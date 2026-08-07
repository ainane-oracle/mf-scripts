#!/usr/bin/env bash

# OEM REST support for every mfEmBlackout.sh action selected with -r.
# Authentication is passed to curl over stdin so the password is never present in
# the process command line, logs, response files, or temporary files.

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

  MF_OEM_HTTP_STATUS=$(mf_oem_authorization_config | curl "${args[@]}")
  MF_OEM_HTTP_RC=$?
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
  local expected_type="$3"
  local required_cdb="$4"
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

    if [ -n "$expected_type" ]
    then
      jq -e --arg type "$expected_type" '.items | all(.typeName == $type)' "$page_file" >/dev/null \
        || mf_oem_error "OEM returned an unexpected target type" || return 1
    fi

    mf_oem_new_temp_file merged_file || return 1
    jq --arg cdb "$required_cdb" --slurpfile page "$page_file" \
      '. + ($page[0].items | map(. + {requiredCdb: $cdb}))' "$output_file" > "$merged_file" \
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
  local selected_file count

  mf_oem_new_temp_file selected_file || return 1
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
  local encoded url blackouts_file

  blackout_name=$(mf_oem_blackout_name "$migration_id") || return 1

  encoded=$(printf '%s' "$blackout_name" | mf_oem_urlencode) || return 1
  url="${MF_OEM_API_BASE_URL}/em/api/blackouts?limit=2000&sort=id%3AASC&name=${encoded}"
  mf_oem_new_temp_file blackouts_file || return 1
  mf_oem_fetch_blackout_pages "$url" "$blackouts_file" || return 1
  mf_oem_select_active_blackout "$blackouts_file" "$blackout_name" "$output_file"
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
  local required_file="$1"
  local targets_file="$2"
  local normalized_file="$3"

  jq -n -e --slurpfile required "$required_file" --slurpfile targets "$targets_file" '
    ($targets[0] | type == "array" and length > 0 and all(
      type == "object" and
      (.id | type == "string" and length > 0) and
      (.name | type == "string" and length > 0) and
      (.typeName == "oracle_database" or .typeName == "oracle_pdb") and
      (.requiredCdb | type == "string" and length > 0)
    )) and
    ($targets[0] | group_by(.id) | all((map([.name, .typeName, .requiredCdb]) | unique | length) == 1)) and
    ($targets[0] | group_by([.name, .typeName]) | all((map(.id) | unique | length) == 1)) and
    ($required[0] | type == "array" and length > 0 and all(. as $cdb |
      ([ $targets[0][] | select(.requiredCdb == $cdb and .typeName == "oracle_database" and .name == $cdb) | .id ] | unique | length) == 1
    )) and
    ($targets[0] | all(. as $target |
      ($required[0] | index($target.requiredCdb)) != null and
      (if $target.typeName == "oracle_database" then $target.name == $target.requiredCdb
       else ($target.name | contains($target.requiredCdb)) end)
    ))
  ' >/dev/null 2>&1 || mf_oem_error "Missing, duplicate, ambiguous, or unexpected OEM targets" || return 1

  jq 'sort_by(.id) | unique_by(.id)' "$targets_file" > "$normalized_file" \
    || mf_oem_error "Unable to normalize OEM targets" || return 1
}

mf_oem_parse_required_cdb_names()
{
  local primary_cdb="$1"
  local peer_count="$2"
  local output_file="$3"
  local configured="${MF_OEM_REQUIRED_CDB_NAMES:-}"

  if [ -z "$configured" ]
  then
    [ "$peer_count" = "0" ] \
      || mf_oem_error "Peer topology exists but MF_OEM_REQUIRED_CDB_NAMES does not provide exact primary and standby OEM CDB target names" \
      || return 1
    configured="$primary_cdb"
  fi

  printf '%s\n' "$configured" | tr ', ' '\n\n' | sed '/^[[:space:]]*$/d' \
    | jq -Rsc 'split("\n") | map(select(length > 0)) | unique' > "$output_file" \
    || mf_oem_error "Unable to parse MF_OEM_REQUIRED_CDB_NAMES" || return 1
  jq -e --arg primary "$primary_cdb" \
    'type == "array" and length > 0 and all(type == "string" and length > 0) and index($primary) != null' \
    "$output_file" >/dev/null \
    || mf_oem_error "MF_OEM_REQUIRED_CDB_NAMES must include the selected primary OEM CDB target name: $primary_cdb" || return 1
  [ "$(jq 'length' "$output_file")" -ge $((peer_count + 1)) ] \
    || mf_oem_error "MF_OEM_REQUIRED_CDB_NAMES does not cover every repository peer target" || return 1
}

mf_oem_discover_targets()
{
  local required_file="$1"
  local output_file="$2"
  local cdb type pattern encoded url query_file normalized

  printf '[]\n' > "$output_file" || return 1
  while IFS= read -r cdb
  do
    for type in oracle_database oracle_pdb
    do
      if [ "$type" = "oracle_database" ]
      then
        pattern="$cdb"
      else
        pattern="%${cdb}%"
      fi
      encoded=$(printf '%s' "$pattern" | mf_oem_urlencode) || return 1
      url="${MF_OEM_API_BASE_URL}/em/api/targets?limit=2000&sort=name%3AASC&typeName=${type}&nameMatches=${encoded}"
      mf_oem_new_temp_file query_file || return 1
      mf_oem_fetch_target_pages "$url" "/em/api/targets" "$type" "$cdb" "$query_file" || return 1
      mf_oem_append_json_array "$output_file" "$query_file" || return 1
    done
  done < <(jq -r '.[]' "$required_file")

  mf_oem_new_temp_file normalized || return 1
  mf_oem_validate_resolved_targets "$required_file" "$output_file" "$normalized" || return 1
  mv -f -- "$normalized" "$output_file" || return 1
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
  local required_file="$2"
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
    --slurpfile required "$required_file" \
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
        requiredCdbNames: $required[0],
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
    "${MF_OEM_API_BASE_URL}/em/api/blackouts/${blackout_id}/targets?limit=2000&sort=id%3AASC" \
    "/em/api/blackouts/${blackout_id}/targets" "" "" "$actual_file" || return 1

  expected_ids=$(jq -c '[.[] | [.id, .name, .typeName]] | sort | unique' "$expected_file") || return 1
  actual_ids=$(jq -c '[.[] | [.id, .name, .typeName]] | sort | unique' "$actual_file") || return 1
  [ "$expected_ids" = "$actual_ids" ] \
    || mf_oem_error "OEM blackout target coverage does not exactly match the resolved target snapshot"
}

mf_oem_start_blackout()
{
  local migration_id="$1"
  local primary_cdb="$2"
  local peer_count="$3"
  local time_to_end="$4"
  local required_file targets_file payload_file response_file blackout_id
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
  mf_oem_new_temp_file required_file || return 1
  mf_oem_new_temp_file targets_file || return 1
  mf_oem_new_temp_file payload_file || return 1
  mf_oem_new_temp_file response_file || return 1

  mf_oem_parse_required_cdb_names "$primary_cdb" "$peer_count" "$required_file" || return 1
  mf_oem_discover_targets "$required_file" "$targets_file" || return 1
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

  mf_oem_write_state "$migration_id" "$required_file" "$targets_file" "$response_file" false || return 1
  mf_oem_wait_for_started "$blackout_id" "$response_file" || {
    mf_oem_write_state "$migration_id" "$required_file" "$targets_file" "$response_file" false >/dev/null 2>&1 || :
    return 1
  }
  mf_oem_verify_blackout_targets "$blackout_id" "$targets_file" || {
    mf_oem_write_state "$migration_id" "$required_file" "$targets_file" "$response_file" false >/dev/null 2>&1 || :
    return 1
  }
  mf_oem_write_state "$migration_id" "$required_file" "$targets_file" "$response_file" true || return 1

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
