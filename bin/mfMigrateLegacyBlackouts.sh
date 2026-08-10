#!/usr/bin/env bash

# One-time migration of timestamp-suffixed Migration Factory blackouts to the
# canonical OEM REST blackout used by mfEmBlackout.sh.
#
# Safety model:
#   * dry-run is the default; --apply is required for POST requests;
#   * every CDB is completely preflighted before the first mutation;
#   * all canonical blackouts are protected before any legacy blackout stops;
#   * legacy resources are re-read immediately before STOP;
#   * this script never invokes emctl and never deletes an OEM resource.

MF_MIGRATE_SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
MF_MIGRATE_HELPER=${MF_MIGRATE_HELPER:-$MF_MIGRATE_SCRIPT_DIR/mfEmBlackout_oemRest.sh}

declare -a MF_MIGRATE_PLAN_FILES=()
declare -a MF_MIGRATE_OWN_TMP_FILES=()
MF_MIGRATE_LOCK_FD=

mf_migrate_error()
{
  printf 'Legacy blackout migration error: %s\n' "$*" >&2
  return 1
}

mf_migrate_log()
{
  printf '%s\n' "$*"
}

mf_migrate_usage()
{
  cat <<'EOF'
Usage: mfMigrateLegacyBlackouts.sh [--dry-run | --apply] [--cutoff-minutes N]

Migrates active legacy blackouts named:
  MF_2_<CDB>_Migration_YYYYMMDD_HHMMSS

Only STARTED blackouts ending strictly after the frozen run time plus N minutes
are selected. N defaults to 1445 (tomorrow plus five minutes). Dry-run is the
default. --apply creates or reuses the canonical blackout and then stops each
verified legacy blackout. This script never deletes blackouts and never falls
back to emctl.

For deterministic offline testing, MF_MIGRATE_NOW_EPOCH may be set to a Unix
epoch. Production runs should leave it unset.
EOF
}

mf_migrate_new_temp_file()
{
  local output_variable="$1"
  local root="${MF_TMP:-${TMPDIR:-/tmp}}"
  local file
  file=$(mktemp "$root/mfMigrateLegacyBlackouts.XXXXXX") || return 1
  chmod 600 "$file" || return 1
  MF_MIGRATE_OWN_TMP_FILES+=("$file")
  printf -v "$output_variable" '%s' "$file"
}

mf_migrate_cleanup()
{
  local file
  if [ -n "${MF_MIGRATE_LOCK_FD:-}" ]
  then
    flock -u "$MF_MIGRATE_LOCK_FD" >/dev/null 2>&1 || :
    exec {MF_MIGRATE_LOCK_FD}>&-
  fi
  for file in "${MF_MIGRATE_OWN_TMP_FILES[@]}"
  do
    [ -n "$file" ] && rm -f -- "$file"
  done
  MF_MIGRATE_OWN_TMP_FILES=()
  if declare -F mf_oem_cleanup >/dev/null 2>&1
  then
    mf_oem_cleanup
  fi
}

mf_migrate_now_epoch()
{
  if [ -n "${MF_MIGRATE_NOW_EPOCH:-}" ]
  then
    [[ "$MF_MIGRATE_NOW_EPOCH" =~ ^[0-9]+$ ]] \
      || mf_migrate_error 'MF_MIGRATE_NOW_EPOCH must be a Unix epoch' || return 1
    printf '%s\n' "$((10#$MF_MIGRATE_NOW_EPOCH))"
  else
    date -u +%s
  fi
}

mf_migrate_epoch_to_iso()
{
  # OEM's timeToEndAfter collection filter is minute-accurate.
  date -u -d "@$1" '+%Y-%m-%dT%H:%MZ' 2>/dev/null \
    || mf_migrate_error "Unable to format Unix epoch $1"
}

mf_migrate_iso_to_epoch()
{
  local instant="$1"
  local date_input timezone_region
  [ -n "$instant" ] && [ "$instant" != null ] \
    || mf_migrate_error 'OEM blackout end time is missing' || return 1
  [[ "$instant" =~ ([zZ]|[+-][0-9]{2}:?[0-9]{2}|[[:space:]][A-Za-z][A-Za-z0-9._+-]*(/[A-Za-z0-9._+-]+)+)$ ]] \
    || mf_migrate_error "OEM blackout end time has no explicit timezone: $instant" || return 1
  date_input=$instant
  if [[ "$instant" =~ [[:space:]][A-Za-z][A-Za-z0-9._+-]*/ ]]
  then
    timezone_region=${instant##* }
    date_input=${instant% *}
    date_input=${date_input/T/ }
    TZ="$timezone_region" date -u -d "$date_input" +%s 2>/dev/null \
      || mf_migrate_error "OEM returned an invalid blackout end time: $instant"
    return
  fi
  date -u -d "$date_input" +%s 2>/dev/null \
    || mf_migrate_error "OEM returned an invalid blackout end time: $instant"
}

mf_migrate_parse_legacy_name()
{
  local name="$1"
  local cdb stamp date_part time_part normalized

  [[ "$name" =~ ^MF_2_(.+)_Migration_([0-9]{8})_([0-9]{6})$ ]] || return 1
  cdb=${BASH_REMATCH[1]}
  date_part=${BASH_REMATCH[2]}
  time_part=${BASH_REMATCH[3]}
  [[ "$cdb" =~ ^[A-Za-z0-9][A-Za-z0-9_\$#]*$ ]] || return 1
  stamp=${date_part}_${time_part}
  normalized=$(date -u -d \
    "${date_part:0:4}-${date_part:4:2}-${date_part:6:2} ${time_part:0:2}:${time_part:2:2}:${time_part:4:2}" \
    '+%Y%m%d_%H%M%S' 2>/dev/null) || return 1
  [ "$normalized" = "$stamp" ] || return 1
  # Keep the canonical prefix exactly as deployed; normalize only the grouping
  # key used to correlate it with repository CDB services.
  printf '%s|%s\n' "${cdb^^}" "${name%_"${stamp}"}"
}

mf_migrate_validate_legacy_targets()
{
  local targets_file="$1"
  jq -e '
    type == "array" and length > 0 and
    all(type == "object" and
        (.id | type == "string" and length > 0) and
        (.name | type == "string" and length > 0) and
        (.typeName == "oracle_database" or .typeName == "oracle_pdb")) and
    ([.[] | select(.typeName == "oracle_database")] | length) > 0 and
    (group_by(.id) | all((map([.name, .typeName]) | unique | length) == 1))
  ' "$targets_file" >/dev/null 2>&1 \
    || mf_migrate_error 'A legacy blackout has missing, conflicting, or invalid target membership'
}

mf_migrate_append_candidate()
{
  local candidates_file="$1"
  local detail_file="$2"
  local targets_file="$3"
  local cdb="$4"
  local canonical="$5"
  local end_epoch="$6"
  local merged_file

  mf_migrate_new_temp_file merged_file || return 1
  jq --arg cdb "$cdb" --arg canonical "$canonical" --argjson endEpoch "$end_epoch" \
    --slurpfile detail "$detail_file" --slurpfile targets "$targets_file" '
      . + [{
        id: $detail[0].id,
        name: $detail[0].name,
        cdb: $cdb,
        canonicalName: $canonical,
        status: $detail[0].status,
        type: $detail[0].type,
        endTime: ($detail[0].timeToEnd // $detail[0].creationTimeToEnd),
        endEpoch: $endEpoch,
        targets: ($targets[0] | sort_by(.id) | unique_by(.id))
      }]
    ' "$candidates_file" > "$merged_file" \
    || mf_migrate_error 'Unable to append a legacy blackout candidate' || return 1
  mv -f -- "$merged_file" "$candidates_file"
}

mf_migrate_collect_candidates()
{
  local cutoff_epoch="$1"
  local output_file="$2"
  local cutoff_iso encoded url collection_file row id name parsed cdb canonical
  local detail_file targets_file end_time end_epoch

  cutoff_iso=$(mf_migrate_epoch_to_iso "$cutoff_epoch") || return 1
  encoded=$(printf '%s' "$cutoff_iso" | mf_oem_urlencode) || return 1
  url="${MF_OEM_API_BASE_URL}/em/api/blackouts?limit=2000&status=STARTED&type=PATCHING&timeToEndAfter=${encoded}"
  mf_migrate_new_temp_file collection_file || return 1
  mf_oem_fetch_blackout_pages "$url" "$collection_file" || return 1
  printf '[]\n' > "$output_file" || return 1

  while IFS= read -r row
  do
    id=$(jq -er '.id' <<<"$row") || return 1
    name=$(jq -er '.name' <<<"$row") || return 1
    parsed=$(mf_migrate_parse_legacy_name "$name") || continue
    cdb=${parsed%%|*}
    canonical=${parsed#*|}

    mf_migrate_new_temp_file detail_file || return 1
    mf_oem_get_blackout "$id" "$detail_file" || return 1
    jq -e --arg id "$id" --arg name "$name" \
      '.id == $id and .name == $name' "$detail_file" >/dev/null \
      || mf_migrate_error "Legacy blackout identity changed during selection: $id" || return 1

    # Status and end are deliberately revalidated from the detail resource.
    jq -e '.status == "STARTED" and .type == "PATCHING"' "$detail_file" >/dev/null \
      || continue
    end_time=$(jq -er '.timeToEnd // .creationTimeToEnd' "$detail_file" 2>/dev/null) \
      || mf_migrate_error "Legacy blackout $id has no end time" || return 1
    end_epoch=$(mf_migrate_iso_to_epoch "$end_time") || return 1
    [ "$end_epoch" -gt "$cutoff_epoch" ] || continue

    mf_migrate_new_temp_file targets_file || return 1
    mf_oem_fetch_blackout_targets "$id" "$targets_file" || return 1
    mf_migrate_validate_legacy_targets "$targets_file" || return 1
    mf_migrate_append_candidate "$output_file" "$detail_file" "$targets_file" \
      "$cdb" "$canonical" "$end_epoch" || return 1
  done < <(jq -c '.[]' "$collection_file")

  jq -e 'group_by(.id) | all((map([.name, .endTime, .cdb]) | unique | length) == 1)' \
    "$output_file" >/dev/null 2>&1 \
    || mf_migrate_error 'OEM returned conflicting legacy blackout identities'
}

mf_migrate_service_cdb()
{
  local service="${1^^}"
  if [[ "$service" == *_* ]]
  then
    printf '%s\n' "${service%%_*}"
  elif [[ "$service" =~ ^(C.*)M[0-9]*$ ]]
  then
    printf '%s\n' "${BASH_REMATCH[1]}"
  else
    printf '%s\n' "$service"
  fi
}

mf_migrate_resolve_authoritative_topology()
{
  local cdb="$1"
  local output_file="$2"
  local rows row migration_id service derived topology_file normalized signature
  local selected_file distinct_file
  local match_count=0

  rows=$(exec_sql "$MF_REPO_CONNECT" "
    select to_char(mig_id) || '|' || trim(target_container_service)
    from migration_attempts
    where current_attempt = 'Y'
      and target_container_service is not null;") \
    || mf_migrate_error "Unable to query current Migration Factory attempts for $cdb" || return 1

  mf_migrate_new_temp_file selected_file || return 1
  mf_migrate_new_temp_file distinct_file || return 1
  printf '[]\n' > "$distinct_file" || return 1

  while IFS= read -r row
  do
    row=${row//$'\r'/}
    row=${row#"${row%%[![:space:]]*}"}
    row=${row%"${row##*[![:space:]]}"}
    [ -n "$row" ] || continue
    migration_id=${row%%|*}
    service=${row#*|}
    [[ "$migration_id" =~ ^[0-9]+$ ]] || continue
    if [ "$service" = "$row" ] || [ -z "$service" ]
    then
      continue
    fi
    derived=$(mf_migrate_service_cdb "$service") || return 1
    [ "${derived^^}" = "${cdb^^}" ] || continue

    match_count=$((match_count + 1))
    mf_migrate_new_temp_file topology_file || return 1
    mf_oem_resolve_topology "$migration_id" "$cdb" "$service" "$topology_file" || return 1
    normalized=$(jq -c '{
      cdbName: (.cdbName | ascii_downcase),
      clusters: ([.clusters[].realName | ascii_downcase] | sort | unique)
    }' "$topology_file") || return 1
    signature=$(printf '%s' "$normalized" | base64 | tr -d '\r\n') || return 1
    jq --arg signature "$signature" --argjson normalized "$normalized" \
      '. + [{signature: $signature, topology: $normalized}] | unique_by(.signature)' \
      "$distinct_file" > "$selected_file" || return 1
    mv -f -- "$selected_file" "$distinct_file" || return 1
    if [ "$match_count" -eq 1 ]
    then
      cp -- "$topology_file" "$output_file" || return 1
    fi
  done <<<"$rows"

  [ "$match_count" -gt 0 ] \
    || mf_migrate_error "No current Migration Factory attempt maps to CDB $cdb" || return 1
  [ "$(jq 'length' "$distinct_file")" -eq 1 ] \
    || mf_migrate_error "Current Migration Factory attempts resolve conflicting topologies for CDB $cdb"
}

mf_migrate_legacy_targets_subset()
{
  local legacy_group_file="$1"
  local discovered_file="$2"
  jq -n -e --slurpfile legacy "$legacy_group_file" --slurpfile discovered "$discovered_file" '
    ([ $legacy[0][].targets[].id ] | sort | unique) as $legacyIds |
    ([ $discovered[0][].id ] | sort | unique) as $discoveredIds |
    ($legacyIds | all(. as $id | ($discoveredIds | index($id)) != null))
  ' >/dev/null 2>&1 \
    || mf_migrate_error 'Legacy blackout membership is not a subset of authoritative OEM discovery'
}

mf_migrate_get_exact_canonical()
{
  local canonical="$1"
  local output_file="$2"
  local ignored_file
  # Read by helper functions sourced at runtime.
  # shellcheck disable=SC2034
  MF_OEM_BLACKOUT_NAME=$canonical
  mf_migrate_new_temp_file ignored_file || return 1
  mf_oem_find_exact_blackouts "$output_file" "$ignored_file"
}

mf_migrate_validate_protected_canonical()
{
  local blackout_id="$1"
  local canonical="$2"
  local required_end_epoch="$3"
  local expected_targets_file="$4"
  local detail_file actual_targets_file end_time end_epoch

  mf_migrate_new_temp_file detail_file || return 1
  mf_oem_get_blackout "$blackout_id" "$detail_file" || return 1
  jq -e --arg id "$blackout_id" --arg name "$canonical" \
    '.id == $id and .name == $name and .status == "STARTED" and .type == "PATCHING"' \
    "$detail_file" >/dev/null \
    || mf_migrate_error "Canonical blackout $canonical is not the expected STARTED resource" || return 1
  end_time=$(jq -er '.timeToEnd // .creationTimeToEnd' "$detail_file" 2>/dev/null) \
    || mf_migrate_error "Canonical blackout $canonical has no end time" || return 1
  end_epoch=$(mf_migrate_iso_to_epoch "$end_time") || return 1
  [ "$end_epoch" -ge "$required_end_epoch" ] \
    || mf_migrate_error "Canonical blackout $canonical ends before the protected legacy interval" || return 1
  mf_migrate_new_temp_file actual_targets_file || return 1
  mf_oem_fetch_blackout_targets "$blackout_id" "$actual_targets_file" || return 1
  mf_oem_target_ids_equal "$expected_targets_file" "$actual_targets_file" \
    || mf_migrate_error "Canonical blackout $canonical does not have exact authoritative target coverage" || return 1
  MF_MIGRATE_VALIDATED_CANONICAL_END_TIME=$end_time
}

mf_migrate_preflight_group()
{
  local candidates_file="$1"
  local cdb="$2"
  local now_epoch="$3"
  local plan_file="$4"
  local group_file topology_file discovered_file canonical_file detail_file targets_file
  local canonical required_end_epoch count canonical_id action=CREATE canonical_end_time

  mf_migrate_new_temp_file group_file || return 1
  jq --arg cdb "$cdb" '[.[] | select(.cdb == $cdb)] | sort_by(.id) | unique_by(.id)' \
    "$candidates_file" > "$group_file" || return 1
  canonical=$(jq -er '.[0].canonicalName' "$group_file") || return 1
  [ "$(jq '[.[].canonicalName] | unique | length' "$group_file")" -eq 1 ] \
    || mf_migrate_error "Legacy names for $cdb do not resolve one exact canonical name" || return 1
  required_end_epoch=$(jq '[.[].endEpoch] | max' "$group_file") || return 1
  canonical_end_time=$(jq -er --argjson end "$required_end_epoch" \
    '[.[] | select(.endEpoch == $end)][0].endTime' "$group_file") || return 1
  [ "$required_end_epoch" -gt "$now_epoch" ] \
    || mf_migrate_error "Legacy interval for $cdb no longer ends in the future" || return 1

  mf_migrate_new_temp_file topology_file || return 1
  mf_migrate_resolve_authoritative_topology "$cdb" "$topology_file" || return 1
  mf_migrate_new_temp_file discovered_file || return 1
  mf_oem_discover_targets "$topology_file" "$discovered_file" || return 1
  mf_migrate_legacy_targets_subset "$group_file" "$discovered_file" || return 1

  mf_migrate_new_temp_file canonical_file || return 1
  mf_migrate_get_exact_canonical "$canonical" "$canonical_file" || return 1
  count=$(jq 'length' "$canonical_file") || return 1
  if [ "$count" -gt 1 ]
  then
    mf_migrate_error "More than one exact canonical blackout exists for $cdb"
    return 1
  elif [ "$count" -eq 1 ]
  then
    action=REUSE
    canonical_id=$(jq -er '.[0].id' "$canonical_file") || return 1
    mf_migrate_validate_protected_canonical "$canonical_id" "$canonical" \
      "$required_end_epoch" "$discovered_file" || return 1
    canonical_end_time=$MF_MIGRATE_VALIDATED_CANONICAL_END_TIME
  fi

  jq -n --arg cdb "$cdb" --arg canonicalName "$canonical" --arg action "$action" \
    --arg canonicalId "${canonical_id:-}" --arg canonicalEndTime "$canonical_end_time" \
    --argjson nowEpoch "$now_epoch" \
    --argjson requiredEndEpoch "$required_end_epoch" \
    --slurpfile legacy "$group_file" --slurpfile topology "$topology_file" \
    --slurpfile targets "$discovered_file" '{
      cdb: $cdb,
      canonicalName: $canonicalName,
      action: $action,
      canonicalId: (if $canonicalId == "" then null else $canonicalId end),
      canonicalEndTime: $canonicalEndTime,
      nowEpoch: $nowEpoch,
      requiredEndEpoch: $requiredEndEpoch,
      legacy: $legacy[0],
      topology: $topology[0],
      targets: $targets[0]
    }' > "$plan_file" || mf_migrate_error "Unable to build migration plan for $cdb"
}

mf_migrate_duration_for_plan()
{
  local plan_file="$1"
  local now_epoch required_end seconds total_minutes hours minutes
  now_epoch=$(jq '.nowEpoch' "$plan_file") || return 1
  required_end=$(jq '.requiredEndEpoch' "$plan_file") || return 1
  seconds=$((required_end - now_epoch))
  [ "$seconds" -gt 0 ] || return 1
  total_minutes=$(((seconds + 59) / 60))
  hours=$((total_minutes / 60))
  minutes=$((total_minutes % 60))
  printf '%s:%02d\n' "$hours" "$minutes"
}

mf_migrate_wait_for_created_started()
{
  local blackout_id="$1"
  local canonical="$2"
  local response_file="$3"
  local attempt=1 status
  local attempts="${MF_OEM_VERIFY_ATTEMPTS:-12}"
  local interval="${MF_OEM_VERIFY_INTERVAL:-5}"

  while [ "$attempt" -le "$attempts" ]
  do
    jq -e --arg id "$blackout_id" --arg name "$canonical" \
      '.id == $id and .name == $name and .type == "PATCHING"' \
      "$response_file" >/dev/null \
      || mf_migrate_error "Created canonical blackout $canonical changed identity or type" || return 1
    status=$(jq -r '.status' "$response_file") || return 1
    case "$status" in
      STARTED) return 0 ;;
      SCHEDULED|START_PROCESSING)
        [ "$attempt" -lt "$attempts" ] || break
        sleep "$interval"
        mf_oem_get_blackout "$blackout_id" "$response_file" || return 1
        ;;
      START_PARTIAL|START_FAILED)
        mf_migrate_error "Created canonical blackout $canonical entered terminal start status $status"
        return 1
        ;;
      *)
        mf_migrate_error "Created canonical blackout $canonical returned unexpected start status $status"
        return 1
        ;;
    esac
    attempt=$((attempt + 1))
  done
  mf_migrate_error "Created canonical blackout $canonical did not reach STARTED"
}

mf_migrate_wait_for_canonical_singleton()
{
  local plan_file="$1"
  local blackout_id="$2"
  local canonical required_end exact_file count found_id targets_file attempt=1
  local attempts="${MF_OEM_VERIFY_ATTEMPTS:-12}"
  local interval="${MF_OEM_VERIFY_INTERVAL:-5}"
  canonical=$(jq -er '.canonicalName' "$plan_file") || return 1
  required_end=$(jq '.requiredEndEpoch' "$plan_file") || return 1
  mf_migrate_new_temp_file targets_file || return 1
  jq '.targets' "$plan_file" > "$targets_file" || return 1
  mf_migrate_new_temp_file exact_file || return 1

  while [ "$attempt" -le "$attempts" ]
  do
    mf_migrate_get_exact_canonical "$canonical" "$exact_file" || return 1
    count=$(jq 'length' "$exact_file") || return 1
    if [ "$count" -gt 1 ]
    then
      mf_migrate_error "Canonical blackout $canonical is no longer a singleton"
      return 1
    elif [ "$count" -eq 1 ]
    then
      found_id=$(jq -er '.[0].id' "$exact_file") || return 1
      [ "$found_id" = "$blackout_id" ] \
        || mf_migrate_error "A different canonical blackout appeared for $canonical" || return 1
      mf_migrate_validate_protected_canonical "$blackout_id" "$canonical" \
        "$required_end" "$targets_file"
      return $?
    fi
    [ "$attempt" -lt "$attempts" ] || break
    sleep "$interval"
    attempt=$((attempt + 1))
  done
  mf_migrate_error "Protected canonical blackout $canonical is not discoverable as one exact resource"
}

mf_migrate_revalidate_canonical_before_stop()
{
  local plan_file="$1"
  local canonical blackout_id required_end exact_file targets_file count found_id
  canonical=$(jq -er '.canonicalName' "$plan_file") || return 1
  blackout_id=$(jq -er '.canonicalId' "$plan_file") \
    || mf_migrate_error "Plan for $canonical has no protected canonical ID" || return 1
  required_end=$(jq '.requiredEndEpoch' "$plan_file") || return 1
  mf_migrate_new_temp_file exact_file || return 1
  mf_migrate_get_exact_canonical "$canonical" "$exact_file" || return 1
  count=$(jq 'length' "$exact_file") || return 1
  [ "$count" -eq 1 ] \
    || mf_migrate_error "Canonical blackout $canonical is not an exact singleton immediately before STOP" || return 1
  found_id=$(jq -er '.[0].id' "$exact_file") || return 1
  [ "$found_id" = "$blackout_id" ] \
    || mf_migrate_error "Canonical blackout ID changed immediately before STOP for $canonical" || return 1
  mf_migrate_new_temp_file targets_file || return 1
  jq '.targets' "$plan_file" > "$targets_file" || return 1
  mf_migrate_validate_protected_canonical "$blackout_id" "$canonical" \
    "$required_end" "$targets_file"
}

mf_migrate_create_canonical()
{
  local plan_file="$1"
  local canonical cdb required_end duration targets_file exact_file payload_file response_file
  local blackout_id
  canonical=$(jq -er '.canonicalName' "$plan_file") || return 1
  cdb=$(jq -er '.cdb' "$plan_file") || return 1
  required_end=$(jq '.requiredEndEpoch' "$plan_file") || return 1
  mf_migrate_new_temp_file targets_file || return 1
  jq '.targets' "$plan_file" > "$targets_file" || return 1

  # Close the preflight/create race: the exact canonical name must still be absent.
  mf_migrate_new_temp_file exact_file || return 1
  mf_migrate_get_exact_canonical "$canonical" "$exact_file" || return 1
  [ "$(jq 'length' "$exact_file")" -eq 0 ] \
    || mf_migrate_error "Canonical blackout $canonical appeared after preflight" || return 1

  duration=$(mf_migrate_duration_for_plan "$plan_file") || return 1
  # Read by helper functions sourced at runtime.
  # shellcheck disable=SC2034
  MF_OEM_BLACKOUT_NAME=$canonical
  mf_migrate_new_temp_file payload_file || return 1
  mf_migrate_new_temp_file response_file || return 1
  mf_oem_build_payload "one-time-legacy-blackout-migration:$cdb" "$targets_file" \
    "$duration" "$payload_file" || return 1
  mf_oem_http POST "${MF_OEM_API_BASE_URL}/em/api/blackouts" "$response_file" "$payload_file" \
    || return 1
  mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 201 "Canonical blackout creation for $cdb" || return 1
  mf_oem_validate_blackout_response "$response_file" || return 1
  jq -e --arg name "$canonical" '.name == $name and .type == "PATCHING"' \
    "$response_file" >/dev/null \
    || mf_migrate_error "Created canonical blackout $canonical has the wrong name or type" || return 1
  blackout_id=$(jq -er '.id' "$response_file") || return 1
  mf_migrate_wait_for_created_started "$blackout_id" "$canonical" "$response_file" || return 1
  mf_migrate_validate_protected_canonical "$blackout_id" "$canonical" \
    "$required_end" "$targets_file" || return 1
  printf '%s\n' "$blackout_id"
}

mf_migrate_protect_plan()
{
  local plan_file="$1"
  local action canonical_id canonical required_end targets_file updated_file
  action=$(jq -er '.action' "$plan_file") || return 1
  canonical=$(jq -er '.canonicalName' "$plan_file") || return 1
  required_end=$(jq '.requiredEndEpoch' "$plan_file") || return 1
  mf_migrate_new_temp_file targets_file || return 1
  jq '.targets' "$plan_file" > "$targets_file" || return 1
  case "$action" in
    CREATE)
      canonical_id=$(mf_migrate_create_canonical "$plan_file") || return 1
      ;;
    REUSE)
      canonical_id=$(jq -er '.canonicalId' "$plan_file") || return 1
      mf_migrate_validate_protected_canonical "$canonical_id" "$canonical" \
        "$required_end" "$targets_file" || return 1
      ;;
    *) mf_migrate_error "Unknown canonical plan action: $action"; return 1 ;;
  esac
  mf_migrate_wait_for_canonical_singleton "$plan_file" "$canonical_id" || return 1
  mf_migrate_new_temp_file updated_file || return 1
  jq --arg id "$canonical_id" --arg end "$MF_MIGRATE_VALIDATED_CANONICAL_END_TIME" \
    '.canonicalId = $id | .canonicalEndTime = $end' "$plan_file" > "$updated_file" || return 1
  mv -f -- "$updated_file" "$plan_file" || return 1
  mf_migrate_log "Protected $canonical as $canonical_id [$action]."
}

mf_migrate_wait_for_stop_transition()
{
  local blackout_id="$1"
  local expected_name="$2"
  local detail_file status attempt=1 attempts="${MF_OEM_VERIFY_ATTEMPTS:-12}"
  local interval="${MF_OEM_VERIFY_INTERVAL:-5}"
  mf_migrate_new_temp_file detail_file || return 1
  while [ "$attempt" -le "$attempts" ]
  do
    mf_oem_get_blackout "$blackout_id" "$detail_file" || return 1
    jq -e --arg id "$blackout_id" --arg name "$expected_name" \
      '.id == $id and .name == $name' "$detail_file" >/dev/null \
      || mf_migrate_error "Legacy blackout identity changed after STOP: $blackout_id" || return 1
    status=$(jq -r '.status' "$detail_file") || return 1
    case "$status" in
      STOP_PENDING|STOPPED|ENDED) return 0 ;;
      STARTED)
        [ "$attempt" -lt "$attempts" ] || break
        sleep "$interval"
        ;;
      *) mf_migrate_error "Legacy blackout $blackout_id entered unexpected STOP status $status"; return 1 ;;
    esac
    attempt=$((attempt + 1))
  done
  mf_migrate_error "Legacy blackout $blackout_id did not enter STOP_PENDING, STOPPED, or ENDED"
}

mf_migrate_stop_legacy()
{
  local row="$1"
  local cutoff_epoch="$2"
  local plan_file="$3"
  local id name expected_end detail_file original_targets_file actual_targets_file stop_file
  local end_time end_epoch
  id=$(jq -er '.id' <<<"$row") || return 1
  name=$(jq -er '.name' <<<"$row") || return 1
  expected_end=$(jq -r '.endEpoch' <<<"$row") || return 1

  mf_migrate_new_temp_file detail_file || return 1
  mf_oem_get_blackout "$id" "$detail_file" || return 1
  jq -e --arg id "$id" --arg name "$name" \
    '.id == $id and .name == $name and .status == "STARTED" and .type == "PATCHING"' \
    "$detail_file" >/dev/null \
    || mf_migrate_error "Legacy blackout $id is no longer the selected STARTED resource" || return 1
  end_time=$(jq -er '.timeToEnd // .creationTimeToEnd' "$detail_file" 2>/dev/null) || return 1
  end_epoch=$(mf_migrate_iso_to_epoch "$end_time") || return 1
  [ "$end_epoch" -eq "$expected_end" ] && [ "$end_epoch" -gt "$cutoff_epoch" ] \
    || mf_migrate_error "Legacy blackout $id end time changed after preflight" || return 1

  mf_migrate_new_temp_file original_targets_file || return 1
  mf_migrate_new_temp_file actual_targets_file || return 1
  jq '.targets' <<<"$row" > "$original_targets_file" || return 1
  mf_oem_fetch_blackout_targets "$id" "$actual_targets_file" || return 1
  mf_oem_target_ids_equal "$original_targets_file" "$actual_targets_file" \
    || mf_migrate_error "Legacy blackout $id target membership changed after preflight" || return 1

  # This is intentionally the final read-only gate before every mutation. If
  # protection disappears or becomes ambiguous, this row issues no STOP.
  mf_migrate_revalidate_canonical_before_stop "$plan_file" || return 1

  mf_migrate_new_temp_file stop_file || return 1
  mf_oem_http POST "${MF_OEM_API_BASE_URL}/em/api/blackouts/${id}/actions/stop" "$stop_file" \
    || return 1
  mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 204 "Legacy blackout STOP for $id" || return 1
  mf_migrate_wait_for_stop_transition "$id" "$name" || return 1
  mf_migrate_log "Stopped legacy blackout $id [$name]."
}

mf_migrate_print_plan()
{
  local plan_file="$1"
  jq -r '
    "CDB: \(.cdb)",
    "  Canonical: action=\(.action) id=\(.canonicalId // "<create>") end=\(.canonicalEndTime)",
    (.legacy | sort_by(.id)[] |
      "  Legacy: id=\(.id) name=\(.name) end=\(.endTime)"),
    (.targets | sort_by(.id)[] |
      "  Target: id=\(.id) name=\(.name) type=\(.typeName)")
  ' "$plan_file"
}

mf_migrate_preflight_all()
{
  local candidates_file="$1"
  local now_epoch="$2"
  local cdb plan_file
  MF_MIGRATE_PLAN_FILES=()
  while IFS= read -r cdb
  do
    mf_migrate_new_temp_file plan_file || return 1
    mf_migrate_preflight_group "$candidates_file" "$cdb" "$now_epoch" "$plan_file" || return 1
    MF_MIGRATE_PLAN_FILES+=("$plan_file")
    mf_migrate_print_plan "$plan_file" || return 1
  done < <(jq -r '[.[].cdb] | unique[]' "$candidates_file")
  mf_migrate_validate_plan_target_isolation
}

mf_migrate_validate_plan_target_isolation()
{
  [ "${#MF_MIGRATE_PLAN_FILES[@]}" -gt 0 ] || return 0
  jq -s -e '
    [ .[] | .cdb as $cdb | .targets[] | {id: .id, cdb: $cdb} ] |
    group_by(.id) |
    all((map(.cdb) | unique | length) == 1)
  ' "${MF_MIGRATE_PLAN_FILES[@]}" >/dev/null 2>&1 \
    || mf_migrate_error 'One authoritative OEM target ID is assigned to more than one CDB plan'
}

mf_migrate_acquire_apply_lock()
{
  local lock_root="${MF_LOGS:-/tmp}"
  local lock_file="$lock_root/mfMigrateLegacyBlackouts.lock"
  command -v flock >/dev/null 2>&1 \
    || mf_migrate_error 'flock is required for --apply' || return 1
  [ -d "$lock_root" ] && [ -w "$lock_root" ] \
    || mf_migrate_error "Apply lock directory is not writable: $lock_root" || return 1
  exec {MF_MIGRATE_LOCK_FD}> "$lock_file" || return 1
  if ! flock -n "$MF_MIGRATE_LOCK_FD"
  then
    exec {MF_MIGRATE_LOCK_FD}>&-
    mf_migrate_error "Another legacy blackout migration holds $lock_file"
    return 1
  fi
}

mf_migrate_run()
{
  local apply=N mode='' cutoff_minutes=1445 arg now_epoch cutoff_epoch candidates_file count
  local plan_file row stop_failures=0

  while [ "$#" -gt 0 ]
  do
    arg=$1
    case "$arg" in
      --apply)
        [ -z "$mode" ] || [ "$mode" = apply ] \
          || mf_migrate_error '--apply and --dry-run cannot be combined' || return 2
        mode=apply
        apply=Y
        shift
        ;;
      --dry-run)
        [ -z "$mode" ] || [ "$mode" = dry-run ] \
          || mf_migrate_error '--apply and --dry-run cannot be combined' || return 2
        mode=dry-run
        apply=N
        shift
        ;;
      --cutoff-minutes)
        [ "$#" -ge 2 ] || mf_migrate_error '--cutoff-minutes requires a value' || return 2
        cutoff_minutes=$2
        shift 2
        ;;
      --help|-h) mf_migrate_usage; return 0 ;;
      *) mf_migrate_error "Unknown argument: $arg"; mf_migrate_usage >&2; return 2 ;;
    esac
  done
  [[ "$cutoff_minutes" =~ ^[0-9]+$ ]] \
    || mf_migrate_error '--cutoff-minutes must be a non-negative integer' || return 2
  cutoff_minutes=$((10#$cutoff_minutes))
  if [ "$apply" = Y ]
  then
    mf_migrate_acquire_apply_lock || return 1
  fi

  now_epoch=$(mf_migrate_now_epoch) || return 1
  cutoff_epoch=$((now_epoch + cutoff_minutes * 60))
  mf_migrate_new_temp_file candidates_file || return 1
  mf_migrate_collect_candidates "$cutoff_epoch" "$candidates_file" || return 1
  count=$(jq 'length' "$candidates_file") || return 1
  mf_migrate_log "Frozen run epoch: $now_epoch; strict cutoff epoch: $cutoff_epoch; selected legacy blackouts: $count."
  [ "$count" -gt 0 ] || { mf_migrate_log 'Nothing to migrate.'; return 0; }

  # Global read-only preflight: no POST is allowed before every CDB passes.
  mf_migrate_preflight_all "$candidates_file" "$now_epoch" || return 1
  if [ "$apply" != Y ]
  then
    mf_migrate_log 'Dry-run complete. No OEM resources were changed. Re-run with --apply to execute this plan.'
    return 0
  fi

  # Protect every CDB first. A failure here prevents all legacy STOP requests.
  for plan_file in "${MF_MIGRATE_PLAN_FILES[@]}"
  do
    mf_migrate_protect_plan "$plan_file" || return 1
  done

  # STOP failures are aggregated so one legacy resource cannot hide the rest.
  for plan_file in "${MF_MIGRATE_PLAN_FILES[@]}"
  do
    while IFS= read -r row
    do
      if ! mf_migrate_stop_legacy "$row" "$cutoff_epoch" "$plan_file"
      then
        stop_failures=$((stop_failures + 1))
      fi
    done < <(jq -c '.legacy[]' "$plan_file")
  done
  [ "$stop_failures" -eq 0 ] \
    || mf_migrate_error "$stop_failures legacy blackout STOP operation(s) failed" || return 1
  mf_migrate_log 'Legacy blackout migration completed successfully.'
}

mf_migrate_initialize()
{
  local utility
  if ! declare -F exec_sql >/dev/null 2>&1
  then
    MF_BIN=${MF_BIN:-$MF_MIGRATE_SCRIPT_DIR}
    shopt -s nullglob
    for utility in "$MF_BIN"/mfUtils_[0-9][0-9]_*.sh
    do
      # shellcheck disable=SC1090
      . "$utility" || return 1
    done
    shopt -u nullglob
    declare -F exec_sql >/dev/null 2>&1 \
      || mf_migrate_error 'Migration Factory utilities did not provide exec_sql' || return 1
    if declare -F mf_setCommonVariables >/dev/null 2>&1
    then
      mf_setCommonVariables || return 1
    fi
  fi
  [ -r "$MF_MIGRATE_HELPER" ] \
    || mf_migrate_error "OEM REST helper is not readable: $MF_MIGRATE_HELPER" || return 1
  # shellcheck disable=SC1090
  . "$MF_MIGRATE_HELPER" || return 1
  [ -n "${MF_REPO_CONNECT:-}" ] \
    || mf_migrate_error 'MF_REPO_CONNECT is required for authoritative topology discovery' || return 1
  mf_oem_validate_config
}

mf_migrate_main()
{
  umask 077
  trap mf_migrate_cleanup EXIT
  trap 'mf_migrate_cleanup; trap - EXIT; exit 130' HUP INT TERM
  mf_migrate_initialize || return 1
  mf_migrate_run "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]
then
  mf_migrate_main "$@"
fi
