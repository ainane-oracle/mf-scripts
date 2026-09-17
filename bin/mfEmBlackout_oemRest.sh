#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# File        : mfEmBlackout_oemRest.sh
# Purpose     : OEM REST API support for mfEmBlackout.sh when -r is used.
#
# Invariant   : START and IS_ON require one managed blackout ID to cover the
#               exact target set, now, and the requested end. STARTED qualifies
#               immediately. SCHEDULED qualifies after its start is two minutes
#               overdue. Coverage is never combined across blackout IDs.
#
# Security    : HTTPS is mandatory. The OEM password is read from the existing
#               Migration Factory KeePass store. Basic authentication is
#               supplied to curl through stdin, temporary files are mode 600,
#               pagination links are restricted to the configured OEM origin,
#               and blackout IDs are validated before use in request paths.
# -----------------------------------------------------------------------------

MF_OEM_REST_VERSION=1.19
# -----------------------------------------------------------------------------
# Modifications:
# ==============
#
# 06/08/2026 AIN - Version 1.9, add opt-in centralized OEM REST blackout
#                  support for Migration Factory.
# 07/08/2026 AIN - Versions 1.10-1.12, add REST lifecycle actions, preserve
#                  local emctl compatibility, and harden REST fallback rules.
# 08/08/2026 AIN - Versions 1.13-1.14, use one canonical blackout identity,
#                  verify target-ID coverage, and handle STOP_PENDING safely.
# 10/08/2026 AIN - Version 1.15, derive REST START duration from the planned
#                  GO-LIVE window when no explicit duration is supplied.
# 15/09/2026 AIN - Version 1.16, classify STOPPED and ENDED same-name records
#                  as historical, reuse verified duplicate STARTED records,
#                  and stop every verified exact-coverage STARTED duplicate.
# 17/09/2026 AIN - Version 1.19, manage the canonical name as a record family.
#                  START and IS_ON verify exact targets and time coverage,
#                  ignore terminal history, and accept SCHEDULED after two
#                  minutes. STOP processes every active managed duplicate.
# -----------------------------------------------------------------------------

declare -a MF_OEM_TMP_FILES=()

mf_oem_error()
{
  printf '         - OEM REST error: %s\n' "$*" >&2
  return 1
}

mf_oem_log()
{
  if declare -F infoAction >/dev/null 2>&1
  then
    infoAction "OEM REST: $*" "${I2:-  - }"
  else
    printf '         - OEM REST: %s\n' "$*"
  fi
}

mf_oem_warning()
{
  printf '         - OEM REST warning: %s\n' "$*" >&2
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

mf_oem_is_managed_blackout_name()
{
  local candidate_name="$1"
  local base_name suffix

  base_name=$(mf_oem_blackout_name) || return 1
  [ "$candidate_name" = "$base_name" ] && return 0
  case "$candidate_name" in
    "$base_name"_*) suffix=${candidate_name#"$base_name"_} ;;
    *) return 1 ;;
  esac
  [[ "$suffix" =~ ^[0-9]{8}T[0-9]{6}Z$ ]]
}

mf_oem_validate_blackout_identity()
{
  local response_file="$1"
  local expected_id="$2"
  local actual_id actual_name

  actual_id=$(jq -er '.id' "$response_file" 2>/dev/null) || return 1
  actual_name=$(jq -er '.name' "$response_file" 2>/dev/null) || return 1
  [ "$actual_id" = "$expected_id" ] && mf_oem_is_managed_blackout_name "$actual_name"
}

mf_oem_timestamped_blackout_name()
{
  local timestamp
  timestamp=$(date -u '+%Y%m%dT%H%M%SZ') || return 1
  printf '%s_%s\n' "$(mf_oem_blackout_name)" "$timestamp"
}

mf_oem_load_credentials()
{
  local password_type=WEB_USER
  local password_id=OEM_REST_API

  # The OEM account is deployment-wide. Only its password is stored in
  # KeePass, under the existing Migration Factory TYPE|ID convention.
  MF_OEM_API_USERNAME=MF_BLACKOUT
  unset MF_OEM_API_PASSWORD

  [ "${MF_PASSWORD_STORE:-}" = "KEEPASS" ] \
    || mf_oem_error "MF_PASSWORD_STORE must be KEEPASS for OEM REST authentication" || return 1
  declare -F isPasswordStored >/dev/null 2>&1 \
    || mf_oem_error "KeePass existence check is not available" || return 1
  declare -F getSecretPassword >/dev/null 2>&1 \
    || mf_oem_error "KeePass password retrieval is not available" || return 1

  isPasswordStored "$password_type" "$password_id" \
    || mf_oem_error "OEM password entry ${password_type}|${password_id} is missing from KeePass" || return 1

  # getSecretPassword can emit secret values through the shared MF_DEBUG
  # path. Disable that debug path only for this retrieval.
  MF_OEM_API_PASSWORD=$(MF_DEBUG=N getSecretPassword "$password_type" "$password_id") \
    || mf_oem_error "Unable to retrieve OEM password from KeePass entry ${password_type}|${password_id}" || return 1
  [ -n "$MF_OEM_API_PASSWORD" ] \
    || mf_oem_error "KeePass returned an empty OEM password" || return 1
}

mf_oem_validate_config()
{
  [ -n "${MF_OEM_API_BASE_URL:-}" ] || mf_oem_error "MF_OEM_API_BASE_URL is required" || return 1
  [[ "$MF_OEM_API_BASE_URL" =~ ^https://([A-Za-z0-9._-]+|\[[0-9A-Fa-f:]+\])(:[0-9]+)?/?$ ]] \
    || mf_oem_error "MF_OEM_API_BASE_URL must be an HTTPS origin without a path" || return 1
  mf_oem_load_credentials || return 1

  MF_OEM_API_BASE_URL=${MF_OEM_API_BASE_URL%/}
  MF_OEM_BLACKOUT_REASON_ID=${MF_OEM_BLACKOUT_REASON_ID:-29}
  MF_OEM_BLACKOUT_ALLOW_JOBS=${MF_OEM_BLACKOUT_ALLOW_JOBS:-true}
  MF_OEM_VERIFY_ATTEMPTS=${MF_OEM_VERIFY_ATTEMPTS:-${MF_OEM_START_VERIFY_ATTEMPTS:-12}}
  MF_OEM_VERIFY_INTERVAL=${MF_OEM_VERIFY_INTERVAL:-${MF_OEM_START_VERIFY_INTERVAL:-5}}
  MF_OEM_SCHEDULED_ACCEPT_SECONDS=${MF_OEM_SCHEDULED_ACCEPT_SECONDS:-120}
  MF_OEM_RENEWAL_GRACE_SECONDS=${MF_OEM_RENEWAL_GRACE_SECONDS:-300}

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
  [[ "$MF_OEM_SCHEDULED_ACCEPT_SECONDS" =~ ^[1-9][0-9]*$ ]] \
    || mf_oem_error "MF_OEM_SCHEDULED_ACCEPT_SECONDS must be a positive integer" || return 1
  [[ "$MF_OEM_RENEWAL_GRACE_SECONDS" =~ ^[0-9]+$ ]] \
    || mf_oem_error "MF_OEM_RENEWAL_GRACE_SECONDS must be a non-negative integer" || return 1

  MF_OEM_BLACKOUT_REASON_ID=$((10#$MF_OEM_BLACKOUT_REASON_ID))
  MF_OEM_VERIFY_ATTEMPTS=$((10#$MF_OEM_VERIFY_ATTEMPTS))
  MF_OEM_VERIFY_INTERVAL=$((10#$MF_OEM_VERIFY_INTERVAL))
  MF_OEM_SCHEDULED_ACCEPT_SECONDS=$((10#$MF_OEM_SCHEDULED_ACCEPT_SECONDS))
  MF_OEM_RENEWAL_GRACE_SECONDS=$((10#$MF_OEM_RENEWAL_GRACE_SECONDS))

  if [ -n "${MF_OEM_CA_CERT:-}" ] && [ ! -r "$MF_OEM_CA_CERT" ]
  then
    mf_oem_error "MF_OEM_CA_CERT is not readable"
    return 1
  fi

  mf_oem_require_command curl || return 1
  mf_oem_require_command jq || return 1
  mf_oem_require_command base64 || return 1
  mf_oem_require_command date || return 1
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
  unset MF_OEM_API_PASSWORD
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
  local managed_file="$1"
  local ignored_file="$2"
  local blackout_name encoded url all_file ignored_count

  blackout_name=$(mf_oem_blackout_name) || return 1
  encoded=$(printf '%s%%' "$blackout_name" | mf_oem_urlencode) || return 1
  url="${MF_OEM_API_BASE_URL}/em/api/blackouts?limit=2000&nameMatches=${encoded}"
  mf_oem_new_temp_file all_file || return 1
  mf_oem_fetch_blackout_pages "$url" "$all_file" || return 1

  jq --arg name "$blackout_name" '
    def managed_name:
      . == $name or
      (startswith($name + "_") and
       (ltrimstr($name + "_") | test("^[0-9]{8}T[0-9]{6}Z$")));
    [.[] | select(.name | managed_name)] | unique_by(.id)
  ' "$all_file" > "$managed_file" \
    || mf_oem_error "Unable to select managed OEM blackouts" || return 1
  jq --arg name "$blackout_name" '
    def managed_name:
      . == $name or
      (startswith($name + "_") and
       (ltrimstr($name + "_") | test("^[0-9]{8}T[0-9]{6}Z$")));
    [.[] | select(.name | startswith($name)) | select((.name | managed_name) | not)] |
    unique_by(.id)
  ' "$all_file" > "$ignored_file" \
    || mf_oem_error "Unable to identify unmanaged similarly named OEM blackouts" || return 1

  ignored_count=$(jq 'length' "$ignored_file") || return 1
  if [ "$ignored_count" -gt 0 ]
  then
    mf_oem_warning "Ignored $ignored_count similarly named blackout definition(s) outside the managed name family"
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
    "oracle_database,oracle_pdb,rac_database" "$output_file"
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
  local candidate_count blackout_id blackout_name current_status
  local detail_file actual_file entry_file append_file inspected_file
  local ids_match terminal active_now covers_required_end scheduled_accepted
  local start_time end_time start_epoch end_epoch start_epoch_json end_epoch_json

  blackout_name=$(mf_oem_blackout_name) || return 1
  candidate_count=$(jq 'length' "$candidates_file") || return 1
  mf_oem_new_temp_file inspected_file || return 1
  printf '[]\n' > "$inspected_file" || return 1

  for blackout_id in $(jq -r '.[].id' "$candidates_file")
  do
    [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
      || mf_oem_error "OEM returned an unsafe blackout ID" || return 1
    mf_oem_new_temp_file detail_file || return 1
    mf_oem_get_blackout "$blackout_id" "$detail_file" || return 1
    mf_oem_validate_blackout_identity "$detail_file" "$blackout_id" \
      || mf_oem_error "OEM blackout identity changed during verification" || return 1
    current_status=$(jq -r '.status' "$detail_file") || return 1

    terminal=false
    ids_match=false
    active_now=false
    covers_required_end=false
    scheduled_accepted=false
    start_epoch_json=null
    end_epoch_json=null
    mf_oem_new_temp_file actual_file || return 1
    start_time=$(jq -r '.creationTimeToStart // .timeToStart // empty' "$detail_file") || return 1
    end_time=$(jq -r '.creationTimeToEnd // .timeToEnd // empty' "$detail_file") || return 1
    start_epoch=
    end_epoch=
    [ -n "$start_time" ] && start_epoch=$(mf_oem_timestamp_epoch "$start_time") || start_epoch=
    [ -n "$end_time" ] && end_epoch=$(mf_oem_timestamp_epoch "$end_time") || end_epoch=
    [ -n "$start_epoch" ] && start_epoch_json=$start_epoch
    [ -n "$end_epoch" ] && end_epoch_json=$end_epoch
    if [ "$current_status" = "SCHEDULED" ] \
       && [ -n "${MF_OEM_NOW_EPOCH:-}" ] \
       && [ -n "$start_epoch" ] \
       && [ "$start_epoch" -le "$((MF_OEM_NOW_EPOCH - MF_OEM_SCHEDULED_ACCEPT_SECONDS))" ]
    then
      scheduled_accepted=true
    fi
    case "$current_status" in
      STARTED)
        mf_oem_fetch_blackout_targets "$blackout_id" "$actual_file" || return 1
        mf_oem_target_ids_equal "$expected_file" "$actual_file" && ids_match=true
        ;;
      SCHEDULED)
        if [ "$scheduled_accepted" = true ]
        then
          mf_oem_fetch_blackout_targets "$blackout_id" "$actual_file" || return 1
          mf_oem_target_ids_equal "$expected_file" "$actual_file" && ids_match=true
        else
          printf '[]\n' > "$actual_file" || return 1
        fi
        ;;
      STOPPED|ENDED)
        # Terminal records have no live coverage. They are logical tombstones,
        # even when an operator has not physically deleted them from OEM.
        terminal=true
        printf '[]\n' > "$actual_file" || return 1
        ;;
      *)
        # Avoid treating missing target data on historical/transitional records
        # as a reason to block creation of a replacement.
        printf '[]\n' > "$actual_file" || return 1
        ;;
    esac

    if { [ "$current_status" = "STARTED" ] || [ "$scheduled_accepted" = true ]; } \
       && [ -n "${MF_OEM_NOW_EPOCH:-}" ] \
       && [ -n "${MF_OEM_MINIMUM_END_EPOCH:-}" ] \
       && [ -n "$start_epoch" ] \
       && [ -n "$end_epoch" ]
    then
      [ "$start_epoch" -le "$MF_OEM_NOW_EPOCH" ] \
        && [ "$MF_OEM_NOW_EPOCH" -le "$end_epoch" ] \
        && active_now=true
      [ "$end_epoch" -ge "$MF_OEM_MINIMUM_END_EPOCH" ] \
        && covers_required_end=true
    fi

    mf_oem_new_temp_file entry_file || return 1
    jq -n \
      --argjson terminal "$terminal" \
      --argjson idsMatch "$ids_match" \
      --argjson activeNow "$active_now" \
      --argjson coversRequiredEnd "$covers_required_end" \
      --argjson scheduledAccepted "$scheduled_accepted" \
      --argjson startEpoch "$start_epoch_json" \
      --argjson endEpoch "$end_epoch_json" \
      --slurpfile detail "$detail_file" \
      --slurpfile actual "$actual_file" '
      $detail[0] as $detail |
      {
        id: $detail.id,
        name: $detail.name,
        status: $detail.status,
        owner: ($detail.owner // null),
        startTime: ($detail.creationTimeToStart // $detail.timeToStart // null),
        endTime: ($detail.creationTimeToEnd // $detail.timeToEnd // null),
        startEpoch: $startEpoch,
        endEpoch: $endEpoch,
        terminal: $terminal,
        exactTargetIds: $idsMatch,
        activeNow: $activeNow,
        coversRequiredEnd: $coversRequiredEnd,
        scheduledAccepted: $scheduledAccepted,
        qualifies: ((($detail.status == "STARTED") or $scheduledAccepted) and $idsMatch and $activeNow and $coversRequiredEnd),
        actualTargets: $actual[0]
      }
    ' > "$entry_file" || mf_oem_error "Unable to inspect OEM blackout candidate" || return 1
    mf_oem_new_temp_file append_file || return 1
    jq --slurpfile entry "$entry_file" '. + $entry' "$inspected_file" > "$append_file" \
      || mf_oem_error "Unable to collect OEM blackout candidate inspection" || return 1
    mv -f -- "$append_file" "$inspected_file" || return 1
  done

  jq -n \
    --slurpfile candidates "$candidates_file" \
    --slurpfile inspected "$inspected_file" \
    --slurpfile expected "$expected_file" \
    '
      $inspected[0] as $items |
      {
        candidateCount: ($items | length),
        activeCandidateCount: ([ $items[] | select(.status as $status | [
          "SCHEDULED", "START_PROCESSING", "START_PARTIAL", "STARTED",
          "STOP_PENDING", "STOP_FAILED", "STOP_PARTIAL",
          "EDIT_PENDING", "EDIT_FAILED", "EDIT_PARTIAL", "END_PARTIAL"
        ] | index($status) != null) ] | length),
        terminalCandidateCount: ([ $items[] | select(.terminal) ] | length),
        startedCandidateCount: ([ $items[] | select(.status == "STARTED") ] | length),
        exactStartedCandidateCount: ([ $items[] | select(.status == "STARTED" and .exactTargetIds) ] | length),
        mismatchedStartedCandidateCount: ([ $items[] | select(.status == "STARTED" and (.exactTargetIds | not)) ] | length),
        unverifiableStartedCandidateCount: ([ $items[] | select(
          .status == "STARTED" and (.startEpoch == null or .endEpoch == null)
        ) ] | length),
        qualifyingCandidateCount: ([ $items[] | select(.qualifies) ] | length),
        scheduledAcceptedCandidateCount: ([ $items[] | select(.scheduledAccepted and .qualifies) ] | length),
        transitionalCandidateCount: ([ $items[] | select(.terminal | not) | select(.status != "STARTED") ] | length),
        blockingCandidateCount: ([ $items[] | select(
          ((.terminal | not) and .status != "STARTED" and (.scheduledAccepted | not)) or
          (.status == "STARTED" and
            ((.exactTargetIds | not) or .startEpoch == null or .endEpoch == null)) or
          (.scheduledAccepted and
            ((.exactTargetIds | not) or .startEpoch == null or .endEpoch == null or
             (.activeNow | not) or (.coversRequiredEnd | not)))
        ) ] | length),
        candidates: $candidates[0],
        inspectedCandidates: $items,
        blackoutId: (if ($items | length) == 1 then $items[0].id else null end),
        status: (if ($items | length) == 1 then $items[0].status else null end),
        endTime: (if ($items | length) == 1 then $items[0].endTime else null end),
        terminal: (if ($items | length) == 1 then $items[0].terminal else false end),
        expectedTargets: $expected[0],
        actualTargets: (if ($items | length) == 1 then $items[0].actualTargets else [] end),
        exactTargetIds: (if ($items | length) == 1 then $items[0].exactTargetIds else false end)
      }
    ' > "$output_file" || mf_oem_error "Unable to build the canonical OEM blackout inspection"
}

mf_oem_inventory_managed_blackouts()
{
  local candidates_file="$1"
  local output_file="$2"
  local blackout_id detail_file entry_file append_file

  printf '[]\n' > "$output_file" || return 1
  for blackout_id in $(jq -r '.[].id' "$candidates_file")
  do
    [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
      || mf_oem_error "OEM returned an unsafe blackout ID" || return 1
    mf_oem_new_temp_file detail_file || return 1
    mf_oem_get_blackout "$blackout_id" "$detail_file" || return 1
    mf_oem_validate_blackout_identity "$detail_file" "$blackout_id" \
      || mf_oem_error "OEM blackout identity changed during inventory" || return 1
    mf_oem_new_temp_file entry_file || return 1
    jq '{
      id,
      name,
      status,
      owner: (.owner // null),
      startTime: (.creationTimeToStart // .timeToStart // null),
      endTime: (.creationTimeToEnd // .timeToEnd // null)
    }' "$detail_file" > "$entry_file" || return 1
    mf_oem_new_temp_file append_file || return 1
    jq --slurpfile entry "$entry_file" '. + $entry' "$output_file" > "$append_file" \
      || mf_oem_error "Unable to collect OEM blackout inventory" || return 1
    mv -f -- "$append_file" "$output_file" || return 1
  done
}

mf_oem_print_inventory()
{
  local inventory_file="$1"
  local count blackout_id blackout_name status start_time end_time

  count=$(jq 'length' "$inventory_file") || return 1
  if [ "$count" -eq 0 ]
  then
    printf '%s\n' '         No Migration Factory OEM blackout was found.'
    return 0
  fi
  while IFS=$'\t' read -r blackout_id blackout_name status start_time end_time
  do
    start_time=$(mf_oem_format_utc "$start_time") || return 1
    end_time=$(mf_oem_format_utc "$end_time") || return 1
    printf '         OEM blackout ID       : %s\n' "$blackout_id"
    printf '         OEM blackout name     : %s\n' "$blackout_name"
    printf '         OEM blackout status   : %s\n' "$status"
    printf '         Blackout starts (UTC) : %s\n' "$start_time"
    printf '         Blackout ends (UTC)   : %s\n' "$end_time"
  done < <(jq -r '.[] | [.id, .name, .status, (.startTime // ""), (.endTime // "")] | @tsv' "$inventory_file")
}

mf_oem_print_inspection()
{
  local inspection_file="$1"
  jq -r '
    . as $inspection |
    (if ($inspection.candidateCount > 1 and $inspection.qualifyingCandidateCount > 0)
     then "WARNING: Found \($inspection.candidateCount) managed blackout records; each ID was verified independently."
     else empty end),
    (if $inspection.candidateCount == 0
     then "Blackout situation    : no managed blackout record exists."
     else ($inspection.inspectedCandidates[] |
       "Blackout \(.id)         : \(.status); scheduled grace accepted=\(.scheduledAccepted), exact targets=\(.exactTargetIds), active now=\(.activeNow), covers required end=\(.coversRequiredEnd), start=\(.startTime // "unknown"), end=\(.endTime // "unknown").")
     end),
    "Qualifying blackouts : \($inspection.qualifyingCandidateCount)"
  ' "$inspection_file" | sed 's/^/         /' || mf_oem_error "Unable to format OEM blackout status"
}

mf_oem_format_utc()
{
  local end_time="$1"

  [ "$end_time" != "" ] || { printf '%s\n' 'not returned by OEM'; return 0; }
  date -u -d "$end_time" '+%Y-%m-%dT%H:%MZ' 2>/dev/null \
    || printf '%s\n' "$end_time"
}

mf_oem_timestamp_epoch()
{
  local timestamp="$1"
  [ -n "$timestamp" ] || return 1
  date -u -d "$timestamp" '+%s' 2>/dev/null
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
  url="${MF_OEM_API_BASE_URL}/em/api/targets?limit=100&typeName=oracle_database&typeName=oracle_pdb&typeName=rac_database&nameMatches=${encoded}"
  mf_oem_fetch_target_pages "$url" "/em/api/targets" \
    "oracle_database,oracle_pdb,rac_database" "$output_file"
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
           select(($target.name | ascii_downcase) | startswith($prefix)) |
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
    ' > "$output_file" || mf_oem_error "Unable to filter OEM targets by CDB name and MF clusters"
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
      (.typeName == "oracle_database" or .typeName == "rac_database" or .typeName == "oracle_pdb") and
      (.member | type == "object") and
      (.member.clusterId | type == "string" and length > 0) and
      (.member.realName | type == "string" and length > 0)
    )) and
    ($resolved | group_by(.id) | all((map([
      .name, .typeName, .member.clusterId, .member.realName
    ]) | unique | length) == 1)) and
    ($resolved | all(. as $target |
      (($target.name | ascii_downcase) |
        startswith(($target.member.realName | ascii_downcase) + "_" + $cdbName)) and
      ([ $required.clusters[] |
         select(.clusterId == $target.member.clusterId and
                 (.realName | ascii_downcase) == ($target.member.realName | ascii_downcase))
       ] | length) == 1
    )) and
    # Every cluster must expose at least one single-instance or RAC database
    # target. PDB targets are optional, but every discovered PDB remains in the
    # authoritative ID set.
    ($required.clusters | all(. as $cluster |
      ([ $resolved[] |
          select(.member.clusterId == $cluster.clusterId and
                 (.typeName == "oracle_database" or .typeName == "rac_database")) |
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
  local create_name="${5:-}"
  local duration_parts duration_hours duration_minutes duration_seconds renewal_grace

  duration_parts=$(mf_oem_parse_duration "$duration") || return 1
  duration_hours=${duration_parts%%|*}
  duration_minutes=${duration_parts#*|}
  [ -n "$create_name" ] || create_name=$(mf_oem_blackout_name) || return 1
  jq -n \
    --arg name "$create_name" \
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

mf_oem_is_explicit_name_conflict()
{
  local http_status="$1"
  local response_file="$2"

  case "$http_status" in
    400|409) : ;;
    *) return 1 ;;
  esac
  jq -e '
    [
      .message?, .errorMessage?, .detail?,
      (.errors[]?.message?)
    ] |
    map(select(type == "string")) |
    join(" ") |
    test("(already[[:space:]]+exists|duplicate[[:space:]]+name|name[^.]*unique)"; "i")
  ' "$response_file" >/dev/null 2>&1
}

mf_oem_set_required_window()
{
  local duration="$1"
  local fixed_end="${2:-}"
  local duration_parts duration_hours duration_minutes duration_seconds renewal_grace

  duration_parts=$(mf_oem_parse_duration "$duration") || return 1
  duration_hours=${duration_parts%%|*}
  duration_minutes=${duration_parts#*|}
  duration_seconds=$((duration_hours * 3600 + duration_minutes * 60))
  MF_OEM_EFFECTIVE_DURATION=$duration
  MF_OEM_NOW_EPOCH=$(date -u '+%s') || return 1
  if [ -n "$fixed_end" ]
  then
    MF_OEM_REQUIRED_END_EPOCH=$(mf_oem_timestamp_epoch "$fixed_end") \
      || mf_oem_error "Unable to parse the fixed OEM blackout end time" || return 1
    if [ "$MF_OEM_REQUIRED_END_EPOCH" -gt "$MF_OEM_NOW_EPOCH" ]
    then
      MF_OEM_MINIMUM_END_EPOCH=$MF_OEM_REQUIRED_END_EPOCH
      return 0
    fi
    MF_OEM_EFFECTIVE_DURATION=02:00
    duration_seconds=7200
  fi
  MF_OEM_REQUIRED_END_EPOCH=$((MF_OEM_NOW_EPOCH + duration_seconds))
  renewal_grace=$MF_OEM_RENEWAL_GRACE_SECONDS
  if [ "$renewal_grace" -ge "$duration_seconds" ]
  then
    renewal_grace=$((duration_seconds / 2))
  fi
  MF_OEM_MINIMUM_END_EPOCH=$((MF_OEM_REQUIRED_END_EPOCH - renewal_grace))
}

mf_oem_response_covers_required_window()
{
  local response_file="$1"
  local start_time end_time start_epoch end_epoch verification_now

  start_time=$(jq -r '.creationTimeToStart // .timeToStart // empty' "$response_file") || return 1
  end_time=$(jq -r '.creationTimeToEnd // .timeToEnd // empty' "$response_file") || return 1
  start_epoch=$(mf_oem_timestamp_epoch "$start_time") || return 1
  end_epoch=$(mf_oem_timestamp_epoch "$end_time") || return 1
  verification_now=$(date -u '+%s') || return 1
  [ "$start_epoch" -le "$verification_now" ] \
    && [ "$verification_now" -le "$end_epoch" ] \
    && [ "$end_epoch" -ge "$MF_OEM_MINIMUM_END_EPOCH" ]
}

mf_oem_start_status_result()
{
  case "$1" in
    STARTED) return 0 ;;
    SCHEDULED|START_PROCESSING) return 2 ;;
    START_PARTIAL|START_FAILED) mf_oem_error "OEM blackout returned terminal start status $1" ;;
    *) mf_oem_error "OEM blackout returned unexpected start status $1" ;;
  esac
}

mf_oem_wait_for_start_accepted()
{
  local blackout_id="$1"
  local response_file="$2"
  local attempt=1 status rc attempt_limit scheduled_attempt_limit

  attempt_limit=$MF_OEM_VERIFY_ATTEMPTS
  scheduled_attempt_limit=$MF_OEM_VERIFY_ATTEMPTS
  if [ "$MF_OEM_VERIFY_INTERVAL" -gt 0 ]
  then
    scheduled_attempt_limit=$((
      (MF_OEM_SCHEDULED_ACCEPT_SECONDS + MF_OEM_VERIFY_INTERVAL - 1) /
      MF_OEM_VERIFY_INTERVAL + 1
    ))
    [ "$scheduled_attempt_limit" -gt "$attempt_limit" ] \
      && attempt_limit=$scheduled_attempt_limit
  fi

  while [ "$attempt" -le "$attempt_limit" ]
  do
    status=$(jq -r '.status' "$response_file") || return 1
    mf_oem_start_status_result "$status"
    rc=$?
    [ "$rc" -eq 0 ] && return 0
    [ "$rc" -eq 2 ] || return 1
    if [ "$status" = "SCHEDULED" ] \
       && [ "$MF_OEM_VERIFY_INTERVAL" -gt 0 ] \
       && [ "$attempt" -ge "$scheduled_attempt_limit" ]
    then
      mf_oem_warning "OEM still reports SCHEDULED after at least ${MF_OEM_SCHEDULED_ACCEPT_SECONDS} seconds; accepting it only after identity, exact-target, and time-window verification."
      return 0
    fi
    [ "$attempt" -lt "$attempt_limit" ] || break
    sleep "$MF_OEM_VERIFY_INTERVAL"
    mf_oem_get_blackout "$blackout_id" "$response_file" || return 1
    attempt=$((attempt + 1))
  done
  mf_oem_error "OEM blackout did not reach STARTED or remain verifiably SCHEDULED for the configured grace window"
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

mf_oem_print_start_result()
{
  local response_file="$1"
  local target_count="$2"
  local status end_time

  status=$(jq -r '.status' "$response_file") || return 1
  end_time=$(jq -r '.creationTimeToEnd // .timeToEnd // empty' "$response_file") || return 1
  end_time=$(mf_oem_format_utc "$end_time") || return 1
  case "$status" in
    STARTED)
      printf '         Blackout has been STARTED; all %s discovered targets are covered.\n' "$target_count"
      ;;
    SCHEDULED)
      printf 'WARNING: OEM still reports SCHEDULED after the configured grace; all %s discovered targets and the required time window were verified.\n' "$target_count"
      ;;
    *)
      mf_oem_error "START result is neither STARTED nor an accepted SCHEDULED record"
      return 1
      ;;
  esac
  printf '         Blackout will end at (UTC): %s\n' "$end_time"
}

mf_oem_print_start_candidates()
{
  local inspection_file="$1"

  jq -r '
    if .candidateCount > 1 then
      "WARNING: Found \(.candidateCount) managed OEM blackout records."
    else empty end,
    (.inspectedCandidates[] |
      select(.qualifies) |
      "         Using blackout \(.id) in status \(.status) with exact target and time coverage; it ends at \(.endTime // "not returned by OEM")."),
    (.inspectedCandidates[] |
      select((.status == "STOPPED" or .status == "ENDED") | not) |
      select(.qualifies | not) |
      "WARNING: Existing blackout \(.id) is \(.status); exact targets=\(.exactTargetIds), active now=\(.activeNow), covers required end=\(.coversRequiredEnd)." )
  ' "$inspection_file" || mf_oem_error "Unable to report existing OEM blackouts"
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

mf_oem_prepare_start_inspection()
{
  local repository_migration_id="$1"
  local cdb_name="$2"
  local target_container_service="$3"
  local topology_file="$4"
  local targets_file="$5"
  local candidates_file="$6"
  local inspection_file="$7"
  local attempt=1

  while [ "$attempt" -le "$MF_OEM_VERIFY_ATTEMPTS" ]
  do
    # A same-name record may disappear between the collection request and its
    # detail request. Retry the complete snapshot; never infer absence from a
    # failed or partial inspection.
    MF_OEM_EXACT_CANDIDATE_COUNT=
    if mf_oem_prepare_inspection "$repository_migration_id" "$cdb_name" \
         "$target_container_service" "$topology_file" "$targets_file" \
         "$candidates_file" "$inspection_file"
    then
      return 0
    fi
    [ "$attempt" -lt "$MF_OEM_VERIFY_ATTEMPTS" ] || break
    mf_oem_warning 'The OEM blackout snapshot changed or was unavailable; retrying the full pre-create inspection.'
    sleep "$MF_OEM_VERIFY_INTERVAL"
    attempt=$((attempt + 1))
  done
  mf_oem_error 'Unable to obtain a complete OEM blackout snapshot; no blackout was created.'
}

mf_oem_reconcile_started_blackouts()
{
  local expected_file="$1"
  local candidates_file suffixed_file inspection_file attempt=1

  mf_oem_new_temp_file candidates_file || return 1
  mf_oem_new_temp_file suffixed_file || return 1
  mf_oem_new_temp_file inspection_file || return 1
  while [ "$attempt" -le "$MF_OEM_VERIFY_ATTEMPTS" ]
  do
    if mf_oem_find_exact_blackouts "$candidates_file" "$suffixed_file"
    then
      MF_OEM_EXACT_CANDIDATE_COUNT=$(jq 'length' "$candidates_file") || return 1
      MF_OEM_NOW_EPOCH=$(date -u '+%s') || return 1
      if mf_oem_inspect_exact_blackouts "$candidates_file" "$expected_file" "$inspection_file" \
          && jq -e '.qualifyingCandidateCount > 0 and .blockingCandidateCount == 0' \
               "$inspection_file" >/dev/null
      then
        mf_oem_warning 'The create result was uncertain, but fully qualifying blackout coverage is now present.'
        mf_oem_print_start_candidates "$inspection_file" || return 1
        mf_oem_stop_inadequate_started_blackouts "$inspection_file" || :
        return 0
      fi
    fi
    [ "$attempt" -lt "$MF_OEM_VERIFY_ATTEMPTS" ] || break
    sleep "$MF_OEM_VERIFY_INTERVAL"
    attempt=$((attempt + 1))
  done
  mf_oem_error "Unable to prove that a qualifying STARTED blackout exists after the create attempt"
}

mf_oem_reinspect_managed_family()
{
  local expected_file="$1"
  local inspection_file="$2"
  local candidates_file ignored_file

  mf_oem_new_temp_file candidates_file || return 1
  mf_oem_new_temp_file ignored_file || return 1
  mf_oem_find_exact_blackouts "$candidates_file" "$ignored_file" || return 1
  MF_OEM_EXACT_CANDIDATE_COUNT=$(jq 'length' "$candidates_file") || return 1
  MF_OEM_NOW_EPOCH=$(date -u '+%s') || return 1
  mf_oem_inspect_exact_blackouts "$candidates_file" "$expected_file" "$inspection_file"
}

mf_oem_create_and_verify_blackout()
{
  local migration_id="$1"
  local targets_file="$2"
  local duration="$3"
  local create_name="$4"
  local payload_file="$5"
  local response_file="$6"
  local blackout_id

  mf_oem_build_payload "$migration_id" "$targets_file" "$duration" "$payload_file" "$create_name" || return 1
  MF_OEM_START_MUTATION_ATTEMPTED=Y
  MF_OEM_MUTATION_ATTEMPTED=Y
  if ! mf_oem_http POST "${MF_OEM_API_BASE_URL}/em/api/blackouts" "$response_file" "$payload_file"
  then
    return 1
  fi
  if [ "$MF_OEM_HTTP_STATUS" != "201" ]
  then
    mf_oem_is_explicit_name_conflict "$MF_OEM_HTTP_STATUS" "$response_file" && return 5
    mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 201 "Blackout creation" || return 1
  fi
  mf_oem_validate_blackout_response "$response_file" || return 1
  jq -e --arg name "$create_name" '.name == $name' "$response_file" >/dev/null \
    || mf_oem_error "OEM create response returned an unexpected blackout name" || return 1
  blackout_id=$(jq -r '.id' "$response_file") || return 1
  [[ "$blackout_id" =~ ^[A-Za-z0-9._-]+$ ]] \
    || mf_oem_error "OEM returned an unsafe blackout ID" || return 1
  mf_oem_wait_for_start_accepted "$blackout_id" "$response_file" || return 1
  mf_oem_validate_blackout_identity "$response_file" "$blackout_id" \
    || mf_oem_error "Created OEM blackout identity could not be verified" || return 1
  mf_oem_verify_blackout_targets "$blackout_id" "$targets_file" || return 1
  mf_oem_response_covers_required_window "$response_file" \
    || mf_oem_error "Created OEM blackout does not cover the required time window" || return 1
}

mf_oem_start_blackout()
{
  local migration_id="$1"
  local repository_migration_id="$2"
  local cdb_name="$3"
  local target_container_service="$4"
  local duration="$5"
  local fixed_end="${6:-}"
  local topology_file targets_file candidates_file inspection_file payload_file response_file
  local conflict_inspection_file candidate_count qualifying_count blocking_count create_name create_rc

  umask 077
  MF_OEM_BLACKOUT_NAME=MF_2_${cdb_name}_Migration
  MF_OEM_TMP_FILES=()
  MF_OEM_START_MUTATION_ATTEMPTED=N
  MF_OEM_MUTATION_ATTEMPTED=N
  MF_OEM_EXACT_CANDIDATE_COUNT=
  mf_oem_validate_config || return 1
  mf_oem_set_required_window "$duration" "$fixed_end" || return 1
  duration=$MF_OEM_EFFECTIVE_DURATION
  mf_oem_new_temp_file topology_file || return 1
  mf_oem_new_temp_file targets_file || return 1
  mf_oem_new_temp_file candidates_file || return 1
  mf_oem_new_temp_file inspection_file || return 1
  if ! mf_oem_prepare_start_inspection "$repository_migration_id" "$cdb_name" \
       "$target_container_service" "$topology_file" "$targets_file" \
       "$candidates_file" "$inspection_file"
  then
    # Once an exact-name candidate is known to exist, inability to verify its
    # state or targets is a semantic conflict. Do not create or use emctl.
    [ "${MF_OEM_EXACT_CANDIDATE_COUNT:-0}" -gt 0 ] && return 3
    return 1
  fi
  candidate_count=$(jq '.candidateCount' "$inspection_file") || return 1
  qualifying_count=$(jq '.qualifyingCandidateCount // 0' "$inspection_file") || return 1
  blocking_count=$(jq '.blockingCandidateCount // 0' "$inspection_file") || return 1
  if [ "$blocking_count" -gt 0 ]
  then
    mf_oem_print_start_candidates "$inspection_file" || return 1
    mf_oem_error "A managed blackout is transitional, failed, partial, unknown, target-mismatched, or otherwise unverifiable; START will not create a competing blackout"
    return 3
  fi
  if [ "$qualifying_count" -gt 0 ]
  then
    mf_oem_print_start_candidates "$inspection_file" || return 1
    # Required coverage already exists. Best-effort cleanup of shorter or
    # otherwise time-inadequate STARTED duplicates cannot reduce that coverage.
    mf_oem_stop_inadequate_started_blackouts "$inspection_file" || :
    return 0
  fi
  if [ "$candidate_count" -gt 0 ]
  then
    mf_oem_warning "No managed blackout covers the required targets and time window; START will create a new one."
    mf_oem_print_start_candidates "$inspection_file" || return 1
  fi

  mf_oem_new_temp_file payload_file || return 1
  mf_oem_new_temp_file response_file || return 1
  create_name=$(mf_oem_blackout_name) || return 1
  mf_oem_create_and_verify_blackout "$migration_id" "$targets_file" "$duration" \
    "$create_name" "$payload_file" "$response_file"
  create_rc=$?
  if [ "$create_rc" -eq 5 ]
  then
    mf_oem_warning "OEM rejected the canonical name as already existing; rechecking the managed family before creating another record."
    mf_oem_new_temp_file conflict_inspection_file || return 1
    mf_oem_reinspect_managed_family "$targets_file" "$conflict_inspection_file" || return 1
    blocking_count=$(jq '.blockingCandidateCount // 0' "$conflict_inspection_file") || return 1
    qualifying_count=$(jq '.qualifyingCandidateCount // 0' "$conflict_inspection_file") || return 1
    if [ "$blocking_count" -gt 0 ]
    then
      mf_oem_print_start_candidates "$conflict_inspection_file" || return 1
      mf_oem_error "The name conflict exposed a blocking managed blackout; no timestamped blackout was created"
      return 3
    fi
    if [ "$qualifying_count" -gt 0 ]
    then
      mf_oem_print_start_candidates "$conflict_inspection_file" || return 1
      mf_oem_stop_inadequate_started_blackouts "$conflict_inspection_file" || :
      return 0
    fi
    inspection_file=$conflict_inspection_file
    mf_oem_warning "The canonical name is unavailable and no qualifying blackout exists; using a timestamped managed name."
    create_name=$(mf_oem_timestamped_blackout_name) || return 1
    mf_oem_create_and_verify_blackout "$migration_id" "$targets_file" "$duration" \
      "$create_name" "$payload_file" "$response_file"
    create_rc=$?
  fi
  if [ "$create_rc" -ne 0 ]
  then
    mf_oem_warning 'The create result was not verified; reconciling the managed blackout family.'
    mf_oem_reconcile_started_blackouts "$targets_file"
    return $?
  fi

  mf_oem_print_start_result "$response_file" "$(jq 'length' "$targets_file")" || return 1
  mf_oem_stop_inadequate_started_blackouts "$inspection_file" || :
}

mf_oem_reconcile_stop_result()
{
  local blackout_id="$1"
  local response_file attempt=1 status

  mf_oem_new_temp_file response_file || return 1
  while [ "$attempt" -le "$MF_OEM_VERIFY_ATTEMPTS" ]
  do
    if mf_oem_get_blackout "$blackout_id" "$response_file"
    then
      if ! mf_oem_validate_blackout_identity "$response_file" "$blackout_id"
      then
        mf_oem_error "OEM blackout identity changed while reconciling STOP for $blackout_id"
        return 1
      fi
      status=$(jq -r '.status' "$response_file") || return 1
      case "$status" in
        STOP_PENDING|STOPPED|ENDED)
          mf_oem_warning "The STOP response for $blackout_id was uncertain, but OEM now reports $status."
          return 0
          ;;
      esac
    elif [ "${MF_OEM_HTTP_STATUS:-}" = "404" ]
    then
      mf_oem_warning "The STOP response for $blackout_id was uncertain, but that ID is now absent."
      return 0
    fi
    [ "$attempt" -lt "$MF_OEM_VERIFY_ATTEMPTS" ] || break
    sleep "$MF_OEM_VERIFY_INTERVAL"
    attempt=$((attempt + 1))
  done
  mf_oem_error "Unable to prove that blackout $blackout_id reached STOP_PENDING, STOPPED, or ENDED"
}

mf_oem_stop_verified_blackout()
{
  local blackout_id="$1"
  local response_file stop_file status

  mf_oem_new_temp_file response_file || return 1
  if ! mf_oem_get_blackout "$blackout_id" "$response_file"
  then
    if [ "${MF_OEM_HTTP_STATUS:-}" = "404" ]
    then
      mf_oem_warning "Blackout $blackout_id disappeared before STOP and is already absent."
      return 0
    fi
    return 1
  fi
  if ! mf_oem_validate_blackout_identity "$response_file" "$blackout_id"
  then
    mf_oem_error "OEM blackout identity changed before STOP for $blackout_id"
    return 1
  fi
  status=$(jq -r '.status' "$response_file") || return 1
  case "$status" in
    STOP_PENDING|STOPPED|ENDED)
      return 0
      ;;
    STARTED) : ;;
    *)
      mf_oem_error "OEM blackout $blackout_id changed to blocking status $status before STOP"
      return 1
      ;;
  esac

  mf_oem_new_temp_file stop_file || return 1
  MF_OEM_STOP_MUTATION_ATTEMPTED=Y
  MF_OEM_MUTATION_ATTEMPTED=Y
  if mf_oem_http POST "${MF_OEM_API_BASE_URL}/em/api/blackouts/${blackout_id}/actions/stop" "$stop_file" \
     && mf_oem_expect_http "$MF_OEM_HTTP_STATUS" 204 "Blackout stop"
  then
    printf '         Blackout %s has been requested to stop; status is now STOP_PENDING.\n' "$blackout_id"
    return 0
  fi

  mf_oem_warning "The stop response for $blackout_id was unavailable or unexpected; reconciling that ID."
  mf_oem_reconcile_stop_result "$blackout_id"
}

mf_oem_stop_inadequate_started_blackouts()
{
  local inspection_file="$1"
  local blackout_id failures=0

  for blackout_id in $(jq -r '
    .inspectedCandidates[] |
    select(.status == "STARTED" and (.qualifies | not)) |
    .id
  ' "$inspection_file")
  do
    if ! mf_oem_stop_verified_blackout "$blackout_id"
    then
      failures=$((failures + 1))
      mf_oem_warning "Replacement coverage is active, but obsolete blackout $blackout_id could not be stopped."
    fi
  done
  [ "$failures" -eq 0 ]
}

mf_oem_status_blackout()
{
  local migration_id="$1"
  local repository_migration_id="$2"
  local cdb_name="$3"
  local target_container_service="$4"
  local candidates_file ignored_file inventory_file

  : "$migration_id" "$repository_migration_id" "$target_container_service"
  umask 077
  MF_OEM_BLACKOUT_NAME=MF_2_${cdb_name}_Migration
  MF_OEM_TMP_FILES=()
  mf_oem_validate_config || return 1
  mf_oem_new_temp_file candidates_file || return 1
  mf_oem_new_temp_file ignored_file || return 1
  mf_oem_new_temp_file inventory_file || return 1
  mf_oem_find_exact_blackouts "$candidates_file" "$ignored_file" || return 1
  mf_oem_inventory_managed_blackouts "$candidates_file" "$inventory_file" || return 1
  mf_oem_print_inventory "$inventory_file"
}

mf_oem_is_blackout_on()
{
  local migration_id="$1"
  local repository_migration_id="$2"
  local cdb_name="$3"
  local target_container_service="$4"
  local duration="$5"
  local fixed_end="${6:-}"
  local topology_file targets_file candidates_file inspection_file

  : "$migration_id"
  umask 077
  MF_OEM_BLACKOUT_NAME=MF_2_${cdb_name}_Migration
  MF_OEM_TMP_FILES=()
  mf_oem_validate_config || return 1
  mf_oem_set_required_window "$duration" "$fixed_end" || return 1
  mf_oem_new_temp_file topology_file || return 1
  mf_oem_new_temp_file targets_file || return 1
  mf_oem_new_temp_file candidates_file || return 1
  mf_oem_new_temp_file inspection_file || return 1
  mf_oem_prepare_inspection "$repository_migration_id" "$cdb_name" \
    "$target_container_service" "$topology_file" "$targets_file" \
    "$candidates_file" "$inspection_file" || return 1
  mf_oem_print_inspection "$inspection_file" || return 1
  if jq -e '.blockingCandidateCount > 0' "$inspection_file" >/dev/null
  then
    mf_oem_error "A managed blackout is transitional, failed, partial, unknown, target-mismatched, or otherwise unverifiable"
    return 1
  fi
  if jq -e '.qualifyingCandidateCount > 0' "$inspection_file" >/dev/null
  then
    printf '         Blackout is ON; required targets and time window are covered.\n'
    return 0
  fi
  printf '         Blackout is not ON for the required targets and time window.\n'
  return 3
}

mf_oem_stop_blackout()
{
  local migration_id="$1"
  local repository_migration_id="$2"
  local cdb_name="$3"
  local target_container_service="$4"
  local candidates_file ignored_file
  local blackout_id candidate_count stop_failures=0

  : "$migration_id" "$repository_migration_id" "$target_container_service"
  umask 077
  MF_OEM_BLACKOUT_NAME=MF_2_${cdb_name}_Migration
  MF_OEM_TMP_FILES=()
  MF_OEM_STOP_MUTATION_ATTEMPTED=N
  MF_OEM_MUTATION_ATTEMPTED=N
  MF_OEM_EXACT_CANDIDATE_COUNT=
  mf_oem_validate_config || return 1
  mf_oem_new_temp_file candidates_file || return 1
  mf_oem_new_temp_file ignored_file || return 1
  mf_oem_find_exact_blackouts "$candidates_file" "$ignored_file" || return 1
  candidate_count=$(jq 'length' "$candidates_file") || return 1
  if [ "$candidate_count" -eq 0 ]
  then
    printf '%s\n' '         No managed blackout requires a stop.'
    return 0
  fi
  for blackout_id in $(jq -r '.[].id' "$candidates_file")
  do
    if ! mf_oem_stop_verified_blackout "$blackout_id"
    then
      stop_failures=$((stop_failures + 1))
    fi
  done
  if [ "$stop_failures" -gt 0 ]
  then
    mf_oem_error "STOP could not verify a complete result for $stop_failures managed blackout(s)"
    return 1
  fi
  printf '%s\n' '         STOP processed every managed blackout record.'

}
