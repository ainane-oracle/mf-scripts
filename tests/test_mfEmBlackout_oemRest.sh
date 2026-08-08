#!/usr/bin/env bash

# Offline fixture tests for the opt-in OEM REST blackout workflow.
# No OEM, database, Migration Factory, or APEX endpoint is contacted.

set -u

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RELEASE_ROOT=$(cd "$TEST_DIR/.." && pwd)
HELPER="$RELEASE_ROOT/bin/mfEmBlackout_oemRest.sh"
MAIN_SCRIPT="$RELEASE_ROOT/bin/mfEmBlackout.sh"
UNSTABLE_SCRIPT="$RELEASE_ROOT/unstable_bin/mfEmBlackout.sh"
TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/mfEmBlackout-test.XXXXXX")
trap 'rm -rf -- "$TEST_TMP"' EXIT

# shellcheck source=../bin/mfEmBlackout_oemRest.sh
. "$HELPER"

if ! command -v jq >/dev/null 2>&1
then
  printf 'fixture prerequisite missing: jq\n' >&2
  exit 127
fi

MF_TMP=$TEST_TMP
MF_OEM_API_BASE_URL=https://oms.example:7803
MF_OEM_BLACKOUT_NAME=MF_2_CDBA_Migration
MF_OEM_BLACKOUT_REASON_ID=29
MF_OEM_BLACKOUT_ALLOW_JOBS=true
MF_OEM_VERIFY_ATTEMPTS=1
MF_OEM_VERIFY_INTERVAL=0

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

validate_discovery_fixture()
{
  local topology_file="$1"
  local candidates_file="$2"
  local expected_count="$3"
  local resolution_file="$TEST_TMP/resolution.$$.json"
  local selected_file="$TEST_TMP/selected.$$.json"
  local normalized_file="$TEST_TMP/normalized.$$.json"

  mf_oem_filter_targets_by_topology "$topology_file" "$candidates_file" "$resolution_file" || return 1
  jq -e '.ambiguousTargetCount == 0' "$resolution_file" >/dev/null || return 1
  jq '.targets' "$resolution_file" > "$selected_file" || return 1
  mf_oem_validate_resolved_targets "$topology_file" "$selected_file" "$normalized_file" || return 1
  [ "$(jq 'length' "$normalized_file")" -eq "$expected_count" ]
}

# -----------------------------------------------------------------------------
# Target discovery and topology fixtures
# -----------------------------------------------------------------------------

write_json "$TEST_TMP/topology-two.json" '{
  "cdbName":"CDBA",
  "targetContainerService":"CDBA_M1",
  "startClusterId":"1",
  "clusters":[
    {"clusterId":"1","realName":"exa1"},
    {"clusterId":"2","realName":"exa2"}
  ]
}'

write_json "$TEST_TMP/targets-all.json" '[
  {"id":"db-1a","name":"exa1_CDBA_M1","typeName":"oracle_database"},
  {"id":"db-1b","name":"exa1_CDBA_M1","typeName":"oracle_database"},
  {"id":"pdb-1a","name":"exa1_CDBA_M1_APP","typeName":"oracle_pdb"},
  {"id":"pdb-1b","name":"exa1_CDBA_M1_AUDIT","typeName":"oracle_pdb"},
  {"id":"db-2","name":"exa2_CDBA_M2","typeName":"oracle_database"},
  {"id":"pdb-2","name":"exa2_CDBA_M2_APP","typeName":"oracle_pdb"},
  {"id":"unrelated","name":"exa1_CDBA2_M1","typeName":"oracle_database"}
]'

expect_success "multiple database targets per cluster and all discovered PDBs are retained" \
  validate_discovery_fixture "$TEST_TMP/topology-two.json" "$TEST_TMP/targets-all.json" 6

mf_oem_filter_targets_by_topology "$TEST_TMP/topology-two.json" "$TEST_TMP/targets-all.json" \
  "$TEST_TMP/prefix-filter.json"
if jq -e '
     (.targets | map(.id) | index("unrelated")) == null and
     ([.targets[] | select(.typeName == "oracle_pdb")] | length) == 3 and
     ([.targets[] | select(.member.clusterId == "1" and .typeName == "oracle_database")] | length) == 2
   ' "$TEST_TMP/prefix-filter.json" >/dev/null
then
  pass "exact prefix boundary rejects CDBA2 while retaining every CDBA target"
else
  fail "exact prefix boundary rejects CDBA2 while retaining every CDBA target"
fi

write_json "$TEST_TMP/topology-one.json" '{
  "cdbName":"CDBA",
  "targetContainerService":"CDBA_M1",
  "startClusterId":"1",
  "clusters":[{"clusterId":"1","realName":"exa1"}]
}'
write_json "$TEST_TMP/targets-db-only.json" '[
  {"id":"db-1a","name":"exa1_CDBA_M1","typeName":"oracle_database"},
  {"id":"db-1b","name":"exa1_CDBA_M1","typeName":"oracle_database"}
]'
expect_success "zero oracle_pdb targets is valid" \
  validate_discovery_fixture "$TEST_TMP/topology-one.json" "$TEST_TMP/targets-db-only.json" 2

write_json "$TEST_TMP/targets-empty.json" '[]'
expect_failure "empty discovery fails closed" \
  validate_discovery_fixture "$TEST_TMP/topology-one.json" "$TEST_TMP/targets-empty.json" 0

write_json "$TEST_TMP/targets-unrelated-only.json" '[
  {"id":"db-other","name":"exa1_CDBA2_M1","typeName":"oracle_database"}
]'
expect_failure "an unrelated prefix cannot satisfy discovery" \
  validate_discovery_fixture "$TEST_TMP/topology-one.json" "$TEST_TMP/targets-unrelated-only.json" 1

write_json "$TEST_TMP/targets-duplicate-identical.json" '[
  {"id":"db-1","name":"exa1_CDBA_M1","typeName":"oracle_database"},
  {"id":"db-1","name":"exa1_CDBA_M1","typeName":"oracle_database"}
]'
expect_success "identical duplicate target IDs are deduplicated" \
  validate_discovery_fixture "$TEST_TMP/topology-one.json" "$TEST_TMP/targets-duplicate-identical.json" 1

write_json "$TEST_TMP/targets-duplicate-conflict.json" '[
  {"id":"shared-id","name":"exa1_CDBA_M1","typeName":"oracle_database"},
  {"id":"shared-id","name":"exa1_CDBA_M1_APP","typeName":"oracle_pdb"}
]'
expect_failure "conflicting duplicate target IDs fail closed" \
  validate_discovery_fixture "$TEST_TMP/topology-one.json" "$TEST_TMP/targets-duplicate-conflict.json" 1

write_json "$TEST_TMP/targets-same-name-two-ids.json" '[
  {"id":"db-a","name":"exa1_CDBA_M1","typeName":"oracle_database"},
  {"id":"db-b","name":"exa1_CDBA_M1","typeName":"oracle_database"}
]'
expect_success "name and type may legitimately map to multiple authoritative IDs" \
  validate_discovery_fixture "$TEST_TMP/topology-one.json" "$TEST_TMP/targets-same-name-two-ids.json" 2

write_json "$TEST_TMP/targets-unsupported.json" '[
  {"id":"host-1","name":"exa1_CDBA_M1","typeName":"host"}
]'
expect_failure "only oracle_database and oracle_pdb targets are accepted" \
  validate_discovery_fixture "$TEST_TMP/topology-one.json" "$TEST_TMP/targets-unsupported.json" 1

expect_success "direct attempt/peer topology fixture is valid" \
  mf_oem_validate_topology "$TEST_TMP/topology-two.json"

# -----------------------------------------------------------------------------
# Duration payload and OEM lifecycle status fixtures
# -----------------------------------------------------------------------------

expect_return "SCHEDULED is an accepted START result" 0 mf_oem_start_status_result SCHEDULED
expect_return "STARTED is an accepted START result" 0 mf_oem_start_status_result STARTED
expect_return "START_PROCESSING remains transitional" 2 mf_oem_start_status_result START_PROCESSING
expect_failure "START_PARTIAL is a failed START result" mf_oem_start_status_result START_PARTIAL
expect_return "STOPPED completes STOP" 0 mf_oem_stop_status_result STOPPED
expect_return "ENDED completes STOP" 0 mf_oem_stop_status_result ENDED
expect_return "STOP_PENDING remains transitional" 2 mf_oem_stop_status_result STOP_PENDING
expect_failure "STOP_PARTIAL fails STOP" mf_oem_stop_status_result STOP_PARTIAL

if [ "$(mf_oem_parse_duration '12:00')" = "12|0" ] \
   && [ "$(mf_oem_parse_duration '1 02:30')" = "26|30" ]
then
  pass "legacy -d duration is translated for REST"
else
  fail "legacy -d duration is translated for REST"
fi
expect_failure "invalid REST duration is rejected" mf_oem_parse_duration '12:60'
expect_failure "zero REST duration is rejected" mf_oem_parse_duration '00:00'

write_json "$TEST_TMP/payload-targets.json" '[
  {"id":"db-1","name":"exa1_CDBA_M1","typeName":"oracle_database","member":{"clusterId":"1","realName":"exa1"}},
  {"id":"pdb-1","name":"exa1_CDBA_M1_APP","typeName":"oracle_pdb","member":{"clusterId":"1","realName":"exa1"}}
]'
if mf_oem_build_payload MIG-42 "$TEST_TMP/payload-targets.json" '1 02:30' "$TEST_TMP/payload.json" \
   && jq -e '
        .name == "MF_2_CDBA_Migration" and
        .durationHours == 26 and
        .durationMinutes == 30 and
        (has("timeToEnd") | not) and
        .targets == [{"id":"db-1"},{"id":"pdb-1"}]
      ' "$TEST_TMP/payload.json" >/dev/null
then
  pass "REST payload uses canonical name, duration, and authoritative target IDs"
else
  fail "REST payload uses canonical name, duration, and authoritative target IDs"
fi

expect_success "HTTP 200 is accepted for GET" mf_oem_expect_http 200 200 "test request"
expect_success "HTTP 201 is accepted for create" mf_oem_expect_http 201 201 "test request"
expect_success "HTTP 204 is accepted for stop and delete" mf_oem_expect_http 204 204 "test request"
expect_failure "unexpected HTTP status is rejected" mf_oem_expect_http 409 201 "test request"

# -----------------------------------------------------------------------------
# Single canonical ID inspection: no coverage union across IDs
# -----------------------------------------------------------------------------

write_json "$TEST_TMP/expected.json" '[
  {"id":"db-1","name":"exa1_CDBA_M1","typeName":"oracle_database"},
  {"id":"pdb-1","name":"exa1_CDBA_M1_APP","typeName":"oracle_pdb"}
]'
write_json "$TEST_TMP/candidates-zero.json" '[]'
expect_success "zero exact-name candidates is represented without creating coverage" \
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidates-zero.json" "$TEST_TMP/expected.json" \
    "$TEST_TMP/inspection-zero.json"

write_json "$TEST_TMP/candidates-duplicate.json" '[
  {"id":"BLACKOUT-A","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf"},
  {"id":"BLACKOUT-B","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf"}
]'
if mf_oem_inspect_exact_blackouts "$TEST_TMP/candidates-duplicate.json" "$TEST_TMP/expected.json" \
     "$TEST_TMP/inspection-duplicate.json" \
   && jq -e '.candidateCount == 2 and .exactTargetIds == false and (has("coveredTargets") | not)' \
        "$TEST_TMP/inspection-duplicate.json" >/dev/null
then
  pass "duplicate exact-name IDs conflict instead of contributing union coverage"
else
  fail "duplicate exact-name IDs conflict instead of contributing union coverage"
fi

write_json "$TEST_TMP/candidate-one.json" '[
  {"id":"BLACKOUT-1","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf"}
]'
write_json "$TEST_TMP/detail-started.json" \
  '{"id":"BLACKOUT-1","name":"MF_2_CDBA_Migration","status":"STARTED"}'
write_json "$TEST_TMP/detail-scheduled.json" \
  '{"id":"BLACKOUT-1","name":"MF_2_CDBA_Migration","status":"SCHEDULED"}'
write_json "$TEST_TMP/actual-full.json" '[
  {"id":"db-1","name":"renamed-display-value","typeName":"oracle_database"},
  {"id":"pdb-1","name":"another-display-value","typeName":"oracle_pdb"}
]'
write_json "$TEST_TMP/actual-incomplete.json" '[
  {"id":"db-1","name":"exa1_CDBA_M1","typeName":"oracle_database"}
]'

if (
  mf_oem_get_blackout() { cp "$TEST_TMP/detail-started.json" "$2"; }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-full.json" "$2"; }
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidate-one.json" "$TEST_TMP/expected.json" \
    "$TEST_TMP/inspection-one.json"
) && jq -e '.candidateCount == 1 and .status == "STARTED" and .exactTargetIds' \
     "$TEST_TMP/inspection-one.json" >/dev/null
then
  pass "one exact-name ID uses target-ID equality without repeated name/type comparison"
else
  fail "one exact-name ID uses target-ID equality without repeated name/type comparison"
fi

if (
  mf_oem_get_blackout() { cp "$TEST_TMP/detail-started.json" "$2"; }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-incomplete.json" "$2"; }
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidate-one.json" "$TEST_TMP/expected.json" \
    "$TEST_TMP/inspection-incomplete.json"
) && jq -e '.candidateCount == 1 and (.exactTargetIds | not)' \
     "$TEST_TMP/inspection-incomplete.json" >/dev/null
then
  pass "singleton exact-name blackout is incomplete when any discovered PDB ID is missing"
else
  fail "singleton exact-name blackout is incomplete when any discovered PDB ID is missing"
fi

# -----------------------------------------------------------------------------
# START semantics and mutation boundary fixtures
# -----------------------------------------------------------------------------

write_json "$TEST_TMP/inspection-scheduled.json" '{
  "candidateCount":1,"activeCandidateCount":1,"blackoutId":"BLACKOUT-1",
  "status":"SCHEDULED","exactTargetIds":true,"expectedTargets":[]
}'
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-one.json" "$6"
    cp "$TEST_TMP/inspection-scheduled.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_http() { return 99; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >/dev/null \
    && [ "$MF_OEM_START_MUTATION_ATTEMPTED" = N ]
)
then
  pass "START accepts one complete SCHEDULED canonical blackout without creating"
else
  fail "START accepts one complete SCHEDULED canonical blackout without creating"
fi

write_json "$TEST_TMP/inspection-incomplete-start.json" '{
  "candidateCount":1,"activeCandidateCount":1,"blackoutId":"BLACKOUT-1",
  "status":"STARTED","exactTargetIds":false,"expectedTargets":[]
}'
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-one.json" "$6"
    cp "$TEST_TMP/inspection-incomplete-start.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_http() { return 99; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >/dev/null 2>&1
  rc=$?
  [ "$rc" -eq 3 ] && [ "$MF_OEM_START_MUTATION_ATTEMPTED" = N ]
)
then
  pass "START fails semantically for an incomplete exact-name candidate and does not create"
else
  fail "START fails semantically for an incomplete exact-name candidate and does not create"
fi

write_json "$TEST_TMP/inspection-create.json" '{
  "candidateCount":0,"activeCandidateCount":0,"candidates":[],"exactTargetIds":false,
  "expectedTargets":[{"id":"db-1","name":"exa1_CDBA_M1","typeName":"oracle_database"}]
}'
write_json "$TEST_TMP/create-response.json" \
  '{"id":"BLACKOUT-NEW","name":"MF_2_CDBA_Migration","status":"SCHEDULED"}'
: > "$TEST_TMP/create-sequence.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-zero.json" "$6"
    cp "$TEST_TMP/inspection-create.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_verify_blackout_targets() { [ "$1" = BLACKOUT-NEW ]; }
  mf_oem_http() {
    [ "$1" = POST ] && [ "$2" = "https://oms.example:7803/em/api/blackouts" ] || return 1
    printf 'POST_CREATE %s\n' "$2" >> "$TEST_TMP/create-sequence.log"
    cp "$TEST_TMP/create-response.json" "$3"
    MF_OEM_HTTP_STATUS=201
  }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >/dev/null \
    && [ "$MF_OEM_START_MUTATION_ATTEMPTED" = Y ] \
    && [ "$MF_OEM_MUTATION_ATTEMPTED" = Y ]
)
then
  pass "zero exact-name candidates creates one complete blackout and accepts SCHEDULED"
else
  fail "zero exact-name candidates creates one complete blackout and accepts SCHEDULED"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-zero.json" "$6"
    cp "$TEST_TMP/inspection-create.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_http() { return 1; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >/dev/null 2>&1
  rc=$?
  [ "$rc" -ne 0 ] && [ "$MF_OEM_START_MUTATION_ATTEMPTED" = Y ] \
    && [ "$MF_OEM_MUTATION_ATTEMPTED" = Y ]
)
then
  pass "uncertain create response marks the mutation boundary and blocks fallback"
else
  fail "uncertain create response marks the mutation boundary and blocks fallback"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-one.json" "$6"
    cp "$TEST_TMP/inspection-scheduled.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_is_blackout_on MIG-42 42 CDBA CDBA_M1 >/dev/null 2>&1
  [ "$?" -eq 3 ]
)
then
  pass "IS_ON does not report ON for a merely SCHEDULED blackout"
else
  fail "IS_ON does not report ON for a merely SCHEDULED blackout"
fi

# -----------------------------------------------------------------------------
# STOP -> terminal state -> DELETE and uncertainty fixtures
# -----------------------------------------------------------------------------

write_json "$TEST_TMP/inspection-started.json" '{
  "candidateCount":1,"activeCandidateCount":1,"blackoutId":"BLACKOUT-1",
  "status":"STARTED","exactTargetIds":true,"expectedTargets":[]
}'
write_json "$TEST_TMP/detail-stopped.json" \
  '{"id":"BLACKOUT-1","name":"MF_2_CDBA_Migration","status":"STOPPED"}'
: > "$TEST_TMP/stop-sequence.log"
if (
  MF_OEM_GET_COUNT=0
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-one.json" "$6"
    cp "$TEST_TMP/inspection-started.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_get_blackout() {
    MF_OEM_GET_COUNT=$((MF_OEM_GET_COUNT + 1))
    if [ "$MF_OEM_GET_COUNT" -eq 1 ]; then cp "$TEST_TMP/detail-started.json" "$2"
    else cp "$TEST_TMP/detail-stopped.json" "$2"; fi
  }
  mf_oem_http() {
    case "$1 $2" in
      "POST https://oms.example:7803/em/api/blackouts/BLACKOUT-1/actions/stop")
        printf 'POST_STOP %s\n' "$2" >> "$TEST_TMP/stop-sequence.log"
        : > "$3"; MF_OEM_HTTP_STATUS=204 ;;
      "DELETE https://oms.example:7803/em/api/blackouts/BLACKOUT-1")
        printf 'DELETE %s\n' "$2" >> "$TEST_TMP/stop-sequence.log"
        : > "$3"; MF_OEM_HTTP_STATUS=204 ;;
      *) return 1 ;;
    esac
  }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null \
    && [ "$MF_OEM_STOP_MUTATION_ATTEMPTED" = Y ] \
    && [ "$MF_OEM_DELETE_MUTATION_ATTEMPTED" = Y ] \
    && [ "$(sed -n '1p' "$TEST_TMP/stop-sequence.log")" = \
         "POST_STOP https://oms.example:7803/em/api/blackouts/BLACKOUT-1/actions/stop" ] \
    && [ "$(sed -n '2p' "$TEST_TMP/stop-sequence.log")" = \
         "DELETE https://oms.example:7803/em/api/blackouts/BLACKOUT-1" ]
)
then
  pass "STOP verifies one ID, waits for STOPPED, then deletes that same ID with HTTP 204"
else
  fail "STOP verifies one ID, waits for STOPPED, then deletes that same ID with HTTP 204"
fi

if (
  mf_oem_http() { return 1; }
  MF_OEM_DELETE_MUTATION_ATTEMPTED=N
  MF_OEM_STOP_MUTATION_ATTEMPTED=N
  MF_OEM_MUTATION_ATTEMPTED=N
  mf_oem_delete_blackout BLACKOUT-1 >/dev/null 2>&1
  rc=$?
  [ "$rc" -ne 0 ] \
    && [ "$MF_OEM_DELETE_MUTATION_ATTEMPTED" = Y ] \
    && [ "$MF_OEM_STOP_MUTATION_ATTEMPTED" = Y ] \
    && [ "$MF_OEM_MUTATION_ATTEMPTED" = Y ]
)
then
  pass "uncertain DELETE response is mutation-guarded and cannot fall back to emctl"
else
  fail "uncertain DELETE response is mutation-guarded and cannot fall back to emctl"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-duplicate.json" "$6"
    cp "$TEST_TMP/inspection-duplicate.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_http() { return 99; }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null 2>&1
  rc=$?
  [ "$rc" -eq 3 ] && [ "$MF_OEM_MUTATION_ATTEMPTED" = N ]
)
then
  pass "STOP rejects duplicate exact-name IDs without stopping or deleting any of them"
else
  fail "STOP rejects duplicate exact-name IDs without stopping or deleting any of them"
fi

if grep -q '^DELETE https://oms.example:7803/em/api/blackouts/BLACKOUT-1$' "$TEST_TMP/stop-sequence.log" \
   && grep -q '^POST_CREATE https://oms.example:7803/em/api/blackouts$' "$TEST_TMP/create-sequence.log"
then
  pass "successful delete leaves the zero-candidate START path available for canonical-name reuse without HTTP 409"
else
  fail "successful delete leaves the zero-candidate START path available for canonical-name reuse without HTTP 409"
fi

# -----------------------------------------------------------------------------
# Offline safety, integration, and regression checks
# -----------------------------------------------------------------------------

write_json "$TEST_TMP/page-with-next.json" '{
  "count":1,
  "items":[{"id":"db-1","name":"exa1_CDBA_M1","typeName":"oracle_database"}],
  "links":{"next":{"href":"/em/api/targets?page=2"}}
}'
expect_success "valid target collection page is accepted" \
  mf_oem_validate_collection_page "$TEST_TMP/page-with-next.json"
expect_success "same-origin relative pagination is accepted" \
  mf_oem_same_origin_next_url '/em/api/targets?page=2' '/em/api/targets'
expect_failure "cross-origin pagination is rejected" \
  mf_oem_same_origin_next_url 'https://evil.example/em/api/targets?page=2' '/em/api/targets'

MF_OEM_TMP_FILES=()
if mf_oem_new_temp_file permission_file \
   && [ "$(stat -c '%a' "$permission_file")" = 600 ]
then
  pass "REST temporary files are mode 600"
else
  fail "REST temporary files are mode 600"
fi
mf_oem_cleanup

if ! grep -Eq 'coveredTargets|fullCoverageBlackoutIds|stoppableFullCoverageBlackoutIds|mf_oem_append_json_array|mf_oem_build_blackout_coverage' "$HELPER" \
   && ! grep -Eq 'MF_OEM_BLACKOUT_STATE|mf_oem_(prepare|write)_state|timeToEnd|MLS_ID_GOLIVE_START|MF_OEM_LOOKUP_RESULT' "$HELPER" "$MAIN_SCRIPT" \
   && ! grep -F 'MF_${migration_id}' "$HELPER" >/dev/null
then
  pass "union coverage, obsolete persistence, scheduling policy, lookup globals, and non-canonical helper fallback are removed"
else
  fail "union coverage, obsolete persistence, scheduling policy, lookup globals, and non-canonical helper fallback are removed"
fi

if grep -F 'MF_OEM_MUTATION_ATTEMPTED:-N' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'MF_OEM_START_MUTATION_ATTEMPTED=Y' "$HELPER" >/dev/null \
   && grep -F 'MF_OEM_STOP_MUTATION_ATTEMPTED=Y' "$HELPER" >/dev/null \
   && grep -F 'MF_OEM_DELETE_MUTATION_ATTEMPTED=Y' "$HELPER" >/dev/null
then
  pass "main fallback is blocked after create, stop, or delete may have been attempted"
else
  fail "main fallback is blocked after create, stop, or delete may have been attempted"
fi

if grep -F 'select prj_name, peer_tclu_id' "$HELPER" >/dev/null \
   && ! grep -F 'connect by nocycle' "$HELPER" >/dev/null \
   && grep -F 'tc.real_name' "$HELPER" >/dev/null
then
  pass "REST discovery uses direct attempt/peer topology and target_clusters.real_name scope"
else
  fail "REST discovery uses direct attempt/peer topology and target_clusters.real_name scope"
fi

if grep -F 'while getopts :m:A:d:rQVnh opt' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'MF_OEM_BLACKOUT_NAME=MF_2_${cdb_name}_Migration' "$HELPER" >/dev/null \
   && grep -F 'start blackout MF_2_${CDB_NAME}_Migration \$(echo \"$targets\") -d $DURATION' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'grep MF_2.*${CDB_NAME}_Migration' "$MAIN_SCRIPT" >/dev/null
then
  pass "-r is opt-in and the original local emctl name, duration, and IS_ON commands remain"
else
  fail "-r is opt-in and the original local emctl name, duration, and IS_ON commands remain"
fi

apex_sources=(
  "$RELEASE_ROOT/repository/plsql/mf_apex_utils.pkb"
  "$RELEASE_ROOT/repository/fullDDL/060_package_mf_apex_utils.pks"
  "$RELEASE_ROOT/repository/fullDDL/061_package_body_mf_apex_utils.pkb"
)
for apex_source in "${apex_sources[@]}"
do
  if grep -F "rec.code || ' -A START ,Start local emctl Blackout'" "$apex_source" >/dev/null \
     && grep -F "rec.code || ' -r -A START ,Start OEM REST Blackout for 12 hours'" "$apex_source" >/dev/null \
     && ! grep -Ei 'go-live plus|GL\+12h|state.file' "$apex_source" >/dev/null
  then
    pass "APEX keeps separate local/REST actions with duration wording ($(basename "$apex_source"))"
  else
    fail "APEX keeps separate local/REST actions with duration wording ($(basename "$apex_source"))"
  fi
done

if grep -F 'if [ "$MF_BLACKOUT_ARGUMENT" = "-r" ]' "$UNSTABLE_SCRIPT" >/dev/null \
   && grep -F 'exec "$MF_BLACKOUT_SCRIPT_DIR/../bin/mfEmBlackout.sh" "$@"' "$UNSTABLE_SCRIPT" >/dev/null
then
  pass "unstable_bin routes advertised REST actions to the REST-capable stable entry point"
else
  fail "unstable_bin routes advertised REST actions to the REST-capable stable entry point"
fi

if grep -F 'args=(--config - --silent --show-error' "$HELPER" >/dev/null \
   && grep -F 'MF_OEM_API_BASE_URL must be an HTTPS origin' "$HELPER" >/dev/null \
   && ! grep -Eq -- '--insecure|-k([[:space:]]|$)' "$HELPER"
then
  pass "HTTPS, protected authentication, and TLS verification remain enforced"
else
  fail "HTTPS, protected authentication, and TLS verification remain enforced"
fi

printf 'tests: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
