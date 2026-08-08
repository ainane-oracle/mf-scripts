#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# File        : mfEmBlackout_oemRest.sh
# Purpose     : OEM REST API support for mfEmBlackout.sh when -r is used.
#
# Invariant   : At most one exact canonical blackout may exist. Target coverage
#               is evaluated for that blackout ID only; coverage is never
#               combined across IDs.
#
# Security    : HTTPS is mandatory. Basic authentication is supplied to curl
#               through stdin, temporary files are mode 600, pagination links
#               are restricted to the configured OEM origin, and blackout IDs
#               are validated before use in request paths.
# -----------------------------------------------------------------------------

declare -a MF_OEM_TMP_FILES=()

mf_oem_error()
{
  printf 'OEM REST error: %s\n' "$*" >&2
  return 1
}

mf_oem_blackout_name()
{
  [ -n "${MF_OEM_BLACKOUT_NAME:-}" ] \
    || mf_oem_error "The canonical OEM blackout name has not been set" || return 1
  printf '%s\n' "$MF_OEM_BLACKOUT_NAME"
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
  local output_file="$4"
  local url="$first_url"
  local page_file next_href next_url merged_file
  local pages=0
  local seen='|'

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
    jq --slurpfile page "$page_file" '. + $page[0].items' "$output_file" > "$merged_file" \
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

mf_oem_find_exact_blackouts()
{
  local exact_file="$1"
  local suffixed_file="$2"
  local blackout_name encoded url all_file suffixed_count

  blackout_name=$(mf_oem_blackout_name) || return 1
  encoded=$(printf '%s%%' "$blackout_name" | mf_oem_urlencode) || return 1
  url="${MF_OEM_API_BASE_URL}/em/api/blackouts?limit=2000&nameMatches=${encoded}"
  mf_oem_new_temp_file all_file || return 1
  mf_oem_fetch_blackout_pages "$url" "$all_file" || return 1

  jq --arg name "$blackout_name" '[.[] | select(.name == $name)] | unique_by(.id)' \
    "$all_file" > "$exact_file" \
    || mf_oem_error "Unable to select exact-name OEM blackouts" || return 1
  jq --arg prefix "${blackout_name}_" '[.[] | select(.name | startswith($prefix))] | unique_by(.id)' \
    "$all_file" > "$suffixed_file" \
    || mf_oem_error "Unable to identify non-canonical OEM blackout names" || return 1

  suffixed_count=$(jq 'length' "$suffixed_file") || return 1
  if [ "$suffixed_count" -gt 0 ]
  then
    printf 'WARNING: Ignoring %s OEM blackout(s) whose name has a suffix; canonical name is %s\n' \
      "$suffixed_count" "$blackout_name" >&2
    jq -r '.[] | "WARNING: Ignored OEM blackout ID \(.id), name \(.name), status \(.status)"' \
      "$suffixed_file" >&2 || return 1
  fi
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

mf_oem_get_blackout()
{
  local blackout_id="$1"
  local response_file="$2"
  [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
    || mf_oem_error "OEM returned an unsafe blackout ID" || return 1
  mf_oem_http GET "${MF_OEM_API_BASE_URL}/em/api/blackouts/${blackout_id}" "$response_file" || return 1
  mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 200 "Blackout status" || return 1
  mf_oem_validate_blackout_response "$response_file"
}

mf_oem_fetch_blackout_targets()
{
  local blackout_id="$1"
  local output_file="$2"
  [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
    || mf_oem_error "OEM returned an unsafe blackout ID" || return 1
  mf_oem_fetch_target_pages \
    "${MF_OEM_API_BASE_URL}/em/api/blackouts/${blackout_id}/targets?limit=2000" \
    "/em/api/blackouts/${blackout_id}/targets" \
    "oracle_database,oracle_pdb" "$output_file"
}

mf_oem_target_ids_equal()
{
  local expected_file="$1"
  local actual_file="$2"
  jq -n -e --slurpfile expected "$expected_file" --slurpfile actual "$actual_file" '
    ([ $expected[0][].id ] | sort | unique) ==
    ([ $actual[0][].id ] | sort | unique)
  ' >/dev/null 2>&1
}

mf_oem_inspect_exact_blackouts()
{
  local candidates_file="$1"
  local expected_file="$2"
  local output_file="$3"
  local candidate_count blackout_id blackout_name
  local detail_file actual_file ids_match=false active=false

  blackout_name=$(mf_oem_blackout_name) || return 1
  candidate_count=$(jq 'length' "$candidates_file") || return 1
  if [ "$candidate_count" -ne 1 ]
  then
    jq -n --slurpfile candidates "$candidates_file" --slurpfile expected "$expected_file" '
      {
        candidateCount: ($candidates[0] | length),
        activeCandidateCount: ([ $candidates[0][] | select(.status as $status | [
          "SCHEDULED", "START_PROCESSING", "START_PARTIAL", "STARTED",
          "STOP_PENDING", "STOP_FAILED", "STOP_PARTIAL",
          "EDIT_PENDING", "EDIT_FAILED", "EDIT_PARTIAL", "END_PARTIAL"
        ] | index($status) != null) ] | length),
        candidates: $candidates[0],
        expectedTargets: $expected[0],
        exactTargetIds: false
      }
    ' > "$output_file" || mf_oem_error "Unable to describe OEM blackout candidates"
    return
  fi

  blackout_id=$(jq -er '.[0].id' "$candidates_file") || return 1
  [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
    || mf_oem_error "OEM returned an unsafe blackout ID" || return 1
  mf_oem_new_temp_file detail_file || return 1
  mf_oem_get_blackout "$blackout_id" "$detail_file" || return 1
  jq -e --arg id "$blackout_id" --arg name "$blackout_name" \
    '.id == $id and .name == $name' "$detail_file" >/dev/null \
    || mf_oem_error "OEM blackout identity changed during verification" || return 1

  mf_oem_new_temp_file actual_file || return 1
  mf_oem_fetch_blackout_targets "$blackout_id" "$actual_file" || return 1
  mf_oem_target_ids_equal "$expected_file" "$actual_file" && ids_match=true
  jq -e '.status as $status | [
      "SCHEDULED", "START_PROCESSING", "START_PARTIAL", "STARTED",
      "STOP_PENDING", "STOP_FAILED", "STOP_PARTIAL",
      "EDIT_PENDING", "EDIT_FAILED", "EDIT_PARTIAL", "END_PARTIAL"
    ] | index($status) != null' "$detail_file" >/dev/null && active=true

  jq -n \
    --argjson active "$active" \
    --argjson idsMatch "$ids_match" \
    --slurpfile candidates "$candidates_file" \
    --slurpfile detail "$detail_file" \
    --slurpfile expected "$expected_file" \
    --slurpfile actual "$actual_file" '
      {
        candidateCount: 1,
        activeCandidateCount: (if $active then 1 else 0 end),
        candidates: $candidates[0],
        blackoutId: $detail[0].id,
        status: $detail[0].status,
        active: $active,
        expectedTargets: $expected[0],
        actualTargets: $actual[0],
        exactTargetIds: $idsMatch
      }
    ' > "$output_file" || mf_oem_error "Unable to build the canonical OEM blackout inspection"
}

mf_oem_print_inspection()
{
  local inspection_file="$1"
  jq -r --arg name "$(mf_oem_blackout_name)" '
    def count_type($items; $type): [$items[] | select(.typeName == $type)] | length;
    "OEM canonical name     : \($name)",
    "OEM exact candidates  : \(.candidateCount)",
    (if .candidateCount == 1 then "OEM blackout ID       : \(.blackoutId)" else empty end),
    (if .candidateCount == 1 then "OEM blackout status   : \(.status)" else empty end),
    "Discovered targets    : \(.expectedTargets | length)",
    "oracle_database       : \(count_type(.expectedTargets; \"oracle_database\")) discovered",
    "oracle_pdb (optional) : \(count_type(.expectedTargets; \"oracle_pdb\")) discovered; every discovered PDB is required",
    (if .candidateCount == 1
     then "Discovered target IDs: \(if .exactTargetIds then \"COMPLETE\" else \"INCOMPLETE\" end)"
     else empty end),
    (if .candidateCount > 1
     then (.candidates[] | "Conflicting exact ID    : \(.id) [\(.status)]")
     else empty end)
  ' "$inspection_file" || mf_oem_error "Unable to format OEM blackout status"
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
    ($topology.targetContainerService) as $selectedService |
    ($topology.cdbName | ascii_downcase) as $cdbName |
    ($topology | type == "object") and
    ($topology.cdbName | type == "string" and length > 0) and
    ($topology.targetContainerService | type == "string" and length > 0) and
    ($topology.startClusterId | type == "string" and length > 0) and
    ($topology.clusters | type == "array" and length > 0 and all(
      type == "object" and
      (.clusterId | type == "string" and length > 0) and
      (.realName | type == "string" and length > 0)
    )) and
    ($topology.clusters | map(.clusterId) | unique | length) == ($topology.clusters | length) and
    ($topology.clusters | map(.realName | ascii_downcase) | unique | length) == ($topology.clusters | length) and
    ($topology.clusters | map(.clusterId) | index($topology.startClusterId)) != null and
    (($selectedService | db_name_from_unique_name | ascii_downcase) == $cdbName)
  ' "$topology_file" >/dev/null 2>&1 \
    || mf_oem_error "MF cluster topology and selected target service are missing, stale, or inconsistent"
}

mf_oem_resolve_topology()
{
  local repository_migration_id="$1"
  local cdb_name="$2"
  local target_container_service="$3"
  local output_file="$4"
  local cluster_rows

  [[ "$repository_migration_id" =~ ^[0-9]+$ ]] \
    || mf_oem_error "The internal MF migration ID must be numeric" || return 1

  # Match the legacy direct topology: the attempt cluster and its direct peer.
  cluster_rows=$(exec_sql "$MF_REPO_CONNECT" "
    select distinct
           to_char((select tclu_id from migration_attempts where mig_id = $repository_migration_id)) || '|' ||
           to_char(tc.tclu_id) || '|' ||
           lower(trim(tc.real_name))
    from target_clusters tc
    where (tc.prj_name, tc.tclu_id) = (
            select prj_name, tclu_id
            from migration_attempts
            where mig_id = $repository_migration_id
          )
       or (tc.prj_name, tc.tclu_id) = (
            select prj_name, peer_tclu_id
            from target_clusters
            where tclu_id = (
              select tclu_id from migration_attempts where mig_id = $repository_migration_id
            )
          );") \
    || mf_oem_error "Unable to resolve the direct MF target clusters" || return 1

  jq -n \
    --arg clusterRows "$cluster_rows" \
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
        clusters: ($rows | map(select(length == 3) | {
          clusterId: .[1],
          realName: .[2]
        }) | unique_by(.clusterId) | sort_by(.clusterId))
      }
    ' > "$output_file" || mf_oem_error "Unable to build the MF/OEM topology snapshot" || return 1

  mf_oem_validate_topology "$output_file"
}

mf_oem_query_targets()
{
  local pattern="$1"
  local output_file="$2"
  local encoded url

  encoded=$(printf '%s' "$pattern" | mf_oem_urlencode) || return 1
  url="${MF_OEM_API_BASE_URL}/em/api/targets?limit=100&typeName=oracle_database&typeName=oracle_pdb&nameMatches=${encoded}"
  mf_oem_fetch_target_pages "$url" "/em/api/targets" \
    "oracle_database,oracle_pdb" "$output_file"
}

mf_oem_filter_targets_by_topology()
{
  local topology_file="$1"
  local candidates_file="$2"
  local output_file="$3"

  jq -n \
    --slurpfile topology "$topology_file" \
    --slurpfile candidates "$candidates_file" '
      $topology[0] as $required |
      [ $candidates[0][] as $target |
        ([ $required.clusters[] as $cluster |
           (($cluster.realName | ascii_downcase) + "_" +
            ($required.cdbName | ascii_downcase)) as $prefix |
           ($target.name | ascii_downcase) as $targetName |
           select(($targetName == $prefix) or ($targetName | startswith($prefix + "_"))) |
           {
             clusterId: $cluster.clusterId,
             realName: $cluster.realName
           }
         ]) as $matches |
        {target: $target, matches: $matches}
      ] as $targetMappings |
      {
        targets: [ $targetMappings[] |
          select((.matches | length) == 1) |
          .target + {member: .matches[0]}
        ],
        ambiguousTargetCount: ([ $targetMappings[] | select((.matches | length) > 1) ] | length)
      }
    ' > "$output_file" || mf_oem_error "Unable to filter OEM targets by exact MF cluster/CDB prefix"
}

mf_oem_validate_resolved_targets()
{
  local topology_file="$1"
  local targets_file="$2"
  local normalized_file="$3"

  jq -n -e --slurpfile topology "$topology_file" --slurpfile targets "$targets_file" '
    ($topology[0]) as $required |
    ($targets[0]) as $resolved |
    ($required.cdbName | ascii_downcase) as $cdbName |
    ($resolved | type == "array" and length > 0 and all(
      type == "object" and
      (.id | type == "string" and length > 0) and
      (.name | type == "string" and length > 0) and
      (.typeName == "oracle_database" or .typeName == "oracle_pdb") and
      (.member | type == "object") and
      (.member.clusterId | type == "string" and length > 0) and
      (.member.realName | type == "string" and length > 0)
    )) and
    ($resolved | group_by(.id) | all((map([
      .name, .typeName, .member.clusterId, .member.realName
    ]) | unique | length) == 1)) and
    ($resolved | all(. as $target |
      (($target.member.realName | ascii_downcase) + "_" + $cdbName) as $prefix |
      ($target.name | ascii_downcase) as $targetName |
      (($targetName == $prefix) or ($targetName | startswith($prefix + "_"))) and
      ([ $required.clusters[] |
         select(.clusterId == $target.member.clusterId and
                 (.realName | ascii_downcase) == ($target.member.realName | ascii_downcase))
       ] | length) == 1
    )) and
    # Every cluster must expose at least one database target. PDB targets are
    # optional, but every discovered PDB remains in the authoritative ID set.
    ($required.clusters | all(. as $cluster |
      ([ $resolved[] |
         select(.member.clusterId == $cluster.clusterId and .typeName == "oracle_database") |
         .id
       ] | unique | length) >= 1
    )) and
    ([ $resolved[].member.clusterId ] | unique | length) == ($required.clusters | length)
  ' >/dev/null 2>&1 || mf_oem_error "Missing, conflicting, ambiguous, or unexpected OEM targets" || return 1

  jq 'sort_by(.id) | unique_by(.id)' "$targets_file" > "$normalized_file" \
    || mf_oem_error "Unable to normalize OEM targets"
}

mf_oem_discover_targets()
{
  local topology_file="$1"
  local output_file="$2"
  local pattern query_file resolution_file selected_file normalized_file

  pattern="%$(jq -r '.cdbName' "$topology_file")%"
  mf_oem_new_temp_file query_file || return 1
  mf_oem_query_targets "$pattern" "$query_file" || return 1

  mf_oem_new_temp_file resolution_file || return 1
  mf_oem_filter_targets_by_topology "$topology_file" "$query_file" "$resolution_file" || return 1
  jq -e '.ambiguousTargetCount == 0' "$resolution_file" >/dev/null 2>&1 \
    || mf_oem_error "An OEM target name matches more than one MF cluster/CDB prefix" || return 1

  mf_oem_new_temp_file selected_file || return 1
  jq '.targets' "$resolution_file" > "$selected_file" || return 1
  mf_oem_new_temp_file normalized_file || return 1
  mf_oem_validate_resolved_targets "$topology_file" "$selected_file" "$normalized_file" || return 1
  mv -f -- "$normalized_file" "$output_file" || return 1
}

mf_oem_parse_duration()
{
  local duration="$1"
  local days=0 hours minutes total_hours

  if [[ "$duration" =~ ^([0-9]+)[[:space:]]+([0-9]{1,2}):([0-9]{2})$ ]]
  then
    days=$((10#${BASH_REMATCH[1]}))
    hours=$((10#${BASH_REMATCH[2]}))
    minutes=$((10#${BASH_REMATCH[3]}))
    [ "$hours" -le 23 ] || mf_oem_error "REST duration day form requires an hour from 00 to 23" || return 1
  elif [[ "$duration" =~ ^([0-9]+):([0-9]{2})$ ]]
  then
    hours=$((10#${BASH_REMATCH[1]}))
    minutes=$((10#${BASH_REMATCH[2]}))
  else
    mf_oem_error "REST duration must use [D ]HH:MI format"
    return 1
  fi
  [ "$minutes" -le 59 ] || mf_oem_error "REST duration minutes must be from 00 to 59" || return 1
  total_hours=$((days * 24 + hours))
  [ "$total_hours" -gt 0 ] || [ "$minutes" -gt 0 ] \
    || mf_oem_error "REST duration must be greater than zero" || return 1
  printf '%s|%s\n' "$total_hours" "$minutes"
}

mf_oem_build_payload()
{
  local migration_id="$1"
  local targets_file="$2"
  local duration="$3"
  local payload_file="$4"
  local duration_parts duration_hours duration_minutes blackout_name

  duration_parts=$(mf_oem_parse_duration "$duration") || return 1
  duration_hours=${duration_parts%%|*}
  duration_minutes=${duration_parts#*|}
  blackout_name=$(mf_oem_blackout_name) || return 1
  jq -n \
    --arg name "$blackout_name" \
    --arg description "Migration Factory planned maintenance for ${migration_id}; OEM monitoring blackout for the requested duration." \
    --argjson reasonId "$MF_OEM_BLACKOUT_REASON_ID" \
    --argjson allowJobs "$MF_OEM_BLACKOUT_ALLOW_JOBS" \
    --argjson durationHours "$duration_hours" \
    --argjson durationMinutes "$duration_minutes" \
    --slurpfile targets "$targets_file" '
      {
        name: $name,
        type: "PATCHING",
        reasonId: $reasonId,
        description: $description,
        isAllowJobs: $allowJobs,
        isFullBlackoutOnHost: false,
        durationHours: $durationHours,
        durationMinutes: $durationMinutes,
        targets: ($targets[0] | map({id: .id}))
      }
    ' > "$payload_file" || mf_oem_error "Unable to build the OEM blackout JSON payload"
}

mf_oem_start_status_result()
{
  case "$1" in
    SCHEDULED|STARTED) return 0 ;;
    START_PROCESSING) return 2 ;;
    START_PARTIAL|START_FAILED) mf_oem_error "OEM blackout returned terminal start status $1" ;;
    *) mf_oem_error "OEM blackout returned unexpected start status $1" ;;
  esac
}

mf_oem_stop_status_result()
{
  case "$1" in
    STOPPED|ENDED) return 0 ;;
    STARTED|STOP_PENDING) return 2 ;;
    START_PARTIAL|START_FAILED|STOP_FAILED|STOP_PARTIAL|END_PARTIAL)
      mf_oem_error "OEM blackout returned terminal stop status $1"
      ;;
    *) mf_oem_error "OEM blackout returned unexpected stop status $1" ;;
  esac
}

mf_oem_wait_for_start_accepted()
{
  local blackout_id="$1"
  local response_file="$2"
  local attempt=1 status rc

  while [ "$attempt" -le "$MF_OEM_VERIFY_ATTEMPTS" ]
  do
    status=$(jq -r '.status' "$response_file") || return 1
    mf_oem_start_status_result "$status"
    rc=$?
    [ "$rc" -eq 0 ] && return 0
    [ "$rc" -eq 2 ] || return 1
    [ "$attempt" -lt "$MF_OEM_VERIFY_ATTEMPTS" ] || break
    sleep "$MF_OEM_VERIFY_INTERVAL"
    mf_oem_get_blackout "$blackout_id" "$response_file" || return 1
    attempt=$((attempt + 1))
  done
  mf_oem_error "OEM blackout did not reach SCHEDULED or STARTED within the verification window"
}

mf_oem_wait_for_stopped()
{
  local blackout_id="$1"
  local response_file="$2"
  local attempt=1 status rc

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
  mf_oem_error "OEM blackout did not reach STOPPED or ENDED within the verification window"
}

mf_oem_verify_blackout_targets()
{
  local blackout_id="$1"
  local expected_file="$2"
  local actual_file
  mf_oem_new_temp_file actual_file || return 1
  mf_oem_fetch_blackout_targets "$blackout_id" "$actual_file" || return 1
  mf_oem_target_ids_equal "$expected_file" "$actual_file" \
    || mf_oem_error "OEM blackout does not have complete discovered target coverage"
}

mf_oem_print_blackout()
{
  local response_file="$1"
  jq -r '
    "OEM blackout ID       : \(.id)",
    "OEM blackout name     : \(.name)",
    "OEM blackout status   : \(.status)"
  ' "$response_file" || mf_oem_error "Unable to format OEM blackout status"
}

mf_oem_prepare_inspection()
{
  local repository_migration_id="$1"
  local cdb_name="$2"
  local target_container_service="$3"
  local topology_file="$4"
  local targets_file="$5"
  local candidates_file="$6"
  local inspection_file="$7"
  local suffixed_file

  mf_oem_resolve_topology "$repository_migration_id" "$cdb_name" \
    "$target_container_service" "$topology_file" || return 1
  mf_oem_discover_targets "$topology_file" "$targets_file" || return 1
  mf_oem_new_temp_file suffixed_file || return 1
  mf_oem_find_exact_blackouts "$candidates_file" "$suffixed_file" || return 1
  MF_OEM_EXACT_CANDIDATE_COUNT=$(jq 'length' "$candidates_file") || return 1
  mf_oem_inspect_exact_blackouts "$candidates_file" "$targets_file" "$inspection_file"
}

mf_oem_start_blackout()
{
  local migration_id="$1"
  local repository_migration_id="$2"
  local cdb_name="$3"
  local target_container_service="$4"
  local duration="$5"
  local topology_file targets_file candidates_file inspection_file payload_file response_file
  local candidate_count blackout_id status

  umask 077
  MF_OEM_BLACKOUT_NAME=MF_2_${cdb_name}_Migration
  MF_OEM_TMP_FILES=()
  MF_OEM_START_MUTATION_ATTEMPTED=N
  MF_OEM_MUTATION_ATTEMPTED=N
  MF_OEM_EXACT_CANDIDATE_COUNT=
  mf_oem_validate_config || return 1
  mf_oem_new_temp_file topology_file || return 1
  mf_oem_new_temp_file targets_file || return 1
  mf_oem_new_temp_file candidates_file || return 1
  mf_oem_new_temp_file inspection_file || return 1
  if ! mf_oem_prepare_inspection "$repository_migration_id" "$cdb_name" \
       "$target_container_service" "$topology_file" "$targets_file" \
       "$candidates_file" "$inspection_file"
  then
    # Once an exact-name candidate is known to exist, inability to verify its
    # state or targets is a semantic conflict. Do not create or use emctl.
    [ "${MF_OEM_EXACT_CANDIDATE_COUNT:-0}" -gt 0 ] && return 3
    return 1
  fi
  mf_oem_print_inspection "$inspection_file" || return 1

  candidate_count=$(jq '.candidateCount' "$inspection_file") || return 1
  if [ "$candidate_count" -eq 1 ]
  then
    if jq -e '
         .activeCandidateCount == 1 and
         (.status == "SCHEDULED" or .status == "STARTED") and
         .exactTargetIds
       ' "$inspection_file" >/dev/null
    then
      printf 'OEM blackout already has complete discovered target coverage; no new blackout was created.\n'
      return 0
    fi
    mf_oem_error "The exact canonical OEM blackout is incomplete or is not in an accepted START state"
    return 3
  elif [ "$candidate_count" -gt 1 ]
  then
    mf_oem_error "More than one exact canonical OEM blackout exists"
    return 3
  fi

  mf_oem_new_temp_file payload_file || return 1
  mf_oem_new_temp_file response_file || return 1
  mf_oem_build_payload "$migration_id" "$targets_file" "$duration" "$payload_file" || return 1
  # Any create attempt may have reached OEM even when its response is lost.
  MF_OEM_START_MUTATION_ATTEMPTED=Y
  MF_OEM_MUTATION_ATTEMPTED=Y
  mf_oem_http POST "${MF_OEM_API_BASE_URL}/em/api/blackouts" "$response_file" "$payload_file" || return 1
  mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 201 "Blackout creation" || return 1
  mf_oem_validate_blackout_response "$response_file" || return 1
  jq -e --arg name "$(mf_oem_blackout_name)" '.name == $name' "$response_file" >/dev/null \
    || mf_oem_error "OEM created a blackout whose name is not canonical" || return 1
  blackout_id=$(jq -r '.id' "$response_file") || return 1
  [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
    || mf_oem_error "OEM returned an unsafe blackout ID" || return 1
  mf_oem_wait_for_start_accepted "$blackout_id" "$response_file" || return 1
  mf_oem_verify_blackout_targets "$blackout_id" "$targets_file" || return 1
  status=$(jq -r '.status' "$response_file") || return 1

  printf 'OEM blackout ID       : %s\n' "$blackout_id"
  printf 'OEM blackout status   : %s\n' "$status"
  printf 'OEM blackout duration : %s\n' "$duration"
  printf 'Resolved target count : %s\n' "$(jq 'length' "$targets_file")"
}

mf_oem_status_blackout()
{
  local migration_id="$1"
  local repository_migration_id="$2"
  local cdb_name="$3"
  local target_container_service="$4"
  local topology_file targets_file candidates_file inspection_file

  : "$migration_id"
  umask 077
  MF_OEM_BLACKOUT_NAME=MF_2_${cdb_name}_Migration
  MF_OEM_TMP_FILES=()
  mf_oem_validate_config || return 1
  mf_oem_new_temp_file topology_file || return 1
  mf_oem_new_temp_file targets_file || return 1
  mf_oem_new_temp_file candidates_file || return 1
  mf_oem_new_temp_file inspection_file || return 1
  mf_oem_prepare_inspection "$repository_migration_id" "$cdb_name" \
    "$target_container_service" "$topology_file" "$targets_file" \
    "$candidates_file" "$inspection_file" || return 1
  mf_oem_print_inspection "$inspection_file"
}

mf_oem_is_blackout_on()
{
  local migration_id="$1"
  local repository_migration_id="$2"
  local cdb_name="$3"
  local target_container_service="$4"
  local topology_file targets_file candidates_file inspection_file

  : "$migration_id"
  umask 077
  MF_OEM_BLACKOUT_NAME=MF_2_${cdb_name}_Migration
  MF_OEM_TMP_FILES=()
  mf_oem_validate_config || return 1
  mf_oem_new_temp_file topology_file || return 1
  mf_oem_new_temp_file targets_file || return 1
  mf_oem_new_temp_file candidates_file || return 1
  mf_oem_new_temp_file inspection_file || return 1
  mf_oem_prepare_inspection "$repository_migration_id" "$cdb_name" \
    "$target_container_service" "$topology_file" "$targets_file" \
    "$candidates_file" "$inspection_file" || return 1
  mf_oem_print_inspection "$inspection_file" || return 1
  if jq -e '
       .candidateCount == 1 and
       .activeCandidateCount == 1 and
       .status == "STARTED" and
       .exactTargetIds
     ' "$inspection_file" >/dev/null
  then
    printf 'OEM blackout has complete discovered target coverage and is ON.\n'
    return 0
  fi
  printf 'OEM blackout is not fully ON for the complete discovered target set.\n'
  return 3
}

mf_oem_delete_blackout()
{
  local blackout_id="$1"
  local response_file

  [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
    || mf_oem_error "OEM returned an unsafe blackout ID" || return 1
  mf_oem_new_temp_file response_file || return 1
  # Mark the boundary before DELETE. A lost response must block emctl fallback.
  MF_OEM_DELETE_MUTATION_ATTEMPTED=Y
  MF_OEM_STOP_MUTATION_ATTEMPTED=Y
  MF_OEM_MUTATION_ATTEMPTED=Y
  mf_oem_http DELETE "${MF_OEM_API_BASE_URL}/em/api/blackouts/${blackout_id}" "$response_file" || return 1
  mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 204 "Blackout deletion" || return 1
  printf 'OEM blackout deleted  : %s\n' "$blackout_id"
}

mf_oem_stop_blackout()
{
  local migration_id="$1"
  local repository_migration_id="$2"
  local cdb_name="$3"
  local target_container_service="$4"
  local topology_file targets_file candidates_file inspection_file response_file stop_file
  local blackout_id status

  : "$migration_id"
  umask 077
  MF_OEM_BLACKOUT_NAME=MF_2_${cdb_name}_Migration
  MF_OEM_TMP_FILES=()
  MF_OEM_STOP_MUTATION_ATTEMPTED=N
  MF_OEM_DELETE_MUTATION_ATTEMPTED=N
  MF_OEM_MUTATION_ATTEMPTED=N
  MF_OEM_EXACT_CANDIDATE_COUNT=
  mf_oem_validate_config || return 1
  mf_oem_new_temp_file topology_file || return 1
  mf_oem_new_temp_file targets_file || return 1
  mf_oem_new_temp_file candidates_file || return 1
  mf_oem_new_temp_file inspection_file || return 1
  if ! mf_oem_prepare_inspection "$repository_migration_id" "$cdb_name" \
       "$target_container_service" "$topology_file" "$targets_file" \
       "$candidates_file" "$inspection_file"
  then
    [ "${MF_OEM_EXACT_CANDIDATE_COUNT:-0}" -gt 0 ] && return 3
    return 1
  fi
  mf_oem_print_inspection "$inspection_file" || return 1

  if ! jq -e '
       .candidateCount == 1 and
       .activeCandidateCount == 1 and
       .exactTargetIds
     ' "$inspection_file" >/dev/null
  then
    mf_oem_error "STOP requires exactly one active exact-name blackout with complete discovered target coverage"
    return 3
  fi
  blackout_id=$(jq -r '.blackoutId' "$inspection_file") || return 1
  [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
    || mf_oem_error "OEM returned an unsafe blackout ID" || return 1

  mf_oem_new_temp_file response_file || return 1
  mf_oem_get_blackout "$blackout_id" "$response_file" || return 1
  jq -e --arg id "$blackout_id" --arg name "$(mf_oem_blackout_name)" \
    '.id == $id and .name == $name' "$response_file" >/dev/null \
    || mf_oem_error "OEM blackout identity changed before STOP" || return 1
  status=$(jq -r '.status' "$response_file") || return 1

  case "$status" in
    STARTED)
      mf_oem_new_temp_file stop_file || return 1
      MF_OEM_STOP_MUTATION_ATTEMPTED=Y
      MF_OEM_MUTATION_ATTEMPTED=Y
      mf_oem_http POST "${MF_OEM_API_BASE_URL}/em/api/blackouts/${blackout_id}/actions/stop" "$stop_file" || return 1
      mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 204 "Blackout stop" || return 1
      ;;
    STOP_PENDING)
      # The stop mutation happened before this rediscovery.
      MF_OEM_STOP_MUTATION_ATTEMPTED=Y
      MF_OEM_MUTATION_ATTEMPTED=Y
      ;;
    STOPPED|ENDED)
      # A STARTED blackout can reach its terminal state between inspection and
      # this identity recheck. Continue with the same verified ID only.
      ;;
    *)
      mf_oem_error "Canonical OEM blackout changed to non-stoppable status $status"
      return 4
      ;;
  esac

  case "$status" in
    STOPPED|ENDED) : ;;
    *) mf_oem_wait_for_stopped "$blackout_id" "$response_file" || return 1 ;;
  esac
  jq -e --arg id "$blackout_id" --arg name "$(mf_oem_blackout_name)" \
    '.id == $id and .name == $name and (.status == "STOPPED" or .status == "ENDED")' \
    "$response_file" >/dev/null \
    || mf_oem_error "OEM blackout identity or terminal stop state could not be verified" || return 1
  mf_oem_print_blackout "$response_file" || return 1
  mf_oem_delete_blackout "$blackout_id"
}
