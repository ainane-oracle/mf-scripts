#!/usr/bin/env bash

set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../bin" && pwd)
MAIN_SCRIPT="$SCRIPT_DIR/mfEmBlackout.sh"
RELEASE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
UNSTABLE_MAIN_SCRIPT="$RELEASE_ROOT/unstable_bin/mfEmBlackout.sh"
. "$SCRIPT_DIR/mfEmBlackout_oemRest.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf -- "$TEST_TMP"' EXIT
PASS=0
FAIL=0

pass()
{
  PASS=$((PASS + 1))
  printf 'ok - %s\n' "$1"
}

fail()
{
  FAIL=$((FAIL + 1))
  printf 'not ok - %s\n' "$1" >&2
}

expect_success()
{
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then pass "$name"; else fail "$name"; fi
}

expect_failure()
{
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then fail "$name"; else pass "$name"; fi
}

write_json()
{
  local file="$1"
  local json="$2"
  printf '%s\n' "$json" > "$file"
}

validate_fixture()
{
  local required_json="$1"
  local targets_json="$2"
  local prefix="$3"
  write_json "$TEST_TMP/${prefix}.required.json" "$required_json"
  write_json "$TEST_TMP/${prefix}.targets.json" "$targets_json"
  mf_oem_validate_resolved_targets \
    "$TEST_TMP/${prefix}.required.json" \
    "$TEST_TMP/${prefix}.targets.json" \
    "$TEST_TMP/${prefix}.normalized.json"
}

expect_success "one CDB and multiple PDBs" validate_fixture \
  '["CDBA"]' \
  '[
    {"id":"cdb-a","name":"CDBA","typeName":"oracle_database","requiredCdb":"CDBA"},
    {"id":"pdb-a1","name":"PDB1_CDBA","typeName":"oracle_pdb","requiredCdb":"CDBA"},
    {"id":"pdb-a2","name":"PDB2_CDBA","typeName":"oracle_pdb","requiredCdb":"CDBA"}
  ]' success_one

expect_success "primary plus standby discovery" validate_fixture \
  '["CDBA_PRIM","CDBA_STBY"]' \
  '[
    {"id":"cdb-p","name":"CDBA_PRIM","typeName":"oracle_database","requiredCdb":"CDBA_PRIM"},
    {"id":"pdb-p","name":"APP_CDBA_PRIM","typeName":"oracle_pdb","requiredCdb":"CDBA_PRIM"},
    {"id":"cdb-s","name":"CDBA_STBY","typeName":"oracle_database","requiredCdb":"CDBA_STBY"},
    {"id":"pdb-s","name":"APP_CDBA_STBY","typeName":"oracle_pdb","requiredCdb":"CDBA_STBY"}
  ]' success_peer

expect_failure "zero targets fails closed" validate_fixture '["CDBA"]' '[]' zero

expect_failure "missing standby target fails closed" validate_fixture \
  '["CDBA_PRIM","CDBA_STBY"]' \
  '[{"id":"cdb-p","name":"CDBA_PRIM","typeName":"oracle_database","requiredCdb":"CDBA_PRIM"}]' missing_peer

expect_success "identical duplicate target IDs are deduplicated" validate_fixture \
  '["CDBA"]' \
  '[
    {"id":"cdb-a","name":"CDBA","typeName":"oracle_database","requiredCdb":"CDBA"},
    {"id":"cdb-a","name":"CDBA","typeName":"oracle_database","requiredCdb":"CDBA"}
  ]' duplicate_identical

expect_failure "conflicting duplicate target IDs fail closed" validate_fixture \
  '["CDBA"]' \
  '[
    {"id":"same-id","name":"CDBA","typeName":"oracle_database","requiredCdb":"CDBA"},
    {"id":"same-id","name":"PDB_CDBA","typeName":"oracle_pdb","requiredCdb":"CDBA"}
  ]' duplicate_conflict

expect_failure "unexpected target type fails closed" validate_fixture \
  '["CDBA"]' \
  '[{"id":"host-a","name":"CDBA","typeName":"host","requiredCdb":"CDBA"}]' unexpected_type

write_json "$TEST_TMP/malformed.json" '{not-json'
expect_failure "malformed JSON response fails closed" mf_oem_validate_collection_page "$TEST_TMP/malformed.json"

for code in 401 403 404 500 503
do
  expect_failure "HTTP $code is rejected" mf_oem_expect_http "$code" 200 "test request"
done
expect_success "HTTP 200 is accepted for GET" mf_oem_expect_http 200 200 "test request"
expect_success "HTTP 201 is accepted for POST" mf_oem_expect_http 201 201 "test request"

expect_success "STARTED is success" mf_oem_status_result STARTED
expect_failure "START_PARTIAL is failure" mf_oem_status_result START_PARTIAL
expect_failure "START_FAILED is failure" mf_oem_status_result START_FAILED

write_json "$TEST_TMP/payload-targets.json" '[
  {"id":"cdb-a","name":"CDBA","typeName":"oracle_database","requiredCdb":"CDBA"},
  {"id":"pdb-a","name":"PDB_CDBA","typeName":"oracle_pdb","requiredCdb":"CDBA"}
]'
MF_OEM_BLACKOUT_REASON_ID=29
MF_OEM_BLACKOUT_ALLOW_JOBS=true
if mf_oem_build_payload 'MIG-42' "$TEST_TMP/payload-targets.json" '2026-08-20T23:59Z' "$TEST_TMP/payload.json" \
   && jq -e '
        .name == "MF_MIG-42" and
        .type == "PATCHING" and
        .reasonId == 29 and
        .isAllowJobs == true and
        .isFullBlackoutOnHost == false and
        .timeToEnd == "2026-08-20T23:59Z" and
        (has("durationHours") | not) and
        (has("durationMinutes") | not) and
        .targets == [{"id":"cdb-a"},{"id":"pdb-a"}]
      ' "$TEST_TMP/payload.json" >/dev/null
then
  pass "blackout payload is safely built from target IDs"
else
  fail "blackout payload is safely built from target IDs"
fi

if mf_oem_build_payload 'MIG-42' "$TEST_TMP/payload-targets.json" '' "$TEST_TMP/fallback-payload.json" \
   && jq -e '
        .durationHours == 12 and
        .durationMinutes == 0 and
        (has("timeToEnd") | not)
      ' "$TEST_TMP/fallback-payload.json" >/dev/null
then
  pass "missing go-live uses a fixed 12-hour duration"
else
  fail "missing go-live uses a fixed 12-hour duration"
fi

expect_success "valid UTC timeToEnd is accepted" mf_oem_validate_time_to_end '2026-08-20T23:59Z'
expect_failure "timeToEnd without Z is rejected" mf_oem_validate_time_to_end '2026-08-20T23:59'
expect_failure "timeToEnd with an invalid hour is rejected" mf_oem_validate_time_to_end '2026-08-20T24:00Z'

if grep -F "mf_mig_parameters.get_id('MLS_ID_GOLIVE_START'" "$MAIN_SCRIPT" >/dev/null \
   && grep -F "from_tz(cast(po.target_date as timestamp), sessiontimezone)" "$MAIN_SCRIPT" >/dev/null \
   && grep -F "interval '12' hour" "$MAIN_SCRIPT" >/dev/null
then
  pass "timeToEnd is derived from current planned go-live plus 12 hours in UTC"
else
  fail "timeToEnd is derived from current planned go-live plus 12 hours in UTC"
fi

if grep -E '^[[:space:]]*ACTION=STATUS$' "$MAIN_SCRIPT" >/dev/null \
   && grep -E '^[[:space:]]*ACTION=STATUS$' "$UNSTABLE_MAIN_SCRIPT" >/dev/null
then
  pass "STATUS is the default action in bin and unstable_bin"
else
  fail "STATUS is the default action in bin and unstable_bin"
fi

write_json "$TEST_TMP/state-required.json" '["CDBA"]'
write_json "$TEST_TMP/state-response.json" '{"id":"BLACKOUT-1","name":"MF_MIG-42","status":"STARTED"}'
MF_DATA="$TEST_TMP/data"
MF_OEM_API_BASE_URL=https://oms.example:7803
MF_OEM_BLACKOUT_STATE_DIR="$MF_DATA/em_blackouts"
unset MF_OEM_BLACKOUT_STATE_FILE
if mf_oem_prepare_state_file 'MIG-42' \
   && mf_oem_write_state 'MIG-42' "$TEST_TMP/state-required.json" \
        "$TEST_TMP/payload-targets.json" "$TEST_TMP/state-response.json" true \
   && [ "$(stat -c '%a' "$MF_OEM_BLACKOUT_STATE_FILE")" = "600" ] \
   && jq -e '.blackoutId == "BLACKOUT-1" and .targetCoverageVerified == true and (.targets | length) == 2' \
        "$MF_OEM_BLACKOUT_STATE_FILE" >/dev/null
then
  pass "protected state persists the blackout ID and exact target snapshot"
else
  fail "protected state persists the blackout ID and exact target snapshot"
fi

MF_OEM_API_BASE_URL=http://invalid.example
MF_OEM_API_USERNAME=test-user
MF_OEM_API_PASSWORD='do-not-print-this-secret'
config_output=$(mf_oem_validate_config 2>&1 || :)
if printf '%s' "$config_output" | grep -F 'do-not-print-this-secret' >/dev/null
then
  fail "configuration errors redact secrets"
else
  pass "configuration errors redact secrets"
fi

start_block=$(awk '
  /if \[ "\$ACTION" = "START" \]/{capture=1}
  capture && /^  else$/{exit}
  capture{print}
' "$MAIN_SCRIPT")
if printf '%s\n' "$start_block" | grep -E 'exec_on_target|emctl start blackout|config agent listtargets|ssh ' >/dev/null
then
  fail "START contains no SSH or emctl execution"
else
  pass "START contains no SSH or emctl execution"
fi

apex_sources=(
  "$RELEASE_ROOT/repository/plsql/mf_apex_utils.pkb"
  "$RELEASE_ROOT/repository/fullDDL/060_package_mf_apex_utils.pks"
  "$RELEASE_ROOT/repository/fullDDL/061_package_body_mf_apex_utils.pkb"
)
for apex_source in "${apex_sources[@]}"
do
  if grep -F "rec.code || ' -A START ,Start Blackout: go-live plus 12 hours; 12-hour fallback if not planned'" "$apex_source" >/dev/null \
     && grep -F "Start (GL+12h / 12h fallback)</A>" "$apex_source" >/dev/null \
     && grep -F "rec.code || ' -A STOP ,Stop Blackout'" "$apex_source" >/dev/null
  then
    pass "APEX blackout links are valid and describe the START end time ($(basename "$apex_source"))"
  else
    fail "APEX blackout links are valid and describe the START end time ($(basename "$apex_source"))"
  fi
done

write_json "$TEST_TMP/page-with-next.json" '{
  "count": 1,
  "items": [{"id":"1","name":"CDBA","typeName":"oracle_database"}],
  "links": {"next":{"href":"/em/api/targets?page=next-token"}}
}'
expect_success "valid paginated collection is accepted" mf_oem_validate_collection_page "$TEST_TMP/page-with-next.json"
MF_OEM_API_BASE_URL=https://oms.example:7803
expect_success "same-origin pagination is accepted" mf_oem_same_origin_next_url "/em/api/targets?page=next-token" "/em/api/targets"
expect_failure "cross-origin pagination is rejected" mf_oem_same_origin_next_url "https://evil.example/em/api/targets?page=x" "/em/api/targets"

write_json "$TEST_TMP/page-1.json" '{
  "count": 1,
  "items": [{"id":"1","name":"CDBA","typeName":"oracle_database"}],
  "links": {"next":{"href":"/em/api/targets?page=page-2"}}
}'
write_json "$TEST_TMP/page-2.json" '{
  "count": 1,
  "items": [{"id":"2","name":"PDB_CDBA","typeName":"oracle_database"}],
  "links": {}
}'

curl()
{
  local url= output=
  while [ "$#" -gt 0 ]
  do
    case "$1" in
      --url) url="$2"; shift 2 ;;
      --output) output="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  case "$url" in
    *page=page-2) cp "$TEST_TMP/page-2.json" "$output" ;;
    *) cp "$TEST_TMP/page-1.json" "$output" ;;
  esac
  printf '200'
}

MF_TMP="$TEST_TMP"
MF_OEM_TMP_FILES=()
MF_OEM_API_USERNAME=test-user
MF_OEM_API_PASSWORD=test-password
if mf_oem_fetch_target_pages \
     "https://oms.example:7803/em/api/targets?limit=1" \
     "/em/api/targets" "oracle_database" "CDBA" "$TEST_TMP/paginated-output.json" \
   && [ "$(jq 'length' "$TEST_TMP/paginated-output.json")" = "2" ]
then
  pass "all advertised pagination pages are processed"
else
  fail "all advertised pagination pages are processed"
fi
unset -f curl
mf_oem_cleanup

printf 'tests: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
