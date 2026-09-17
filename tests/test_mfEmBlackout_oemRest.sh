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
  {"id":"rac-2","name":"exa2_CDBA_M2","typeName":"rac_database"},
  {"id":"pdb-2","name":"exa2_CDBA_M2_APP","typeName":"oracle_pdb"},
  {"id":"unrelated","name":"exa1_CDBA2_M1","typeName":"oracle_database"}
]'

expect_success "multiple database targets per cluster and all discovered PDBs are retained" \
  validate_discovery_fixture "$TEST_TMP/topology-two.json" "$TEST_TMP/targets-all.json" 8

mf_oem_filter_targets_by_topology "$TEST_TMP/topology-two.json" "$TEST_TMP/targets-all.json" \
  "$TEST_TMP/prefix-filter.json"
if jq -e '
     (.targets | map(.id) | index("unrelated")) != null and
     ([.targets[] | select(.typeName == "oracle_pdb")] | length) == 3 and
     ([.targets[] | select(.member.clusterId == "1" and .typeName == "oracle_database")] | length) == 3
   ' "$TEST_TMP/prefix-filter.json" >/dev/null
then
  pass "legacy target prefix matching behavior is preserved"
else
  fail "legacy target prefix matching behavior is preserved"
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

write_json "$TEST_TMP/targets-rac-only.json" '[
  {"id":"rac-1","name":"exa1_CDBA_M1","typeName":"rac_database"}
]'
expect_success "a RAC database target satisfies required cluster coverage" \
  validate_discovery_fixture "$TEST_TMP/topology-one.json" "$TEST_TMP/targets-rac-only.json" 1

write_json "$TEST_TMP/targets-empty.json" '[]'
expect_failure "empty discovery fails closed" \
  validate_discovery_fixture "$TEST_TMP/topology-one.json" "$TEST_TMP/targets-empty.json" 0

write_json "$TEST_TMP/targets-unrelated-only.json" '[
  {"id":"db-other","name":"exa1_CDBA2_M1","typeName":"oracle_database"}
]'
expect_success "legacy prefix matching accepts longer names that start with the CDB prefix" \
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
expect_failure "only oracle_database, rac_database, and oracle_pdb targets are accepted" \
  validate_discovery_fixture "$TEST_TMP/topology-one.json" "$TEST_TMP/targets-unsupported.json" 1

expect_success "direct attempt/peer topology fixture is valid" \
  mf_oem_validate_topology "$TEST_TMP/topology-two.json"

# -----------------------------------------------------------------------------
# Duration payload and OEM lifecycle status fixtures
# -----------------------------------------------------------------------------

expect_return "SCHEDULED remains transitional until STARTED is verified" 2 mf_oem_start_status_result SCHEDULED
expect_return "STARTED is an accepted START result" 0 mf_oem_start_status_result STARTED
expect_return "START_PROCESSING remains transitional" 2 mf_oem_start_status_result START_PROCESSING
expect_failure "START_PARTIAL is a failed START result" mf_oem_start_status_result START_PARTIAL

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
  {"id":"rac-1","name":"exa1_CDBA_M1","typeName":"rac_database","member":{"clusterId":"1","realName":"exa1"}},
  {"id":"pdb-1","name":"exa1_CDBA_M1_APP","typeName":"oracle_pdb","member":{"clusterId":"1","realName":"exa1"}}
]'
if mf_oem_build_payload MIG-42 "$TEST_TMP/payload-targets.json" '1 02:30' "$TEST_TMP/payload.json" \
   && jq -e '
        .name == "MF_2_CDBA_Migration" and
        .durationHours == 26 and
        .durationMinutes == 30 and
        (has("timeToEnd") | not) and
         .targets == [{"id":"db-1"},{"id":"rac-1"},{"id":"pdb-1"}]
      ' "$TEST_TMP/payload.json" >/dev/null
then
  pass "REST payload includes database, RAC database, and PDB target IDs"
else
  fail "REST payload includes database, RAC database, and PDB target IDs"
fi

write_json "$TEST_TMP/start-result.json" \
  '{"id":"BLACKOUT-1","name":"MF_2_CDBA_Migration","status":"STARTED","creationTimeToEnd":"2026-08-10T14:00+02:00"}'
if mf_oem_print_start_result "$TEST_TMP/start-result.json" 4 > "$TEST_TMP/start-result.out" \
   && [ "$(wc -l < "$TEST_TMP/start-result.out")" -eq 2 ] \
   && grep -F 'Blackout has been STARTED; all 4 discovered targets are covered' "$TEST_TMP/start-result.out" >/dev/null \
   && grep -F 'Blackout will end at (UTC): 2026-08-10T12:00Z' "$TEST_TMP/start-result.out" >/dev/null
then
  pass "START reports one status line and one OEM end-time line"
else
  fail "START reports one status line and one OEM end-time line"
fi

expect_success "HTTP 200 is accepted for GET" mf_oem_expect_http 200 200 "test request"
expect_success "HTTP 201 is accepted for create" mf_oem_expect_http 201 201 "test request"
expect_success "HTTP 204 is accepted for stop" mf_oem_expect_http 204 204 "test request"
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
if mf_oem_print_inspection "$TEST_TMP/inspection-zero.json" > "$TEST_TMP/inspection-zero.out" \
   && grep -F '2 discovered targets; 0 targets covered by the canonical blackout' "$TEST_TMP/inspection-zero.out" >/dev/null \
   && grep -F 'no canonical blackout exists; use START to create one' "$TEST_TMP/inspection-zero.out" >/dev/null
then
  pass "STATUS explains missing canonical coverage and the START action"
else
  fail "STATUS explains missing canonical coverage and the START action"
fi

write_json "$TEST_TMP/actual-full.json" '[
  {"id":"db-1","name":"renamed-display-value","typeName":"oracle_database"},
  {"id":"pdb-1","name":"another-display-value","typeName":"oracle_pdb"}
]'
write_json "$TEST_TMP/candidates-duplicate.json" '[
  {"id":"BLACKOUT-A","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf"},
  {"id":"BLACKOUT-B","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf"}
]'
write_json "$TEST_TMP/detail-blackout-a.json" \
  '{"id":"BLACKOUT-A","name":"MF_2_CDBA_Migration","status":"STARTED","creationTimeToEnd":"2026-08-10T14:00+02:00"}'
write_json "$TEST_TMP/detail-blackout-b.json" \
  '{"id":"BLACKOUT-B","name":"MF_2_CDBA_Migration","status":"STARTED","creationTimeToEnd":"2026-08-10T14:00+02:00"}'
if (
  mf_oem_get_blackout() {
    case "$1" in
      BLACKOUT-A) cp "$TEST_TMP/detail-blackout-a.json" "$2" ;;
      BLACKOUT-B) cp "$TEST_TMP/detail-blackout-b.json" "$2" ;;
      *) return 1 ;;
    esac
  }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-full.json" "$2"; }
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidates-duplicate.json" "$TEST_TMP/expected.json" \
    "$TEST_TMP/inspection-duplicate.json"
) && jq -e '.candidateCount == 2 and .startedCandidateCount == 2 and .exactStartedCandidateCount == 2 and .transitionalCandidateCount == 0' \
      "$TEST_TMP/inspection-duplicate.json" >/dev/null
then
  pass "duplicate STARTED IDs are independently verified without unioning coverage"
else
  fail "duplicate STARTED IDs are independently verified without unioning coverage"
fi

write_json "$TEST_TMP/candidates-started-terminal.json" '[
  {"id":"BLACKOUT-A","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf"},
  {"id":"BLACKOUT-T","name":"MF_2_CDBA_Migration","status":"STOPPED","type":"PATCHING","owner":"mf"}
]'
write_json "$TEST_TMP/detail-blackout-terminal.json" \
  '{"id":"BLACKOUT-T","name":"MF_2_CDBA_Migration","status":"STOPPED"}'
if (
  mf_oem_get_blackout() {
    case "$1" in
      BLACKOUT-A) cp "$TEST_TMP/detail-blackout-a.json" "$2" ;;
      BLACKOUT-T) cp "$TEST_TMP/detail-blackout-terminal.json" "$2" ;;
      *) return 1 ;;
    esac
  }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-full.json" "$2"; }
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidates-started-terminal.json" "$TEST_TMP/expected.json" \
    "$TEST_TMP/inspection-started-terminal.json"
) && jq -e '.candidateCount == 2 and .terminalCandidateCount == 1 and .exactStartedCandidateCount == 1 and .transitionalCandidateCount == 0' \
      "$TEST_TMP/inspection-started-terminal.json" >/dev/null
then
  pass "STOPPED duplicate is a historical record beside a verified STARTED blackout"
else
  fail "STOPPED duplicate is a historical record beside a verified STARTED blackout"
fi

write_json "$TEST_TMP/candidate-one.json" '[
  {"id":"BLACKOUT-1","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf"}
]'
write_json "$TEST_TMP/detail-started.json" \
  '{"id":"BLACKOUT-1","name":"MF_2_CDBA_Migration","status":"STARTED","creationTimeToEnd":"2026-08-10T14:00+02:00"}'
write_json "$TEST_TMP/detail-scheduled.json" \
  '{"id":"BLACKOUT-1","name":"MF_2_CDBA_Migration","status":"SCHEDULED"}'
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

if mf_oem_print_inspection "$TEST_TMP/inspection-one.json" > "$TEST_TMP/inspection-output.txt" \
   && grep -F 'all 2 discovered targets are covered by the blackout' "$TEST_TMP/inspection-output.txt" >/dev/null \
   && grep -F 'Blackout status       : STARTED' "$TEST_TMP/inspection-output.txt" >/dev/null \
   && grep -F 'Blackout will end at (UTC): 2026-08-10T12:00Z' "$TEST_TMP/inspection-output.txt" >/dev/null
then
  pass "inspection output reports complete coverage, status, and OEM end time"
else
  fail "inspection output reports complete coverage, status, and OEM end time"
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
if mf_oem_print_inspection "$TEST_TMP/inspection-incomplete.json" > "$TEST_TMP/inspection-incomplete.out" \
   && grep -F '2 discovered targets; 1 targets covered by the canonical blackout' "$TEST_TMP/inspection-incomplete.out" >/dev/null \
   && grep -F 'coverage is incomplete; use START to create a replacement blackout' "$TEST_TMP/inspection-incomplete.out" >/dev/null
then
  pass "STATUS directs incomplete canonical coverage to START reconciliation"
else
  fail "STATUS directs incomplete canonical coverage to START reconciliation"
fi

write_json "$TEST_TMP/candidate-stopped.json" '[
  {"id":"BLACKOUT-OLD","name":"MF_2_CDBA_Migration","status":"STOPPED","type":"PATCHING","owner":"mf"}
]'
write_json "$TEST_TMP/detail-stopped-old.json" \
  '{"id":"BLACKOUT-OLD","name":"MF_2_CDBA_Migration","status":"STOPPED"}'
if (
  mf_oem_get_blackout() { cp "$TEST_TMP/detail-stopped-old.json" "$2"; }
  mf_oem_fetch_blackout_targets() { return 99; }
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidate-stopped.json" "$TEST_TMP/expected.json" \
    "$TEST_TMP/inspection-terminal.json"
) && jq -e '
     .candidateCount == 1 and .blackoutId == "BLACKOUT-OLD" and
     .status == "STOPPED" and .terminal and (.exactTargetIds | not)
   ' "$TEST_TMP/inspection-terminal.json" >/dev/null
then
  pass "terminal canonical blackout is rediscovered by verified ID without requiring its targets endpoint"
else
  fail "terminal canonical blackout is rediscovered by verified ID without requiring its targets endpoint"
fi
if mf_oem_print_inspection "$TEST_TMP/inspection-terminal.json" > "$TEST_TMP/terminal-inspection-output.txt" \
   && grep -F 'no active canonical blackout; the STOPPED record is historical' \
         "$TEST_TMP/terminal-inspection-output.txt" >/dev/null \
   && grep -F 'use START to create a new blackout' \
         "$TEST_TMP/terminal-inspection-output.txt" >/dev/null
then
  pass "terminal records report as historical and do not require cleanup"
else
  fail "terminal records report as historical and do not require cleanup"
fi

if (
  mf_oem_get_blackout() { cp "$TEST_TMP/detail-scheduled.json" "$2"; }
  mf_oem_fetch_blackout_targets() { return 99; }
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidate-one.json" "$TEST_TMP/expected.json" \
    "$TEST_TMP/inspection-scheduled-no-targets.json"
) && jq -e '.status == "SCHEDULED" and (.exactTargetIds | not)' \
     "$TEST_TMP/inspection-scheduled-no-targets.json" >/dev/null
then
  pass "non-STARTED lifecycle records do not require a targets endpoint before replacement"
else
  fail "non-STARTED lifecycle records do not require a targets endpoint before replacement"
fi

# -----------------------------------------------------------------------------
# START semantics and mutation boundary fixtures
# -----------------------------------------------------------------------------

write_json "$TEST_TMP/inspection-scheduled.json" '{
  "candidateCount":1,"activeCandidateCount":1,"blackoutId":"BLACKOUT-1",
  "status":"SCHEDULED","exactTargetIds":false,"exactStartedCandidateCount":0,
  "inspectedCandidates":[{"id":"BLACKOUT-1","status":"SCHEDULED","exactTargetIds":false}],
  "expectedTargets":[]
}'
write_json "$TEST_TMP/create-response.json" \
  '{"id":"BLACKOUT-NEW","name":"MF_2_CDBA_Migration","status":"STARTED","creationTimeToEnd":"2026-08-10T14:00+02:00"}'
: > "$TEST_TMP/scheduled-start.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-one.json" "$6"
    cp "$TEST_TMP/inspection-scheduled.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_verify_blackout_targets() { [ "$1" = BLACKOUT-NEW ]; }
  mf_oem_http() {
    printf '%s\n' "$1" >> "$TEST_TMP/scheduled-start.log"
    cp "$TEST_TMP/create-response.json" "$3"; MF_OEM_HTTP_STATUS=201
  }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >/dev/null \
    && [ "$MF_OEM_START_MUTATION_ATTEMPTED" = Y ] \
    && [ "$(cat "$TEST_TMP/scheduled-start.log")" = POST ]
)
then
  pass "START creates a replacement when the only same-name blackout is SCHEDULED"
else
  fail "START creates a replacement when the only same-name blackout is SCHEDULED"
fi

write_json "$TEST_TMP/inspection-incomplete-start.json" '{
  "candidateCount":1,"activeCandidateCount":1,"blackoutId":"BLACKOUT-1",
  "status":"STARTED","exactTargetIds":false,"exactStartedCandidateCount":0,
  "inspectedCandidates":[{"id":"BLACKOUT-1","status":"STARTED","exactTargetIds":false}],
  "expectedTargets":[]
}'
: > "$TEST_TMP/incomplete-start.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-one.json" "$6"
    cp "$TEST_TMP/inspection-incomplete-start.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_verify_blackout_targets() { [ "$1" = BLACKOUT-NEW ]; }
  mf_oem_http() {
    printf '%s\n' "$1" >> "$TEST_TMP/incomplete-start.log"
    cp "$TEST_TMP/create-response.json" "$3"; MF_OEM_HTTP_STATUS=201
  }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >/dev/null \
    && [ "$MF_OEM_START_MUTATION_ATTEMPTED" = Y ] \
    && [ "$(cat "$TEST_TMP/incomplete-start.log")" = POST ]
)
then
  pass "START creates a replacement instead of mutating an incomplete STARTED blackout"
else
  fail "START creates a replacement instead of mutating an incomplete STARTED blackout"
fi

write_json "$TEST_TMP/inspection-create.json" '{
  "candidateCount":0,"activeCandidateCount":0,"exactStartedCandidateCount":0,
  "candidates":[],"inspectedCandidates":[],"exactTargetIds":false,
  "expectedTargets":[{"id":"db-1","name":"exa1_CDBA_M1","typeName":"oracle_database"}]
}'
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
  pass "zero exact-name candidates creates one complete STARTED blackout"
else
  fail "zero exact-name candidates creates one complete STARTED blackout"
fi

: > "$TEST_TMP/stale-snapshot-start.log"
if (
  MF_OEM_VERIFY_ATTEMPTS=2
  MF_OEM_VERIFY_INTERVAL=0
  MF_PREPARE_COUNT=0
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    MF_PREPARE_COUNT=$((MF_PREPARE_COUNT + 1))
    if [ "$MF_PREPARE_COUNT" -eq 1 ]
    then
      MF_OEM_EXACT_CANDIDATE_COUNT=1
      return 1
    fi
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-zero.json" "$6"
    cp "$TEST_TMP/inspection-create.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_verify_blackout_targets() { [ "$1" = BLACKOUT-NEW ]; }
  mf_oem_http() {
    printf '%s\n' "$1" >> "$TEST_TMP/stale-snapshot-start.log"
    cp "$TEST_TMP/create-response.json" "$3"; MF_OEM_HTTP_STATUS=201
  }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >/dev/null 2>&1 \
    && [ "$MF_PREPARE_COUNT" -eq 2 ] \
    && [ "$(cat "$TEST_TMP/stale-snapshot-start.log")" = POST ]
)
then
  pass "START retries a stale list/detail snapshot before proving absence and creating"
else
  fail "START retries a stale list/detail snapshot before proving absence and creating"
fi

: > "$TEST_TMP/unverified-snapshot-start.log"
if (
  MF_OEM_VERIFY_ATTEMPTS=2
  MF_OEM_VERIFY_INTERVAL=0
  MF_PREPARE_COUNT=0
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    MF_PREPARE_COUNT=$((MF_PREPARE_COUNT + 1))
    MF_OEM_EXACT_CANDIDATE_COUNT=1
    return 1
  }
  mf_oem_http() { printf 'POST\n' >> "$TEST_TMP/unverified-snapshot-start.log"; return 99; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >/dev/null 2>&1
  rc=$?
  [ "$rc" -eq 3 ] && [ "$MF_PREPARE_COUNT" -eq 2 ] \
    && [ ! -s "$TEST_TMP/unverified-snapshot-start.log" ]
)
then
  pass "START never creates when every pre-create snapshot remains incomplete"
else
  fail "START never creates when every pre-create snapshot remains incomplete"
fi

: > "$TEST_TMP/reuse-sequence.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-stopped.json" "$6"
    cp "$TEST_TMP/inspection-terminal.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_verify_blackout_targets() { [ "$1" = BLACKOUT-NEW ]; }
  mf_oem_http() {
    case "$1 $2" in
      "POST https://oms.example:7803/em/api/blackouts")
        printf 'POST_CREATE %s\n' "$2" >> "$TEST_TMP/reuse-sequence.log"
        cp "$TEST_TMP/create-response.json" "$3"; MF_OEM_HTTP_STATUS=201 ;;
      *) return 1 ;;
    esac
  }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >/dev/null 2>&1 \
    && [ "$MF_OEM_START_MUTATION_ATTEMPTED" = Y ] \
    && [ "$(sed -n '1p' "$TEST_TMP/reuse-sequence.log")" = \
         "POST_CREATE https://oms.example:7803/em/api/blackouts" ] \
    && [ "$(wc -l < "$TEST_TMP/reuse-sequence.log" | tr -d ' ')" -eq 1 ]
)
then
  pass "START treats one terminal canonical ID as historical and creates the same name without DELETE"
else
  fail "START treats one terminal canonical ID as historical and creates the same name without DELETE"
fi

write_json "$TEST_TMP/inspection-ended.json" '{
  "candidateCount":1,"activeCandidateCount":0,"blackoutId":"BLACKOUT-ENDED",
  "status":"ENDED","terminal":true,"exactTargetIds":false,"exactStartedCandidateCount":0,
  "inspectedCandidates":[{"id":"BLACKOUT-ENDED","status":"ENDED","exactTargetIds":false}],
  "expectedTargets":[]
}'
: > "$TEST_TMP/ended-start.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-stopped.json" "$6"
    cp "$TEST_TMP/inspection-ended.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_verify_blackout_targets() { [ "$1" = BLACKOUT-NEW ]; }
  mf_oem_http() {
    printf '%s\n' "$1" >> "$TEST_TMP/ended-start.log"
    cp "$TEST_TMP/create-response.json" "$3"; MF_OEM_HTTP_STATUS=201
  }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 02:00 >/dev/null 2>&1 \
    && [ "$(cat "$TEST_TMP/ended-start.log")" = POST ]
)
then
  pass "ENDED history does not block a fresh two-hour START after GO-LIVE"
else
  fail "ENDED history does not block a fresh two-hour START after GO-LIVE"
fi

write_json "$TEST_TMP/inspection-stop-pending.json" '{
  "candidateCount":1,"activeCandidateCount":1,"blackoutId":"BLACKOUT-OLD",
  "status":"STOP_PENDING","exactTargetIds":false,"exactStartedCandidateCount":0,
  "inspectedCandidates":[{"id":"BLACKOUT-OLD","status":"STOP_PENDING","exactTargetIds":false}],
  "expectedTargets":[]
}'
write_json "$TEST_TMP/detail-stop-pending.json" \
  '{"id":"BLACKOUT-OLD","name":"MF_2_CDBA_Migration","status":"STOP_PENDING"}'
: > "$TEST_TMP/pending-recovery-sequence.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-stopped.json" "$6"
    cp "$TEST_TMP/inspection-stop-pending.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_verify_blackout_targets() { [ "$1" = BLACKOUT-NEW ]; }
  mf_oem_http() {
    case "$1 $2" in
      "POST https://oms.example:7803/em/api/blackouts")
        printf 'POST_CREATE %s\n' "$2" >> "$TEST_TMP/pending-recovery-sequence.log"
        cp "$TEST_TMP/create-response.json" "$3"; MF_OEM_HTTP_STATUS=201 ;;
      *) return 1 ;;
    esac
  }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >/dev/null 2>&1 \
    && [ "$(cat "$TEST_TMP/pending-recovery-sequence.log")" = \
         "POST_CREATE https://oms.example:7803/em/api/blackouts" ]
)
then
  pass "START creates a replacement without deleting or polling a STOP_PENDING record"
else
  fail "START creates a replacement without deleting or polling a STOP_PENDING record"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-zero.json" "$6"
    cp "$TEST_TMP/inspection-create.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_reconcile_started_blackouts() { return 1; }
  mf_oem_http() { return 1; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >/dev/null 2>&1
  rc=$?
  [ "$rc" -ne 0 ] && [ "$MF_OEM_START_MUTATION_ATTEMPTED" = Y ] \
    && [ "$MF_OEM_MUTATION_ATTEMPTED" = Y ]
)
then
  pass "uncertain create fails when reconciliation cannot prove exact STARTED coverage"
else
  fail "uncertain create fails when reconciliation cannot prove exact STARTED coverage"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-zero.json" "$6"
    cp "$TEST_TMP/inspection-create.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_http() { return 1; }
  mf_oem_reconcile_started_blackouts() { printf 'reconciled\n' > "$TEST_TMP/reconciled.log"; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >/dev/null 2>&1 \
    && [ "$(cat "$TEST_TMP/reconciled.log")" = reconciled ]
)
then
  pass "lost create response succeeds only after reconciliation proves an exact STARTED blackout"
else
  fail "lost create response succeeds only after reconciliation proves an exact STARTED blackout"
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

write_json "$TEST_TMP/inspection-started-with-transition.json" '{
  "candidateCount":2,"activeCandidateCount":2,"exactStartedCandidateCount":1,
  "transitionalCandidateCount":1,"expectedTargets":[],"actualTargets":[],
  "candidates":[{"name":"MF_2_CDBA_Migration"}],
  "inspectedCandidates":[
    {"id":"BLACKOUT-1","status":"STARTED","exactTargetIds":true},
    {"id":"BLACKOUT-OLD","status":"STOP_PENDING","exactTargetIds":false}
  ]
}'
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-duplicate.json" "$6"
    cp "$TEST_TMP/inspection-started-with-transition.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_http() { return 99; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 12:00 >"$TEST_TMP/reused-with-clutter.out" 2>&1 \
    && [ "$MF_OEM_START_MUTATION_ATTEMPTED" = N ] \
    && grep -F 'Using STARTED blackout BLACKOUT-1 with exact target coverage' \
         "$TEST_TMP/reused-with-clutter.out" >/dev/null
)
then
  pass "START reuses an exact STARTED blackout despite lifecycle clutter"
else
  fail "START reuses an exact STARTED blackout despite lifecycle clutter"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-duplicate.json" "$6"
    cp "$TEST_TMP/inspection-started-with-transition.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_is_blackout_on MIG-42 42 CDBA CDBA_M1 >/dev/null 2>&1
)
then
  pass "IS_ON is true when an exact STARTED blackout exists despite lifecycle clutter"
else
  fail "IS_ON is true when an exact STARTED blackout exists despite lifecycle clutter"
fi

# -----------------------------------------------------------------------------
# STOP fixtures
# -----------------------------------------------------------------------------

write_json "$TEST_TMP/inspection-started.json" '{
  "candidateCount":1,"activeCandidateCount":1,"blackoutId":"BLACKOUT-1",
  "status":"STARTED","exactTargetIds":true,"expectedTargets":[]
}'
: > "$TEST_TMP/stop-sequence.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-one.json" "$6"
    cp "$TEST_TMP/inspection-started.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_get_blackout() { cp "$TEST_TMP/detail-started.json" "$2"; }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-full.json" "$2"; }
  mf_oem_http() {
    [ "$1 $2" = "POST https://oms.example:7803/em/api/blackouts/BLACKOUT-1/actions/stop" ] \
      || return 1
    printf 'POST_STOP %s\n' "$2" >> "$TEST_TMP/stop-sequence.log"
    : > "$3"; MF_OEM_HTTP_STATUS=204
  }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null \
    && [ "$MF_OEM_STOP_MUTATION_ATTEMPTED" = Y ] \
    && [ "$(sed -n '1p' "$TEST_TMP/stop-sequence.log")" = \
         "POST_STOP https://oms.example:7803/em/api/blackouts/BLACKOUT-1/actions/stop" ] \
    && [ "$(wc -l < "$TEST_TMP/stop-sequence.log" | tr -d ' ')" -eq 1 ]
)
then
  pass "STOP verifies one STARTED ID, submits stop, and returns without polling or DELETE"
else
  fail "STOP verifies one STARTED ID, submits stop, and returns without polling or DELETE"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-one.json" "$6"
    cp "$TEST_TMP/inspection-started.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_get_blackout() { cp "$TEST_TMP/detail-started.json" "$2"; }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-full.json" "$2"; }
  mf_oem_http() { return 1; }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null 2>&1
  rc=$?
  [ "$rc" -ne 0 ] \
    && [ "$MF_OEM_STOP_MUTATION_ATTEMPTED" = Y ] \
    && [ "$MF_OEM_MUTATION_ATTEMPTED" = Y ]
)
then
  pass "uncertain stop response is mutation-guarded but never followed by DELETE or emctl fallback"
else
  fail "uncertain stop response is mutation-guarded but never followed by DELETE or emctl fallback"
fi

: > "$TEST_TMP/changed-target-stop.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-one.json" "$6"
    cp "$TEST_TMP/inspection-started.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_get_blackout() { cp "$TEST_TMP/detail-started.json" "$2"; }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-incomplete.json" "$2"; }
  mf_oem_http() { printf 'called\n' >> "$TEST_TMP/changed-target-stop.log"; return 99; }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null 2>&1
  rc=$?
  [ "$rc" -ne 0 ] && [ ! -s "$TEST_TMP/changed-target-stop.log" ]
)
then
  pass "STOP fails closed before mutation when target coverage changes"
else
  fail "STOP fails closed before mutation when target coverage changes"
fi

: > "$TEST_TMP/partial-stop.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-duplicate.json" "$6"
    cp "$TEST_TMP/inspection-duplicate.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_get_blackout() {
    case "$1" in
      BLACKOUT-A) cp "$TEST_TMP/detail-blackout-a.json" "$2" ;;
      BLACKOUT-B) cp "$TEST_TMP/detail-blackout-b.json" "$2" ;;
      *) return 1 ;;
    esac
  }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-full.json" "$2"; }
  mf_oem_http() {
    printf '%s\n' "$2" >> "$TEST_TMP/partial-stop.log"
    case "$2" in
      *BLACKOUT-A/actions/stop) return 1 ;;
      *BLACKOUT-B/actions/stop) : > "$3"; MF_OEM_HTTP_STATUS=204 ;;
      *) return 1 ;;
    esac
  }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null 2>&1
  rc=$?
  [ "$rc" -ne 0 ] && [ "$(wc -l < "$TEST_TMP/partial-stop.log" | tr -d ' ')" -eq 2 ]
)
then
  pass "partial duplicate STOP continues later IDs and returns nonzero for an unverified result"
else
  fail "partial duplicate STOP continues later IDs and returns nonzero for an unverified result"
fi

write_json "$TEST_TMP/detail-blackout-a-pending.json" \
  '{"id":"BLACKOUT-A","name":"MF_2_CDBA_Migration","status":"STOP_PENDING"}'
: > "$TEST_TMP/reconciled-stop.log"
if (
  MF_A_GET_COUNT=0
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-duplicate.json" "$6"
    cp "$TEST_TMP/inspection-duplicate.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_get_blackout() {
    case "$1" in
      BLACKOUT-A)
        MF_A_GET_COUNT=$((MF_A_GET_COUNT + 1))
        if [ "$MF_A_GET_COUNT" -eq 1 ]
        then cp "$TEST_TMP/detail-blackout-a.json" "$2"
        else cp "$TEST_TMP/detail-blackout-a-pending.json" "$2"
        fi
        ;;
      BLACKOUT-B) cp "$TEST_TMP/detail-blackout-b.json" "$2" ;;
      *) return 1 ;;
    esac
  }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-full.json" "$2"; }
  mf_oem_http() {
    printf '%s\n' "$2" >> "$TEST_TMP/reconciled-stop.log"
    case "$2" in
      *BLACKOUT-A/actions/stop) return 1 ;;
      *BLACKOUT-B/actions/stop) : > "$3"; MF_OEM_HTTP_STATUS=204 ;;
      *) return 1 ;;
    esac
  }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null 2>&1 \
    && [ "$MF_A_GET_COUNT" -eq 2 ] \
    && [ "$(wc -l < "$TEST_TMP/reconciled-stop.log" | tr -d ' ')" -eq 2 ]
)
then
  pass "lost duplicate STOP response reconciles by ID and fan-out continues"
else
  fail "lost duplicate STOP response reconciles by ID and fan-out continues"
fi

write_json "$TEST_TMP/inspection-started-pending.json" '{
  "candidateCount":2,"activeCandidateCount":2,"startedCandidateCount":1,
  "exactStartedCandidateCount":1,"transitionalCandidateCount":1,
  "candidates":[{"name":"MF_2_CDBA_Migration"}],
  "inspectedCandidates":[
    {"id":"BLACKOUT-A","status":"STOP_PENDING","terminal":false,"exactTargetIds":false},
    {"id":"BLACKOUT-B","status":"STARTED","terminal":false,"exactTargetIds":true}
  ],
  "expectedTargets":[]
}'
if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-duplicate.json" "$6"
    cp "$TEST_TMP/inspection-started-pending.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_get_blackout() { [ "$1" = BLACKOUT-B ] && cp "$TEST_TMP/detail-blackout-b.json" "$2"; }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-full.json" "$2"; }
  mf_oem_http() {
    [ "$2" = "https://oms.example:7803/em/api/blackouts/BLACKOUT-B/actions/stop" ] || return 1
    : > "$3"; MF_OEM_HTTP_STATUS=204
  }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null
)
then
  pass "STOP retry ignores a prior STOP_PENDING duplicate and stops the remaining exact STARTED ID"
else
  fail "STOP retry ignores a prior STOP_PENDING duplicate and stops the remaining exact STARTED ID"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-stopped.json" "$6"
    cp "$TEST_TMP/inspection-terminal.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_http() { return 99; }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >"$TEST_TMP/terminal-stop.out" 2>&1 \
    && grep -F 'Blackout has been STOPPED and is treated as a historical record' "$TEST_TMP/terminal-stop.out" >/dev/null
)
then
  pass "repeated STOP treats a terminal blackout as complete without cleanup"
else
  fail "repeated STOP treats a terminal blackout as complete without cleanup"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidate-one.json" "$6"
    cp "$TEST_TMP/inspection-stop-pending.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_http() { return 99; }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >"$TEST_TMP/pending-stop.out" 2>&1 \
    && [ "$MF_OEM_STOP_MUTATION_ATTEMPTED" = N ] \
    && grep -F 'Blackout has been STOP_PENDING; STOP remains non-blocking' "$TEST_TMP/pending-stop.out" >/dev/null
)
then
  pass "repeated STOP on STOP_PENDING is a non-blocking no-op"
else
  fail "repeated STOP on STOP_PENDING is a non-blocking no-op"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-zero.json" "$6"
    cp "$TEST_TMP/inspection-create.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_http() { return 99; }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >"$TEST_TMP/stop-absent.out" 2>&1 \
    && grep -F 'STOP is already complete' "$TEST_TMP/stop-absent.out" >/dev/null
)
then
  pass "STOP is idempotent when no exact canonical blackout remains"
else
  fail "STOP is idempotent when no exact canonical blackout remains"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_prepare_inspection() {
    : > "$4"; cp "$TEST_TMP/expected.json" "$5"; cp "$TEST_TMP/candidates-duplicate.json" "$6"
    cp "$TEST_TMP/inspection-duplicate.json" "$7"
  }
  mf_oem_print_inspection() { :; }
  mf_oem_get_blackout() {
    case "$1" in
      BLACKOUT-A) cp "$TEST_TMP/detail-blackout-a.json" "$2" ;;
      BLACKOUT-B) cp "$TEST_TMP/detail-blackout-b.json" "$2" ;;
      *) return 1 ;;
    esac
  }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-full.json" "$2"; }
  mf_oem_http() {
    case "$2" in
      *BLACKOUT-A/actions/stop|*BLACKOUT-B/actions/stop) : > "$3"; MF_OEM_HTTP_STATUS=204 ;;
      *) return 1 ;;
    esac
  }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null \
    && [ "$MF_OEM_MUTATION_ATTEMPTED" = Y ]
)
then
  pass "STOP requests a stop for every verified duplicate STARTED ID"
else
  fail "STOP requests a stop for every verified duplicate STARTED ID"
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
   && ! grep -Eq 'MF_OEM_BLACKOUT_STATE|mf_oem_(prepare|write)_state|MF_OEM_LOOKUP_RESULT' "$HELPER" \
   && ! grep -F 'MF_${migration_id}' "$HELPER" >/dev/null
then
  pass "union coverage, obsolete persistence, lookup globals, and non-canonical helper fallback are removed"
else
  fail "union coverage, obsolete persistence, lookup globals, and non-canonical helper fallback are removed"
fi

if grep -F 'MF_OEM_START_MUTATION_ATTEMPTED=Y' "$HELPER" >/dev/null \
   && grep -F 'MF_OEM_STOP_MUTATION_ATTEMPTED=Y' "$HELPER" >/dev/null \
   && grep -F 'no local fallback was attempted' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'mf_oem_reconcile_started_blackouts' "$HELPER" >/dev/null \
   && ! grep -F 'mf_oem_http PATCH' "$HELPER" >/dev/null \
   && ! grep -F 'mf_oem_http DELETE' "$HELPER" >/dev/null \
   && ! grep -F 'MF_OEM_STOP_PENDING_TIMEOUT' "$HELPER" >/dev/null
then
  pass "START creates or reconciles exact STARTED coverage without PATCH, DELETE, or emctl fallback"
else
  fail "START creates or reconciles exact STARTED coverage without PATCH, DELETE, or emctl fallback"
fi

workflow_callers=(
  "$RELEASE_ROOT/bin/mfDbActions.sh"
  "$RELEASE_ROOT/bin/mfCreateTargetPDB.sh"
  "$RELEASE_ROOT/bin/mfUpdateparams.sh"
  "$RELEASE_ROOT/unstable_bin/mfDbActions.sh"
  "$RELEASE_ROOT/unstable_bin/mfCreateTargetPDB.sh"
  "$RELEASE_ROOT/unstable_bin/mfUpdateparams.sh"
)
for caller in "${workflow_callers[@]}"
do
  if grep -F 'mfEmBlackout.sh -m $MF_MIGRATION_ID -r -A START' "$caller" >/dev/null \
     && grep -F 'die "Unable to create blackout"' "$caller" >/dev/null
  then
    pass "$(basename "$caller") keeps nonzero REST START fatal"
  else
    fail "$(basename "$caller") keeps nonzero REST START fatal"
  fi
done

if grep -F 'select prj_name, peer_tclu_id' "$HELPER" >/dev/null \
   && ! grep -F 'connect by nocycle' "$HELPER" >/dev/null \
   && grep -F 'tc.real_name' "$HELPER" >/dev/null
then
  pass "REST discovery uses direct attempt/peer topology and target_clusters.real_name scope"
else
  fail "REST discovery uses direct attempt/peer topology and target_clusters.real_name scope"
fi

if grep -F 'while getopts :m:A:d:rQVnh opt' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'USE_REST_API=N' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'DURATION_EXPLICIT=N' "$MAIN_SCRIPT" >/dev/null \
   && grep -F "when min(target_date) <= sysdate then '02:00'" "$MAIN_SCRIPT" >/dev/null \
   && grep -F "interval '2' hour" "$MAIN_SCRIPT" >/dev/null \
   && grep -F "'MLS_ID_GOLIVE_START'" "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'Omit -d to use the planned GO-LIVE' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'pass -d only to override that duration.' "$MAIN_SCRIPT" >/dev/null \
   && ! grep -F 'For REST START, pass -d explicitly.' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'MF_OEM_BLACKOUT_NAME=MF_2_${cdb_name}_Migration' "$HELPER" >/dev/null \
   && grep -F 'start blackout MF_2_${CDB_NAME}_Migration \$(echo \"$targets\") -d $DURATION' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'grep MF_2.*${CDB_NAME}_Migration' "$MAIN_SCRIPT" >/dev/null
then
  pass "-r is opt-in; REST START defaults to planned GO-LIVE + 2h while local emctl stays compatible"
else
  fail "-r is opt-in; REST START defaults to planned GO-LIVE + 2h while local emctl stays compatible"
fi

constants_sources=(
  "$RELEASE_ROOT/bin/mfUtils_99_constants.sh.example"
  "$RELEASE_ROOT/unstable_bin/mfUtils_99_constants.sh.example"
)
for constants_source in "${constants_sources[@]}"
do
  if grep -F 'MF_OEM_API_BASE_URL' "$constants_source" >/dev/null \
     && grep -F 'WEB_USER|OEM_REST_API' "$constants_source" >/dev/null
  then
    pass "REST configuration is available from $(basename "$(dirname "$constants_source")")"
  else
    fail "REST configuration is available from $(basename "$(dirname "$constants_source")")"
  fi
done

apex_sources=(
  "$RELEASE_ROOT/repository/plsql/mf_apex_utils.pkb"
  "$RELEASE_ROOT/repository/fullDDL/060_package_mf_apex_utils.pks"
  "$RELEASE_ROOT/repository/fullDDL/061_package_body_mf_apex_utils.pkb"
)
for apex_source in "${apex_sources[@]}"
do
  if ! grep -F "Start local emctl Blackout" "$apex_source" >/dev/null \
     && grep -F "rec.code || ' -r -A START ,Start OEM REST Blackout until planned GO-LIVE plus 2 hours'" "$apex_source" >/dev/null \
     && grep -F 'Start (GO-LIVE + 2h)</A>' "$apex_source" >/dev/null \
     && ! grep -Ei 'GL\+12h|state.file' "$apex_source" >/dev/null
  then
    pass "APEX exposes only the opt-in REST actions with GO-LIVE + 2h wording ($(basename "$apex_source"))"
  else
    fail "APEX exposes only the opt-in REST actions with GO-LIVE + 2h wording ($(basename "$apex_source"))"
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
