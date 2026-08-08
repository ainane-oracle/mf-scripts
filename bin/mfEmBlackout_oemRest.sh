#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# File        : mfEmBlackout_oemRest.sh
# Purpose     : Provide OEM REST API support for mfEmBlackout.sh when -r is used.
#
# Actions     : Discover typed OEM targets, create/verify/stop blackouts, and
#               report blackout status through the centralized OEM REST API.
#
# Security    : Basic authentication is passed to curl through stdin. Passwords
#               are not placed on the process command line, in logs, response
#               files, or temporary files. REST working files are mode 600 and
#               are removed when the operation completes.
#
# Lookup      : Blackout lookup first uses an exact `name` query. If the OEM
#               endpoint rejects it or no active exact match is found, lookup
#               falls back to `nameMatches=%<blackout_name>%`. Multiple active
#               matches remain an error to prevent selecting the wrong blackout.
#
# Compatibility: Sort parameters were removed because the deployed OEM API does
#               not accept the previously used id/name sort fields. Results are
#               validated and selected locally, so ordering is not required.
#
# Debug       : Set MF_OEM_DEBUG=Y for request URL, HTTP status, and response
#               body diagnostics. Authentication headers are never printed.
#
# Modifications:
# - REST support is opt-in from mfEmBlackout.sh via -r.
# - Added exact-name lookup with a nameMatches wildcard fallback.
# - Removed unsupported sort query parameters from REST collection requests.
# - Added protected blackout state persistence for later verification/STOP use.
# -----------------------------------------------------------------------------

declare -a MF_OEM_TMP_FILES=()

mf_oem_error()
{
  printf 'OEM REST error: %s\n' "$*" >&2
  return 1
}

mf_oem_blackout_name()
{
  local migration_id="$1"
  printf '%s\n' "${MF_OEM_BLACKOUT_NAME:-MF_${migration_id}}"
}

mf_oem_require_command()
{
  command -v "$1" >/dev/null 2>&1 || mf_oem_error "Required command is not available: $1"
}

mf_oem_validate_config()
{
  [ -n "${MF_OEM_API_BASE_URL:-}" ] || mf_oem_error "MF_OEM_API_BASE_URL is required" || return 1
  [ -n "${MF_OEM_API_USERNAME:-}" ] || mf_oem_error "MF_OEM_API_USERNAME is required" || return 1
  [ -n "${MF_OEM_API_PASSWORD:-}" ] || mf_oem_error "MF_OEM_API_PASSWORD is required" || return 1
  [[ "$MF_OEM_API_BASE_URL" =~ ^https://([A-Za-z0-9._-]+|\[[0-9A-Fa-f:]+\])(:[0-9]+)?/?$ ]] \
    || mf_oem_error "MF_OEM_API_BASE_URL must be an HTTPS origin without a path" || return 1

  MF_OEM_API_BASE_URL=${MF_OEM_API_BASE_URL%/}
  MF_OEM_BLACKOUT_REASON_ID=${MF_OEM_BLACKOUT_REASON_ID:-29}
  MF_OEM_BLACKOUT_ALLOW_JOBS=${MF_OEM_BLACKOUT_ALLOW_JOBS:-true}
  MF_OEM_VERIFY_ATTEMPTS=${MF_OEM_VERIFY_ATTEMPTS:-${MF_OEM_START_VERIFY_ATTEMPTS:-12}}
  MF_OEM_VERIFY_INTERVAL=${MF_OEM_VERIFY_INTERVAL:-${MF_OEM_START_VERIFY_INTERVAL:-5}}

  [[ "$MF_OEM_BLACKOUT_REASON_ID" =~ ^[0-9]+$ ]] \
    || mf_oem_error "MF_OEM_BLACKOUT_REASON_ID must be a non-negative integer" || return 1
  case "$MF_OEM_BLACKOUT_ALLOW_JOBS" in
    true|false) : ;;
    *) mf_oem_error "MF_OEM_BLACKOUT_ALLOW_JOBS must be true or false"; return 1 ;;
  esac
  [[ "$MF_OEM_VERIFY_ATTEMPTS" =~ ^[1-9][0-9]*$ ]] \
    || mf_oem_error "MF_OEM_VERIFY_ATTEMPTS must be a positive integer" || return 1
  [[ "$MF_OEM_VERIFY_INTERVAL" =~ ^[0-9]+$ ]] \
    || mf_oem_error "MF_OEM_VERIFY_INTERVAL must be a non-negative integer" || return 1

  MF_OEM_BLACKOUT_REASON_ID=$((10#$MF_OEM_BLACKOUT_REASON_ID))
  MF_OEM_VERIFY_ATTEMPTS=$((10#$MF_OEM_VERIFY_ATTEMPTS))
  MF_OEM_VERIFY_INTERVAL=$((10#$MF_OEM_VERIFY_INTERVAL))

  if [ -n "${MF_OEM_CA_CERT:-}" ] && [ ! -r "$MF_OEM_CA_CERT" ]
  then
    mf_oem_error "MF_OEM_CA_CERT is not readable"
    return 1
  fi

  mf_oem_require_command curl || return 1
  mf_oem_require_command jq || return 1
  mf_oem_require_command base64 || return 1
}

mf_oem_validate_time_to_end()
{
  local time_to_end="$1"
  [[ "$time_to_end" =~ ^[0-9]{4}-(0[1-9]|1[0-2])-([0-2][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]Z$ ]] \
    || mf_oem_error "timeToEnd must use YYYY-MM-DDTHH:MIZ format"
}

mf_oem_urlencode()
{
  jq -sRr @uri
}

mf_oem_authorization_config()
{
  local token
  token=$(printf '%s' "${MF_OEM_API_USERNAME}:${MF_OEM_API_PASSWORD}" | base64 | tr -d '\r\n') \
    || return 1
  printf 'header = "Authorization: Basic %s"\n' "$token"
}

mf_oem_http()
{
  local method="$1"
  local url="$2"
  local output_file="$3"
  local payload_file="${4:-}"
  local -a args

  args=(--config - --silent --show-error --request "$method" --url "$url"
        --header 'Accept: application/json' --output "$output_file" --write-out '%{http_code}')
  if [ -n "$payload_file" ]
  then
    args+=(--header 'Content-Type: application/json' --data-binary "@$payload_file")
  fi
  if [ -n "${MF_OEM_CA_CERT:-}" ]
  then
    args+=(--cacert "$MF_OEM_CA_CERT")
  fi

  if [ "${MF_OEM_DEBUG:-N}" = "Y" ]
  then
    printf 'OEM REST request: %s %s\n' "$method" "$url" >&2
    printf 'OEM REST response file: %s\n' "$output_file" >&2
  fi

  MF_OEM_HTTP_STATUS=$(mf_oem_authorization_config | curl "${args[@]}")
  MF_OEM_HTTP_RC=$?

  if [ "${MF_OEM_DEBUG:-N}" = "Y" ]
  then
    printf 'OEM REST HTTP status: %s\n' "$MF_OEM_HTTP_STATUS" >&2
    printf '%s\n' 'OEM REST response body:' >&2
    jq . "$output_file" >&2 2>/dev/null || sed -n '1,120p' "$output_file" >&2
  fi

  [ "$MF_OEM_HTTP_RC" -eq 0 ] || mf_oem_error "HTTPS request failed for $method $url"
}

mf_oem_expect_http()
{
  local actual="$1"
  local expected="$2"
  local operation="$3"
  [ "$actual" = "$expected" ] \
    || mf_oem_error "$operation returned HTTP ${actual:-unknown}; expected $expected"
}

mf_oem_validate_collection_page()
{
  local file="$1"
  jq -e '
    type == "object" and
    (.count | type == "number") and
    (.items | type == "array") and
    (.links | type == "object") and
    (.count == (.items | length)) and
    ((.links.next == null) or
      (.links.next | type == "object" and (.href | type == "string" and length > 0))) and
    (.items | all(
      type == "object" and
      (.id | type == "string" and length > 0) and
      (.name | type == "string" and length > 0) and
      (.typeName | type == "string" and length > 0)
    ))
  ' "$file" >/dev/null 2>&1 || mf_oem_error "Malformed OEM target collection response"
}

mf_oem_validate_blackout_collection_page()
{
  local file="$1"
  jq -e '
    type == "object" and
    (.count | type == "number") and
    (.items | type == "array") and
    (.links | type == "object") and
    (.count == (.items | length)) and
    ((.links.next == null) or
      (.links.next | type == "object" and (.href | type == "string" and length > 0))) and
    (.items | all(
      type == "object" and
      (.id | type == "string" and length > 0) and
      (.name | type == "string" and length > 0) and
      (.status | type == "string" and length > 0) and
      (.type | type == "string" and length > 0) and
      (.owner | type == "string" and length > 0)
    ))
  ' "$file" >/dev/null 2>&1 || mf_oem_error "Malformed OEM blackout collection response"
}

mf_oem_same_origin_next_url()
{
  local href="$1"
  local allowed_path="$2"
  case "$href" in
    "$allowed_path"\?*) printf '%s%s\n' "$MF_OEM_API_BASE_URL" "$href" ;;
    "$MF_OEM_API_BASE_URL$allowed_path"\?*) printf '%s\n' "$href" ;;
    *) mf_oem_error "Unsafe or unexpected pagination link returned by OEM"; return 1 ;;
  esac
}

mf_oem_new_temp_file()
{
  local output_variable="$1"
  local root="${MF_TMP:-${TMPDIR:-/tmp}}"
  local file
  file=$(mktemp "$root/mfEmBlackout.XXXXXX") || return 1
  chmod 600 "$file" || return 1
  MF_OEM_TMP_FILES+=("$file")
  printf -v "$output_variable" '%s' "$file"
}

mf_oem_cleanup()
{
  local file
  for file in "${MF_OEM_TMP_FILES[@]}"
  do
    [ -n "$file" ] && rm -f -- "$file"
  done
  MF_OEM_TMP_FILES=()
}

mf_oem_fetch_target_pages()
{
  local first_url="$1"
  local allowed_path="$2"
  local expected_types="$3"
  local member_json="${4:-null}"
  local output_file="$5"
  local url="$first_url"
  local page_file next_href next_url
  local pages=0
  local seen='|'
  local merged_file

  printf '[]\n' > "$output_file" || return 1
  while [ -n "$url" ]
  do
    pages=$((pages + 1))
    [ "$pages" -le 100 ] || mf_oem_error "OEM pagination exceeded 100 pages" || return 1
    case "$seen" in
      *"|$url|"*) mf_oem_error "OEM pagination cycle detected"; return 1 ;;
    esac
    seen="${seen}${url}|"

    mf_oem_new_temp_file page_file || return 1
    mf_oem_http GET "$url" "$page_file" || return 1
    mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 200 "Target discovery" || return 1
    mf_oem_validate_collection_page "$page_file" || return 1

    if [ -n "$expected_types" ]
    then
      jq -e --arg types "$expected_types" \
        '.items | all(.typeName as $type | ($types | split(",") | index($type)) != null)' \
        "$page_file" >/dev/null \
        || mf_oem_error "OEM returned an unexpected target type" || return 1
    fi

    mf_oem_new_temp_file merged_file || return 1
    jq --argjson member "$member_json" --slurpfile page "$page_file" \
      '. + ($page[0].items | map(. + (if $member == null then {} else {member: $member} end)))' \
      "$output_file" > "$merged_file" \
      || mf_oem_error "Unable to merge OEM target results" || return 1
    mv -f -- "$merged_file" "$output_file" || return 1

    next_href=$(jq -er '.links.next.href // empty' "$page_file" 2>/dev/null) || next_href=
    if [ -n "$next_href" ]
    then
      next_url=$(mf_oem_same_origin_next_url "$next_href" "$allowed_path") || return 1
      url="$next_url"
    else
      url=
    fi
  done
}

mf_oem_fetch_blackout_pages()
{
  local first_url="$1"
  local output_file="$2"
  local allowed_path="/em/api/blackouts"
  local url="$first_url"
  local page_file next_href next_url merged_file
  local pages=0
  local seen='|'

  printf '[]\n' > "$output_file" || return 1
  while [ -n "$url" ]
  do
    pages=$((pages + 1))
    [ "$pages" -le 100 ] || mf_oem_error "OEM blackout pagination exceeded 100 pages" || return 1
    case "$seen" in
      *"|$url|"*) mf_oem_error "OEM blackout pagination cycle detected"; return 1 ;;
    esac
    seen="${seen}${url}|"

    mf_oem_new_temp_file page_file || return 1
    mf_oem_http GET "$url" "$page_file" || return 1
    mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 200 "Blackout lookup" || return 1
    mf_oem_validate_blackout_collection_page "$page_file" || return 1

    mf_oem_new_temp_file merged_file || return 1
    jq --slurpfile page "$page_file" '. + $page[0].items' "$output_file" > "$merged_file" \
      || mf_oem_error "Unable to merge OEM blackout results" || return 1
    mv -f -- "$merged_file" "$output_file" || return 1

    next_href=$(jq -er '.links.next.href // empty' "$page_file" 2>/dev/null) || next_href=
    if [ -n "$next_href" ]
    then
      next_url=$(mf_oem_same_origin_next_url "$next_href" "$allowed_path") || return 1
      url="$next_url"
    else
      url=
    fi
  done
}

mf_oem_select_active_blackout()
{
  local blackouts_file="$1"
  local blackout_name="$2"
  local output_file="$3"
  local match_mode="${4:-exact}"
  local selected_file count

  mf_oem_new_temp_file selected_file || return 1
  if [ "$match_mode" = "contains" ]
  then
    jq --arg name "$blackout_name" '
      [ .[] |
        select(.name | contains($name)) |
        select(.status as $status | [
          "SCHEDULED", "START_PROCESSING", "START_PARTIAL", "STARTED",
          "STOP_PENDING", "STOP_FAILED", "STOP_PARTIAL",
          "EDIT_PENDING", "EDIT_FAILED", "EDIT_PARTIAL", "END_PARTIAL"
        ] | index($status) != null)
      ] | unique_by(.id)
    ' "$blackouts_file" > "$selected_file" \
      || mf_oem_error "Unable to select the active OEM blackout" || return 1
  else
    jq --arg name "$blackout_name" '
      [ .[] |
        select(.name == $name) |
        select(.status as $status | [
          "SCHEDULED", "START_PROCESSING", "START_PARTIAL", "STARTED",
          "STOP_PENDING", "STOP_FAILED", "STOP_PARTIAL",
          "EDIT_PENDING", "EDIT_FAILED", "EDIT_PARTIAL", "END_PARTIAL"
        ] | index($status) != null)
      ] | unique_by(.id)
    ' "$blackouts_file" > "$selected_file" \
      || mf_oem_error "Unable to select the active OEM blackout" || return 1
  fi

  count=$(jq 'length' "$selected_file") || return 1
  case "$count" in
    0) return 3 ;;
    1) jq '.[0]' "$selected_file" > "$output_file" || return 1 ;;
    *) mf_oem_error "More than one active OEM blackout has the exact name $blackout_name"; return 1 ;;
  esac
}

mf_oem_find_active_blackout()
{
  local migration_id="$1"
  local output_file="$2"
  local blackout_name
  local encoded url blackouts_file fallback_file rc

  blackout_name=$(mf_oem_blackout_name "$migration_id") || return 1

  encoded=$(printf '%s' "$blackout_name" | mf_oem_urlencode) || return 1
  url="${MF_OEM_API_BASE_URL}/em/api/blackouts?limit=2000&name=${encoded}"
  mf_oem_new_temp_file blackouts_file || return 1
  if mf_oem_fetch_blackout_pages "$url" "$blackouts_file"
  then
    mf_oem_select_active_blackout "$blackouts_file" "$blackout_name" "$output_file"
    rc=$?
    [ "$rc" -eq 0 ] && return 0
  fi

  encoded=$(printf '%%%s%%' "$blackout_name" | mf_oem_urlencode) || return 1
  url="${MF_OEM_API_BASE_URL}/em/api/blackouts?limit=2000&nameMatches=${encoded}"
  mf_oem_new_temp_file fallback_file || return 1
  mf_oem_fetch_blackout_pages "$url" "$fallback_file" || return 1
  mf_oem_select_active_blackout "$fallback_file" "$blackout_name" "$output_file" contains
}

mf_oem_append_json_array()
{
  local destination="$1"
  local source="$2"
  local merged
  mf_oem_new_temp_file merged || return 1
  jq --slurpfile source "$source" '. + $source[0]' "$destination" > "$merged" \
    || mf_oem_error "Unable to merge resolved targets" || return 1
  mv -f -- "$merged" "$destination" || return 1
}

mf_oem_validate_resolved_targets()
{
  local topology_file="$1"
  local targets_file="$2"
  local normalized_file="$3"

  jq -n -e --slurpfile topology "$topology_file" --slurpfile targets "$targets_file" '
    ($topology[0]) as $required |
    ($targets[0]) as $resolved |
    ($resolved | type == "array" and length > 0 and all(
      type == "object" and
      (.id | type == "string" and length > 0) and
      (.name | type == "string" and length > 0) and
      (.typeName == "oracle_database" or .typeName == "oracle_pdb") and
      (.member | type == "object") and
      (.member.clusterId | type == "string" and length > 0) and
      (.member.realName | type == "string" and length > 0) and
      (.member.dbUniqueName | type == "string" and length > 0) and
      (.member.targetPrefix | type == "string" and length > 0) and
      (.member.discoveryMode == "target_prefix" or .member.discoveryMode == "cdb_name_fallback")
    )) and
    ($resolved | group_by(.id) | all((map([
      .name, .typeName, .member.clusterId, .member.realName,
      .member.dbUniqueName, .member.targetPrefix
    ]) | unique | length) == 1)) and
    ($resolved | group_by([.name, .typeName]) | all((map(.id) | unique | length) == 1)) and
    ($resolved | all(. as $target |
      (($target.name | ascii_downcase) | startswith($target.member.targetPrefix | ascii_downcase)) and
      ($required.dbUniqueNames | index($target.member.dbUniqueName)) != null and
      ([ $required.clusters[] |
         select(.clusterId == $target.member.clusterId and
                (.realName | ascii_downcase) == ($target.member.realName | ascii_downcase))
       ] | length) == 1 and
      ($target.member.targetPrefix | ascii_downcase) ==
        (($target.member.realName | ascii_downcase) + "_" + ($target.member.dbUniqueName | ascii_downcase))
    )) and
    ($required.clusters | all(. as $cluster |
      ([ $resolved[] | select(.member.clusterId == $cluster.clusterId) | .member.dbUniqueName ] | unique | length) == 1 and
      ([ $resolved[] |
         select(.member.clusterId == $cluster.clusterId and .typeName == "oracle_database") |
         .id
       ] | unique | length) >= 1
    )) and
    ($required.dbUniqueNames | all(. as $dbUniqueName |
      ([ $resolved[] | select(.member.dbUniqueName == $dbUniqueName) | .member.clusterId ] | unique | length) == 1
    )) and
    ([ $resolved[].member.clusterId ] | unique | length) == ($required.clusters | length) and
    ([ $resolved[].member.dbUniqueName ] | unique | length) == ($required.dbUniqueNames | length)
  ' >/dev/null 2>&1 || mf_oem_error "Missing, duplicate, ambiguous, or unexpected OEM targets" || return 1

  jq 'sort_by(.id) | unique_by(.id)' "$targets_file" > "$normalized_file" \
    || mf_oem_error "Unable to normalize OEM targets" || return 1
}

mf_oem_validate_topology()
{
  local topology_file="$1"
  jq -e '
    def db_name_from_unique_name:
      if contains("_") then split("_")[0]
      elif test("^C.*M[0-9]*$") then sub("M[0-9]*$"; "")
      else . end;
    . as $topology |
    ($topology.targetContainerService | ascii_downcase) as $selectedService |
    ($topology.cdbName | ascii_downcase) as $cdbName |
    ($topology | type == "object") and
    ($topology.cdbName | type == "string" and length > 0) and
    ($topology.targetContainerService | type == "string" and length > 0) and
    ($topology.startClusterId | type == "string" and length > 0) and
    ($topology.clusters | type == "array" and length > 0 and all(
      type == "object" and
      (.clusterId | type == "string" and length > 0) and
      ((.peerClusterId == null) or (.peerClusterId | type == "string" and length > 0)) and
      (.realName | type == "string" and length > 0)
    )) and
    ($topology.dbUniqueNames | type == "array" and length > 0 and all(type == "string" and length > 0)) and
    ($topology.clusters | map(.clusterId) | unique | length) == ($topology.clusters | length) and
    ($topology.clusters | map(.realName | ascii_downcase) | unique | length) == ($topology.clusters | length) and
    ($topology.clusters | map(.clusterId) | index($topology.startClusterId)) != null and
    ($topology.clusters | all(.peerClusterId == null or
      (.peerClusterId as $peer | [$topology.clusters[].clusterId] | index($peer)) != null)) and
    ($topology.dbUniqueNames | unique | length) == ($topology.dbUniqueNames | length) and
    ($topology.clusters | length) == ($topology.dbUniqueNames | length) and
    ([$topology.dbUniqueNames[] | ascii_downcase] | index($selectedService)) != null and
    ($topology.dbUniqueNames | all((db_name_from_unique_name | ascii_downcase) == $cdbName))
  ' "$topology_file" >/dev/null 2>&1 \
    || mf_oem_error "MF cluster topology and Data Guard members are missing, stale, or inconsistent"
}

mf_oem_resolve_topology()
{
  local repository_migration_id="$1"
  local cdb_name="$2"
  local target_container_service="$3"
  local output_file="$4"
  local cluster_rows db_unique_names

  [[ "$repository_migration_id" =~ ^[0-9]+$ ]] \
    || mf_oem_error "The internal MF migration ID must be numeric" || return 1

  cluster_rows=$(exec_sql "$MF_REPO_CONNECT" "
    select distinct
           to_char((select tclu_id from migration_attempts where mig_id = $repository_migration_id)) || '|' ||
           to_char(tc.tclu_id) || '|' ||
           nvl(to_char(tc.peer_tclu_id), '') || '|' ||
           lower(trim(tc.real_name))
    from target_clusters tc
    where tc.prj_name = (select prj_name from migration_attempts where mig_id = $repository_migration_id)
    start with tc.tclu_id = (select tclu_id from migration_attempts where mig_id = $repository_migration_id)
    connect by nocycle
           prior tc.prj_name = tc.prj_name
       and (prior tc.tclu_id = tc.peer_tclu_id or prior tc.peer_tclu_id = tc.tclu_id);") \
    || mf_oem_error "Unable to resolve the connected MF target clusters" || return 1

  db_unique_names=$(exec_sql "$MF_TGT_CDB_CONNECT" "
    select db_unique_name from v\$database
    union
    select db_unique_name from v\$dataguard_config;") \
    || mf_oem_error "Unable to resolve Data Guard DB_UNIQUE_NAME members" || return 1

  jq -n \
    --arg clusterRows "$cluster_rows" \
    --arg dbUniqueNames "$db_unique_names" \
    --arg cdbName "$cdb_name" \
    --arg targetContainerService "$target_container_service" '
      def lines($value):
        $value | gsub("\\r"; "") | split("\n") |
        map(gsub("^[[:space:]]+|[[:space:]]+$"; "")) |
        map(select(length > 0));
      (lines($clusterRows) | map(split("|"))) as $rows |
      {
        cdbName: $cdbName,
        targetContainerService: $targetContainerService,
        startClusterId: ($rows[0][0] // ""),
        clusters: ($rows | map(select(length == 4) | {
          clusterId: .[1],
          peerClusterId: (if .[2] == "" then null else .[2] end),
          realName: .[3]
        }) | unique_by(.clusterId) | sort_by(.clusterId)),
        dbUniqueNames: (lines($dbUniqueNames) | unique | sort)
      }
    ' > "$output_file" || mf_oem_error "Unable to build the MF/OEM topology snapshot" || return 1

  mf_oem_validate_topology "$output_file"
}

mf_oem_query_targets()
{
  local pattern="$1"
  local member_json="${2:-null}"
  local output_file="$3"
  local encoded url

  encoded=$(printf '%s' "$pattern" | mf_oem_urlencode) || return 1
  url="${MF_OEM_API_BASE_URL}/em/api/targets?limit=100&typeName=oracle_database&typeName=oracle_pdb&nameMatches=${encoded}"
  mf_oem_fetch_target_pages "$url" "/em/api/targets" \
    "oracle_database,oracle_pdb" "$member_json" "$output_file"
}

mf_oem_discover_targets()
{
  local topology_file="$1"
  local output_file="$2"
  local member prefix pattern query_file filtered_file normalized_file
  local unmatched_members_file fallback_file mapped_fallback_file ambiguous_count

  printf '[]\n' > "$output_file" || return 1
  while IFS= read -r member
  do
    prefix=$(printf '%s' "$member" | jq -r '.targetPrefix') || return 1
    pattern="${prefix}%"
    mf_oem_new_temp_file query_file || return 1
    mf_oem_query_targets "$pattern" "$member" "$query_file" || return 1
    mf_oem_new_temp_file filtered_file || return 1
    jq --arg prefix "$prefix" '
      ($prefix | ascii_downcase) as $expected |
      [ .[] | select((.name | ascii_downcase) | startswith($expected)) ]
    ' "$query_file" > "$filtered_file" || return 1
    [ "$(jq 'length' "$filtered_file")" -eq 0 ] \
      || mf_oem_append_json_array "$output_file" "$filtered_file" || return 1
  done < <(jq -c '
    .clusters[] as $cluster |
    .dbUniqueNames[] as $dbUniqueName |
    {
      clusterId: $cluster.clusterId,
      realName: $cluster.realName,
      dbUniqueName: $dbUniqueName,
      targetPrefix: (($cluster.realName | ascii_downcase) + "_" + $dbUniqueName),
      discoveryMode: "target_prefix"
    }
  ' "$topology_file")

  mf_oem_new_temp_file unmatched_members_file || return 1
  jq -n --slurpfile topology "$topology_file" --slurpfile targets "$output_file" '
    ($targets[0] | map(.member.clusterId) | unique) as $matchedClusters |
    [ $topology[0].clusters[] |
      select(.clusterId as $id | ($matchedClusters | index($id)) == null) |
      . as $cluster |
      $topology[0].dbUniqueNames[] as $dbUniqueName |
      {
        clusterId: $cluster.clusterId,
        realName: $cluster.realName,
        dbUniqueName: $dbUniqueName,
        targetPrefix: (($cluster.realName | ascii_downcase) + "_" + $dbUniqueName)
      }
    ]
  ' > "$unmatched_members_file" || return 1

  if [ "$(jq 'length' "$unmatched_members_file")" -gt 0 ]
  then
    pattern="%$(jq -r '.cdbName' "$topology_file")%"
    mf_oem_new_temp_file fallback_file || return 1
    mf_oem_query_targets "$pattern" null "$fallback_file" || return 1

    ambiguous_count=$(jq -n --slurpfile candidates "$fallback_file" --slurpfile members "$unmatched_members_file" '
      [ $candidates[0][] as $target |
        [ $members[0][] |
          .targetPrefix as $prefix |
          select(($target.name | ascii_downcase) | startswith($prefix | ascii_downcase))
        ] |
        select(length > 1)
      ] | length
    ') || return 1
    [ "$ambiguous_count" -eq 0 ] \
      || mf_oem_error "The CDB-name fallback maps an OEM target to more than one MF member" || return 1

    mf_oem_new_temp_file mapped_fallback_file || return 1
    jq -n --slurpfile candidates "$fallback_file" --slurpfile members "$unmatched_members_file" '
      [ $candidates[0][] as $target |
        ([ $members[0][] |
           .targetPrefix as $prefix |
           select(($target.name | ascii_downcase) | startswith($prefix | ascii_downcase))
         ]) as $matches |
        select(($matches | length) == 1) |
        $target + {member: ($matches[0] + {discoveryMode: "cdb_name_fallback"})}
      ]
    ' > "$mapped_fallback_file" || return 1
    mf_oem_append_json_array "$output_file" "$mapped_fallback_file" || return 1
  fi

  mf_oem_new_temp_file normalized_file || return 1
  mf_oem_validate_resolved_targets "$topology_file" "$output_file" "$normalized_file" || return 1
  mv -f -- "$normalized_file" "$output_file" || return 1
}

mf_oem_build_payload()
{
  local migration_id="$1"
  local targets_file="$2"
  local time_to_end="$3"
  local payload_file="$4"
  [ -z "$time_to_end" ] || mf_oem_validate_time_to_end "$time_to_end" || return 1
  jq -n \
    --arg name "$(mf_oem_blackout_name "$migration_id")" \
    --arg description "Migration Factory planned maintenance for ${migration_id}; OEM monitoring blackout during the migration window." \
    --argjson reasonId "$MF_OEM_BLACKOUT_REASON_ID" \
    --argjson allowJobs "$MF_OEM_BLACKOUT_ALLOW_JOBS" \
    --arg timeToEnd "$time_to_end" \
    --slurpfile targets "$targets_file" '
      ({
        name: $name,
        type: "PATCHING",
        reasonId: $reasonId,
        description: $description,
        isAllowJobs: $allowJobs,
        isFullBlackoutOnHost: false,
        targets: ($targets[0] | map({id: .id}))
      } + if $timeToEnd == ""
           then {durationHours: 12, durationMinutes: 0}
           else {timeToEnd: $timeToEnd}
           end)
    ' > "$payload_file" || mf_oem_error "Unable to build the OEM blackout JSON payload"
}

mf_oem_validate_blackout_response()
{
  local file="$1"
  jq -e '
    type == "object" and
    (.id | type == "string" and length > 0) and
    (.name | type == "string" and length > 0) and
    (.status | type == "string" and length > 0)
  ' "$file" >/dev/null 2>&1 || mf_oem_error "Malformed OEM blackout response"
}

mf_oem_status_result()
{
  case "$1" in
    STARTED) return 0 ;;
    START_PROCESSING) return 2 ;;
    START_PARTIAL|START_FAILED) mf_oem_error "OEM blackout returned terminal status $1" ;;
    *) mf_oem_error "OEM blackout returned unexpected status $1" ;;
  esac
}

mf_oem_stop_status_result()
{
  case "$1" in
    STOPPED|ENDED) return 0 ;;
    SCHEDULED|START_PROCESSING|STARTED|STOP_PENDING) return 2 ;;
    START_PARTIAL|STOP_FAILED|STOP_PARTIAL|END_PARTIAL)
      mf_oem_error "OEM blackout returned terminal stop status $1"
      ;;
    *) mf_oem_error "OEM blackout returned unexpected stop status $1" ;;
  esac
}

mf_oem_get_blackout()
{
  local blackout_id="$1"
  local response_file="$2"
  mf_oem_http GET "${MF_OEM_API_BASE_URL}/em/api/blackouts/${blackout_id}" "$response_file" || return 1
  mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 200 "Blackout status" || return 1
  mf_oem_validate_blackout_response "$response_file"
}

mf_oem_print_blackout()
{
  local response_file="$1"
  jq -r '
    "OEM blackout ID       : \(.id)",
    "OEM blackout name     : \(.name)",
    "OEM blackout status   : \(.status)",
    (if (.timeToEnd // .creationTimeToEnd // "") != ""
     then "OEM blackout end time : \(.timeToEnd // .creationTimeToEnd)"
     else empty end)
  ' "$response_file" || mf_oem_error "Unable to format OEM blackout status"
}

mf_oem_wait_for_stopped()
{
  local blackout_id="$1"
  local response_file="$2"
  local attempt=1
  local status rc

  while [ "$attempt" -le "$MF_OEM_VERIFY_ATTEMPTS" ]
  do
    mf_oem_get_blackout "$blackout_id" "$response_file" || return 1
    status=$(jq -r '.status' "$response_file") || return 1
    mf_oem_stop_status_result "$status"
    rc=$?
    [ "$rc" -eq 0 ] && return 0
    [ "$rc" -eq 2 ] || return 1
    [ "$attempt" -lt "$MF_OEM_VERIFY_ATTEMPTS" ] || break
    sleep "$MF_OEM_VERIFY_INTERVAL"
    attempt=$((attempt + 1))
  done
  mf_oem_error "OEM blackout did not reach STOPPED within the verification window"
}

mf_oem_prepare_state_file()
{
  local migration_id="$1"
  local safe_id timestamp
  MF_OEM_BLACKOUT_STATE_DIR=${MF_OEM_BLACKOUT_STATE_DIR:-${MF_DATA}/em_blackouts}
  umask 077
  mkdir -p "$MF_OEM_BLACKOUT_STATE_DIR" || return 1
  chmod 700 "$MF_OEM_BLACKOUT_STATE_DIR" || return 1
  safe_id=$(printf '%s' "$migration_id" | tr -c 'A-Za-z0-9_.-' '_')
  timestamp=$(date +%Y%m%d_%H%M%S)
  MF_OEM_BLACKOUT_STATE_FILE=${MF_OEM_BLACKOUT_STATE_FILE:-${MF_OEM_BLACKOUT_STATE_DIR}/${safe_id}_${timestamp}.json}
  [ ! -e "$MF_OEM_BLACKOUT_STATE_FILE" ] \
    || mf_oem_error "OEM blackout state file already exists; refusing to overwrite it" || return 1
}

mf_oem_write_state()
{
  local migration_id="$1"
  local topology_file="$2"
  local targets_file="$3"
  local response_file="$4"
  local verified="$5"
  local tmp_file
  tmp_file="${MF_OEM_BLACKOUT_STATE_FILE}.tmp.$$"

  jq -n \
    --arg migrationId "$migration_id" \
    --arg baseUrl "$MF_OEM_API_BASE_URL" \
    --arg capturedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson verified "$verified" \
    --slurpfile topology "$topology_file" \
    --slurpfile targets "$targets_file" \
    --slurpfile response "$response_file" '
      {
        migrationId: $migrationId,
        oemApiBaseUrl: $baseUrl,
        blackoutId: $response[0].id,
        blackoutName: $response[0].name,
        status: $response[0].status,
        capturedAt: $capturedAt,
        targetCoverageVerified: $verified,
        requiredTopology: $topology[0],
        targets: $targets[0]
      }
    ' > "$tmp_file" || return 1
  chmod 600 "$tmp_file" || return 1
  mv -f -- "$tmp_file" "$MF_OEM_BLACKOUT_STATE_FILE" || return 1
}

mf_oem_wait_for_started()
{
  local blackout_id="$1"
  local response_file="$2"
  local attempt=1
  local status rc

  while [ "$attempt" -le "$MF_OEM_VERIFY_ATTEMPTS" ]
  do
    status=$(jq -r '.status' "$response_file") || return 1
    mf_oem_status_result "$status"
    rc=$?
    [ "$rc" -eq 0 ] && return 0
    [ "$rc" -eq 2 ] || return 1
    [ "$attempt" -lt "$MF_OEM_VERIFY_ATTEMPTS" ] || break
    sleep "$MF_OEM_VERIFY_INTERVAL"
    mf_oem_http GET "${MF_OEM_API_BASE_URL}/em/api/blackouts/${blackout_id}" "$response_file" || return 1
    mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 200 "Blackout status verification" || return 1
    mf_oem_validate_blackout_response "$response_file" || return 1
    attempt=$((attempt + 1))
  done
  mf_oem_error "OEM blackout did not reach STARTED within the verification window"
}

mf_oem_verify_blackout_targets()
{
  local blackout_id="$1"
  local expected_file="$2"
  local actual_file expected_ids actual_ids
  mf_oem_new_temp_file actual_file || return 1
  mf_oem_fetch_target_pages \
    "${MF_OEM_API_BASE_URL}/em/api/blackouts/${blackout_id}/targets?limit=2000" \
    "/em/api/blackouts/${blackout_id}/targets" "" "" "$actual_file" || return 1

  expected_ids=$(jq -c '[.[] | [.id, .name, .typeName]] | sort | unique' "$expected_file") || return 1
  actual_ids=$(jq -c '[.[] | [.id, .name, .typeName]] | sort | unique' "$actual_file") || return 1
  [ "$expected_ids" = "$actual_ids" ] \
    || mf_oem_error "OEM blackout target coverage does not exactly match the resolved target snapshot"
}

mf_oem_start_blackout()
{
  local migration_id="$1"
  local repository_migration_id="$2"
  local cdb_name="$3"
  local target_container_service="$4"
  local time_to_end="$5"
  local topology_file targets_file payload_file response_file blackout_id
  local active_file active_rc active_status

  umask 077
  MF_OEM_TMP_FILES=()
  MF_OEM_START_MUTATION_ATTEMPTED=N
  mf_oem_validate_config || return 1
  mf_oem_new_temp_file active_file || return 1
  mf_oem_find_active_blackout "$migration_id" "$active_file"
  active_rc=$?
  case "$active_rc" in
    0)
      active_status=$(jq -r '.status' "$active_file") || return 1
      mf_oem_error "An OEM blackout named $(mf_oem_blackout_name "$migration_id") is already active with status $active_status"
      return 1
      ;;
    3) : ;;
    *) return 1 ;;
  esac
  mf_oem_prepare_state_file "$migration_id" || return 1
  mf_oem_new_temp_file topology_file || return 1
  mf_oem_new_temp_file targets_file || return 1
  mf_oem_new_temp_file payload_file || return 1
  mf_oem_new_temp_file response_file || return 1

  mf_oem_resolve_topology "$repository_migration_id" "$cdb_name" \
    "$target_container_service" "$topology_file" || return 1
  mf_oem_discover_targets "$topology_file" "$targets_file" || return 1
  mf_oem_build_payload "$migration_id" "$targets_file" "$time_to_end" "$payload_file" || return 1
  # A network failure after this point is ambiguous: OEM may have created the
  # blackout even when curl did not receive a response. The caller must not
  # fall back to emctl in that case.
  MF_OEM_START_MUTATION_ATTEMPTED=Y
  mf_oem_http POST "${MF_OEM_API_BASE_URL}/em/api/blackouts" "$response_file" "$payload_file" || return 1
  mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 201 "Blackout creation" || return 1
  mf_oem_validate_blackout_response "$response_file" || return 1
  blackout_id=$(jq -r '.id' "$response_file") || return 1
  [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
    || mf_oem_error "OEM returned an unsafe blackout ID" || return 1

  mf_oem_write_state "$migration_id" "$topology_file" "$targets_file" "$response_file" false || return 1
  mf_oem_wait_for_started "$blackout_id" "$response_file" || {
    mf_oem_write_state "$migration_id" "$topology_file" "$targets_file" "$response_file" false >/dev/null 2>&1 || :
    return 1
  }
  mf_oem_verify_blackout_targets "$blackout_id" "$targets_file" || {
    mf_oem_write_state "$migration_id" "$topology_file" "$targets_file" "$response_file" false >/dev/null 2>&1 || :
    return 1
  }
  mf_oem_write_state "$migration_id" "$topology_file" "$targets_file" "$response_file" true || return 1

  printf 'OEM blackout ID       : %s\n' "$blackout_id"
  printf 'OEM blackout status   : STARTED\n'
  if [ -n "$time_to_end" ]
  then
    printf 'OEM blackout end time : %s\n' "$time_to_end"
  else
    printf 'OEM blackout duration : 12 hours (no planned go-live)\n'
  fi
  printf 'Resolved target count : %s\n' "$(jq 'length' "$targets_file")"
  printf 'Protected state file  : %s\n' "$MF_OEM_BLACKOUT_STATE_FILE"
}

mf_oem_status_blackout()
{
  local migration_id="$1"
  local active_file response_file blackout_id rc

  umask 077
  MF_OEM_TMP_FILES=()
  MF_OEM_LOOKUP_RESULT=
  mf_oem_validate_config || return 1
  mf_oem_new_temp_file active_file || return 1
  mf_oem_find_active_blackout "$migration_id" "$active_file"
  rc=$?
  case "$rc" in
    0) : ;;
    3) MF_OEM_LOOKUP_RESULT=NOT_ACTIVE; printf 'OEM blackout %s: NOT ACTIVE\n' "$(mf_oem_blackout_name "$migration_id")"; return 0 ;;
    *) return 1 ;;
  esac

  blackout_id=$(jq -r '.id' "$active_file") || return 1
  [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
    || mf_oem_error "OEM returned an unsafe blackout ID" || return 1
  mf_oem_new_temp_file response_file || return 1
  mf_oem_get_blackout "$blackout_id" "$response_file" || return 1
  mf_oem_print_blackout "$response_file"
}

mf_oem_is_blackout_on()
{
  local migration_id="$1"
  local active_file response_file blackout_id status rc

  umask 077
  MF_OEM_TMP_FILES=()
  mf_oem_validate_config || return 1
  mf_oem_new_temp_file active_file || return 1
  mf_oem_find_active_blackout "$migration_id" "$active_file"
  rc=$?
  case "$rc" in
    0) : ;;
    3) printf 'OEM blackout %s: NOT ACTIVE\n' "$(mf_oem_blackout_name "$migration_id")"; return 1 ;;
    *) return 1 ;;
  esac

  blackout_id=$(jq -r '.id' "$active_file") || return 1
  [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
    || mf_oem_error "OEM returned an unsafe blackout ID" || return 1
  mf_oem_new_temp_file response_file || return 1
  mf_oem_get_blackout "$blackout_id" "$response_file" || return 1
  status=$(jq -r '.status' "$response_file") || return 1
  if [ "$status" = "STARTED" ]
  then
    printf 'OEM blackout %s is ON\n' "$(mf_oem_blackout_name "$migration_id")"
    return 0
  fi
  printf 'OEM blackout %s is not fully ON (status: %s)\n' "$(mf_oem_blackout_name "$migration_id")" "$status"
  return 1
}

mf_oem_stop_blackout()
{
  local migration_id="$1"
  local active_file response_file stop_file blackout_id status rc

  umask 077
  MF_OEM_TMP_FILES=()
  MF_OEM_STOP_MUTATION_ATTEMPTED=N
  mf_oem_validate_config || return 1
  mf_oem_new_temp_file active_file || return 1
  mf_oem_find_active_blackout "$migration_id" "$active_file"
  rc=$?
  case "$rc" in
    0) : ;;
    3) mf_oem_error "No active OEM blackout named $(mf_oem_blackout_name "$migration_id") was found"; return 1 ;;
    *) return 1 ;;
  esac

  blackout_id=$(jq -r '.id' "$active_file") || return 1
  [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
    || mf_oem_error "OEM returned an unsafe blackout ID" || return 1
  mf_oem_new_temp_file response_file || return 1
  mf_oem_get_blackout "$blackout_id" "$response_file" || return 1
  status=$(jq -r '.status' "$response_file") || return 1

  if [ "$status" != "STOP_PENDING" ]
  then
    mf_oem_new_temp_file stop_file || return 1
    # Once a stop request is attempted, its outcome may be unknown even if the
    # transport fails. Do not let callers issue an unrelated local fallback.
    MF_OEM_STOP_MUTATION_ATTEMPTED=Y
    mf_oem_http POST "${MF_OEM_API_BASE_URL}/em/api/blackouts/${blackout_id}/actions/stop" "$stop_file" || return 1
    mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 204 "Blackout stop" || return 1
  else
    MF_OEM_STOP_MUTATION_ATTEMPTED=Y
  fi

  mf_oem_wait_for_stopped "$blackout_id" "$response_file" || return 1
  mf_oem_print_blackout "$response_file"
}
