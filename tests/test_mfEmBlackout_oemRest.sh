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
MF_TMP="$TEST_TMP"
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

expect_return()
{
  local name="$1"
  local expected="$2"
  shift 2
  "$@" >/dev/null 2>&1
  local actual=$?
  if [ "$actual" -eq "$expected" ]; then pass "$name"; else fail "$name"; fi
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
  '{
    "cdbName":"CDBA","targetContainerService":"CDBA_M1","startClusterId":"1",
    "clusters":[{"clusterId":"1","peerClusterId":null,"realName":"exa1"}],
    "dbUniqueNames":["CDBA_M1"]
  }' \
  '[
    {"id":"cdb-a","name":"exa1_CDBA_M1","typeName":"oracle_database","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}},
    {"id":"pdb-a1","name":"exa1_CDBA_M1_PDB1","typeName":"oracle_pdb","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}},
    {"id":"pdb-a2","name":"exa1_CDBA_M1_PDB2","typeName":"oracle_pdb","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}}
  ]' success_one

expect_success "primary plus multiple standby discovery" validate_fixture \
  '{
    "cdbName":"CDBA","targetContainerService":"CDBA_M1","startClusterId":"1",
    "clusters":[
      {"clusterId":"1","peerClusterId":null,"realName":"exa1"},
      {"clusterId":"2","peerClusterId":"1","realName":"exa2"},
      {"clusterId":"3","peerClusterId":"1","realName":"exa3"}
    ],
    "dbUniqueNames":["CDBA_M1","CDBA_M2","CDBA_M3"]
  }' \
  '[
    {"id":"cdb-1","name":"exa1_CDBA_M1","typeName":"oracle_database","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}},
    {"id":"pdb-1","name":"exa1_CDBA_M1_APP","typeName":"oracle_pdb","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}},
    {"id":"cdb-2","name":"exa2_CDBA_M2","typeName":"oracle_database","member":{"clusterId":"2","realName":"exa2","dbUniqueName":"CDBA_M2","targetPrefix":"exa2_CDBA_M2","discoveryMode":"target_prefix"}},
    {"id":"pdb-2","name":"exa2_CDBA_M2_APP","typeName":"oracle_pdb","member":{"clusterId":"2","realName":"exa2","dbUniqueName":"CDBA_M2","targetPrefix":"exa2_CDBA_M2","discoveryMode":"target_prefix"}},
    {"id":"cdb-3","name":"exa3_CDBA_M3","typeName":"oracle_database","member":{"clusterId":"3","realName":"exa3","dbUniqueName":"CDBA_M3","targetPrefix":"exa3_CDBA_M3","discoveryMode":"cdb_name_fallback"}},
    {"id":"pdb-3","name":"exa3_CDBA_M3_APP","typeName":"oracle_pdb","member":{"clusterId":"3","realName":"exa3","dbUniqueName":"CDBA_M3","targetPrefix":"exa3_CDBA_M3","discoveryMode":"cdb_name_fallback"}}
  ]' success_peer

one_topology='{"cdbName":"CDBA","targetContainerService":"CDBA_M1","startClusterId":"1","clusters":[{"clusterId":"1","peerClusterId":null,"realName":"exa1"}],"dbUniqueNames":["CDBA_M1"]}'
one_member='{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}'

expect_failure "zero targets fails closed" validate_fixture "$one_topology" '[]' zero

expect_failure "database-only discovery cannot satisfy the REST DB and PDB requirement" validate_fixture \
  "$one_topology" \
  '[{"id":"cdb-a","name":"exa1_CDBA_M1","typeName":"oracle_database","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}}]' db_only

expect_failure "missing standby target fails closed" validate_fixture \
  '{"cdbName":"CDBA","targetContainerService":"CDBA_M1","startClusterId":"1","clusters":[{"clusterId":"1","peerClusterId":null,"realName":"exa1"},{"clusterId":"2","peerClusterId":"1","realName":"exa2"}],"dbUniqueNames":["CDBA_M1","CDBA_M2"]}' \
  '[{"id":"cdb-p","name":"exa1_CDBA_M1","typeName":"oracle_database","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}}]' missing_peer

expect_success "identical duplicate target IDs are deduplicated" validate_fixture \
  "$one_topology" \
  '[
    {"id":"cdb-a","name":"exa1_CDBA_M1","typeName":"oracle_database","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}},
    {"id":"cdb-a","name":"exa1_CDBA_M1","typeName":"oracle_database","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}},
    {"id":"pdb-a","name":"exa1_CDBA_M1_PDB","typeName":"oracle_pdb","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}}
  ]' duplicate_identical

expect_failure "conflicting duplicate target IDs fail closed" validate_fixture \
  "$one_topology" \
  '[
    {"id":"same-id","name":"exa1_CDBA_M1","typeName":"oracle_database","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}},
    {"id":"same-id","name":"exa1_CDBA_M1_PDB","typeName":"oracle_pdb","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}}
  ]' duplicate_conflict

expect_failure "unexpected target type fails closed" validate_fixture \
  "$one_topology" \
  '[{"id":"host-a","name":"exa1_CDBA_M1","typeName":"host","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}}]' unexpected_type

expect_success "consistent topology is accepted" mf_oem_validate_topology "$TEST_TMP/success_peer.required.json"
write_json "$TEST_TMP/topology-count-mismatch.json" '{"cdbName":"CDBA","targetContainerService":"CDBA_M1","startClusterId":"1","clusters":[{"clusterId":"1","peerClusterId":null,"realName":"exa1"},{"clusterId":"2","peerClusterId":"1","realName":"exa2"}],"dbUniqueNames":["CDBA_M1"]}'
expect_failure "MF and Data Guard member count mismatch fails REST validation" mf_oem_validate_topology "$TEST_TMP/topology-count-mismatch.json"

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
expect_success "STOPPED is a completed stop" mf_oem_stop_status_result STOPPED
expect_return "STOP_PENDING remains in progress" 2 mf_oem_stop_status_result STOP_PENDING
expect_failure "STOP_PARTIAL is a failed stop" mf_oem_stop_status_result STOP_PARTIAL

write_json "$TEST_TMP/payload-targets.json" '[
  {"id":"cdb-a","name":"exa1_CDBA_M1","typeName":"oracle_database","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}},
  {"id":"pdb-a","name":"exa1_CDBA_M1_PDB","typeName":"oracle_pdb","member":{"clusterId":"1","realName":"exa1","dbUniqueName":"CDBA_M1","targetPrefix":"exa1_CDBA_M1","discoveryMode":"target_prefix"}}
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

if grep -E '^[[:space:]]*ACTION=START$' "$MAIN_SCRIPT" >/dev/null \
   && grep -E '^[[:space:]]*ACTION=START$' "$UNSTABLE_MAIN_SCRIPT" >/dev/null
then
  pass "START remains the compatible default action in bin and unstable_bin"
else
  fail "START remains the compatible default action in bin and unstable_bin"
fi

write_json "$TEST_TMP/blackout-page.json" '{
  "count": 1,
  "items": [{"id":"B-1","name":"MF_MIG-42","status":"STARTED","type":"PATCHING","owner":"mf-user"}],
  "links": {}
}'
expect_success "valid blackout collection is accepted" mf_oem_validate_blackout_collection_page "$TEST_TMP/blackout-page.json"

write_json "$TEST_TMP/blackouts.json" '[
  {"id":"B-OLD","name":"MF_2_CDBA_Migration","status":"ENDED","type":"PATCHING","owner":"mf-user"},
  {"id":"B-1","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf-user"},
  {"id":"B-2","name":"MF_2_CDBA_Migration","status":"STOP_PENDING","type":"PATCHING","owner":"mf-user"},
  {"id":"B-DATED","name":"MF_2_CDBA_Migration_20260808_153000","status":"STARTED","type":"PATCHING","owner":"mf-user"}
]'
if mf_oem_classify_active_blackouts "$TEST_TMP/blackouts.json" 'MF_2_CDBA_Migration' \
     "$TEST_TMP/exact-blackouts.json" "$TEST_TMP/suffixed-blackouts.json" \
   && [ "$(jq 'length' "$TEST_TMP/exact-blackouts.json")" = "2" ] \
   && [ "$(jq -r '.[0].id' "$TEST_TMP/suffixed-blackouts.json")" = "B-DATED" ]
then
  pass "multiple exact legacy IDs are retained while timestamp-suffixed names are separated"
else
  fail "multiple exact legacy IDs are retained while timestamp-suffixed names are separated"
fi

write_json "$TEST_TMP/no-active-blackouts.json" '[
  {"id":"B-OLD","name":"MF_2_CDBA_Migration","status":"ENDED","type":"PATCHING","owner":"mf-user"}
]'
if mf_oem_classify_active_blackouts "$TEST_TMP/no-active-blackouts.json" 'MF_2_CDBA_Migration' \
     "$TEST_TMP/no-active-exact.json" "$TEST_TMP/no-active-suffixed.json" \
   && [ "$(jq 'length' "$TEST_TMP/no-active-exact.json")" = "0" ]
then
  pass "no canonical active blackout is a valid REST result"
else
  fail "no canonical active blackout is a valid REST result"
fi

MF_OEM_BLACKOUT_NAME=MF_2_CDBA_Migration
write_json "$TEST_TMP/legacy-db-only.json" '[
  {"id":"LEGACY-DB","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf-user"}
]'
write_json "$TEST_TMP/legacy-db-target.json" '[
  {"id":"cdb-a","name":"exa1_CDBA_M1","typeName":"oracle_database"}
]'
write_json "$TEST_TMP/full-targets.json" '[
  {"id":"cdb-a","name":"exa1_CDBA_M1","typeName":"oracle_database"},
  {"id":"pdb-a","name":"exa1_CDBA_M1_PDB","typeName":"oracle_pdb"}
]'
mf_oem_get_blackout()
{
  local id="$1" output="$2"
  printf '{"id":"%s","name":"MF_2_CDBA_Migration","status":"STARTED"}\n' "$id" > "$output"
}
mf_oem_fetch_blackout_targets()
{
  case "$1" in
    LEGACY-DB) cp "$TEST_TMP/legacy-db-target.json" "$2" ;;
    FULL-REST) cp "$TEST_TMP/full-targets.json" "$2" ;;
    *) return 1 ;;
  esac
}
MF_OEM_TMP_FILES=()
if mf_oem_build_blackout_coverage 'MIG-42' "$TEST_TMP/legacy-db-only.json" \
     "$TEST_TMP/payload-targets.json" "$TEST_TMP/db-only-coverage.json" \
   && jq -e '.complete == false and (.missingTargets | map(.typeName)) == ["oracle_pdb"]' \
        "$TEST_TMP/db-only-coverage.json" >/dev/null
then
  pass "legacy database-only IDs are incomplete when PDB coverage is required"
else
  fail "legacy database-only IDs are incomplete when PDB coverage is required"
fi

write_json "$TEST_TMP/legacy-plus-full.json" '[
  {"id":"LEGACY-DB","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf-user"},
  {"id":"FULL-REST","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf-user"}
]'
MF_OEM_TMP_FILES=()
if mf_oem_build_blackout_coverage 'MIG-42' "$TEST_TMP/legacy-plus-full.json" \
     "$TEST_TMP/payload-targets.json" "$TEST_TMP/full-coverage.json" \
   && jq -e '.complete == true and .fullCoverageBlackoutIds == ["FULL-REST"]' \
        "$TEST_TMP/full-coverage.json" >/dev/null
then
  pass "one full REST ID satisfies coverage alongside legacy database-only IDs"
else
  fail "one full REST ID satisfies coverage alongside legacy database-only IDs"
fi
unset -f mf_oem_get_blackout mf_oem_fetch_blackout_targets

write_json "$TEST_TMP/state-required.json" "$one_topology"
write_json "$TEST_TMP/state-response.json" '{"id":"BLACKOUT-1","name":"MF_MIG-42","status":"STARTED"}'
MF_DATA="$TEST_TMP/data"
MF_OEM_API_BASE_URL=https://oms.example:7803
MF_OEM_BLACKOUT_STATE_DIR="$MF_DATA/em_blackouts"
unset MF_OEM_BLACKOUT_STATE_FILE
if mf_oem_prepare_state_file 'MIG-42' \
   && mf_oem_write_state 'MIG-42' "$TEST_TMP/state-required.json" \
        "$TEST_TMP/payload-targets.json" "$TEST_TMP/state-response.json" true \
   && [ "$(stat -c '%a' "$MF_OEM_BLACKOUT_STATE_FILE")" = "600" ] \
   && jq -e '.blackoutId == "BLACKOUT-1" and .targetCoverageVerified == true and
             .requiredTopology.cdbName == "CDBA" and (.targets | length) == 2' \
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

rest_block=$(awk '
  /if \[ "\$USE_REST_API" = "Y" \]/{capture=1}
  capture && /^  if \[ "\$USE_REST_API" != "Y" \]/{exit}
  capture{print}
' "$MAIN_SCRIPT")
if printf '%s\n' "$rest_block" | grep -E 'exec_on_target|emctl start blackout|config agent listtargets|ssh ' >/dev/null
then
  fail "REST path directly invokes SSH or emctl"
elif printf '%s\n' "$rest_block" | grep -F 'mf_oem_start_blackout' >/dev/null \
     && printf '%s\n' "$rest_block" | grep -F 'mf_oem_status_blackout' >/dev/null \
     && printf '%s\n' "$rest_block" | grep -F 'mf_oem_is_blackout_on' >/dev/null \
     && printf '%s\n' "$rest_block" | grep -F 'mf_oem_stop_blackout' >/dev/null \
     && printf '%s\n' "$rest_block" | grep -F 'USE_REST_API=N' >/dev/null
then
  pass "-r uses REST first and selects local fallback only after safe failures"
else
  fail "-r uses REST first and selects local fallback only after safe failures"
fi

legacy_block=$(awk '
  /if \[ "\$USE_REST_API" != "Y" \]/{capture=1; next}
  capture && /^  fi$/{exit}
  capture{print}
' "$MAIN_SCRIPT")
if printf '%s\n' "$legacy_block" | grep -F '$EMCTL start blackout' >/dev/null \
   && printf '%s\n' "$legacy_block" | grep -F '$EMCTL status blackout' >/dev/null \
   && printf '%s\n' "$legacy_block" | grep -F '$EMCTL stop blackout' >/dev/null
then
  pass "without -r every action retains local emctl behavior"
else
  fail "without -r every action retains local emctl behavior"
fi

if grep -F '. "$SCRIPT_DIR/mfEmBlackout_oemRest.sh"' "$MAIN_SCRIPT" >/dev/null \
   && ! awk '/for s in \$MF_BIN\/mfUtils_/{capture=1} capture && /startStep "Initialization"/{exit} capture{print}' "$MAIN_SCRIPT" \
          | grep -F 'mfEmBlackout_oemRest.sh' >/dev/null
then
  pass "REST helper is loaded only after -r has been parsed"
else
  fail "REST helper is loaded only after -r has been parsed"
fi

if grep -F 'while getopts :m:A:d:rQVnh opt' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'r) USE_REST_API=Y' "$MAIN_SCRIPT" >/dev/null
then
  pass "-r is an explicit opt-in switch"
else
  fail "-r is an explicit opt-in switch"
fi

if grep -F 'MF_OEM_BLACKOUT_NAME=MF_2_${CDB_NAME}_Migration' "$MAIN_SCRIPT" >/dev/null \
   && ! grep -F 'MF_OEM_BLACKOUT_NAME=${MF_OEM_BLACKOUT_NAME:-' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'nameMatches=${encoded}' "$SCRIPT_DIR/mfEmBlackout_oemRest.sh" >/dev/null \
   && grep -F 'Ignoring %s active OEM blackout(s) whose name has a suffix' \
        "$SCRIPT_DIR/mfEmBlackout_oemRest.sh" >/dev/null
then
  pass "the canonical blackout name is fixed and timestamp-suffixed names are warning-only"
else
  fail "the canonical blackout name is fixed and timestamp-suffixed names are warning-only"
fi

if ! grep -F '[ "${MF_OEM_LOOKUP_RESULT:-}" = "NOT_ACTIVE" ]' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'OEM REST STATUS workflow failed; falling back to local emctl' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'return 3' "$SCRIPT_DIR/mfEmBlackout_oemRest.sh" >/dev/null
then
  pass "semantic REST results do not trigger the temporary emctl fallback"
else
  fail "semantic REST results do not trigger the temporary emctl fallback"
fi

if grep -F 'limit=100&typeName=oracle_database&typeName=oracle_pdb&nameMatches=${encoded}' \
     "$SCRIPT_DIR/mfEmBlackout_oemRest.sh" >/dev/null \
   && grep -F 'discoveryMode: "cdb_name_fallback"' "$SCRIPT_DIR/mfEmBlackout_oemRest.sh" >/dev/null
then
  pass "OEM 13.5 target discovery uses one repeated-typeName call and a CDB-name fallback"
else
  fail "OEM 13.5 target discovery uses one repeated-typeName call and a CDB-name fallback"
fi

apex_sources=(
  "$RELEASE_ROOT/repository/plsql/mf_apex_utils.pkb"
  "$RELEASE_ROOT/repository/fullDDL/060_package_mf_apex_utils.pks"
  "$RELEASE_ROOT/repository/fullDDL/061_package_body_mf_apex_utils.pkb"
)
for apex_source in "${apex_sources[@]}"
do
  if grep -F "rec.code || ' -A START ,Start local emctl Blackout'" "$apex_source" >/dev/null \
     && grep -F "rec.code || ' -r -A STATUS ,OEM REST Blackout status for '" "$apex_source" >/dev/null \
     && grep -F "rec.code || ' -r -A START ,Start OEM REST Blackout: go-live plus 12 hours; 12-hour fallback if not planned'" "$apex_source" >/dev/null \
     && grep -F "rec.code || ' -r -A STOP ,Stop OEM REST Blackout'" "$apex_source" >/dev/null
  then
    pass "APEX exposes separate local and OEM REST blackout actions ($(basename "$apex_source"))"
  else
    fail "APEX exposes separate local and OEM REST blackout actions ($(basename "$apex_source"))"
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
  local url= output= config_line
  while [ "$#" -gt 0 ]
  do
    case "$1" in
      --url) url="$2"; shift 2 ;;
      --output) output="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  while IFS= read -r config_line
  do
    :
  done
  case "$url" in
    *page=page-2) cp "$TEST_TMP/page-2.json" "$output" ;;
    *) cp "$TEST_TMP/page-1.json" "$output" ;;
  esac
  printf '200'
}

MF_OEM_TMP_FILES=()
MF_OEM_API_USERNAME=test-user
MF_OEM_API_PASSWORD=test-password
if mf_oem_fetch_target_pages \
     "https://oms.example:7803/em/api/targets?limit=1" \
     "/em/api/targets" "oracle_database" null "$TEST_TMP/paginated-output.json" \
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
