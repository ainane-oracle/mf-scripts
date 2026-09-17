#!/usr/bin/env bash

# Offline fixture tests for the opt-in OEM REST blackout workflow.
# No OEM, database, Migration Factory, APEX endpoint, or credential store is contacted.

set -u

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RELEASE_ROOT=$(cd "$TEST_DIR/.." && pwd)
HELPER="$RELEASE_ROOT/bin/mfEmBlackout_oemRest.sh"
MAIN_SCRIPT="$RELEASE_ROOT/bin/mfEmBlackout.sh"
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

FIXED_NOW=$(date -u -d '2026-08-10T12:00+02:00' '+%s')
FIXED_REQUIRED_END=$(date -u -d '2026-08-10T14:00+02:00' '+%s')

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

set_fixed_window()
{
  MF_OEM_NOW_EPOCH=$FIXED_NOW
  MF_OEM_REQUIRED_END_EPOCH=$FIXED_REQUIRED_END
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
# Target discovery and topology regression fixtures
# -----------------------------------------------------------------------------

write_json "$TEST_TMP/topology-two.json" '{
  "cdbName":"CDBA","targetContainerService":"CDBA_M1","startClusterId":"1",
  "clusters":[{"clusterId":"1","realName":"exa1"},{"clusterId":"2","realName":"exa2"}]
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

write_json "$TEST_TMP/topology-one.json" '{
  "cdbName":"CDBA","targetContainerService":"CDBA_M1","startClusterId":"1",
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

write_json "$TEST_TMP/targets-unsupported.json" '[
  {"id":"host-1","name":"exa1_CDBA_M1","typeName":"host"}
]'
expect_failure "unsupported target types fail closed" \
  validate_discovery_fixture "$TEST_TMP/topology-one.json" "$TEST_TMP/targets-unsupported.json" 1

expect_success "direct attempt/peer topology fixture is valid" \
  mf_oem_validate_topology "$TEST_TMP/topology-two.json"

# -----------------------------------------------------------------------------
# Name family, duration, and payload
# -----------------------------------------------------------------------------

expect_success "the exact canonical name is managed" \
  mf_oem_is_managed_blackout_name MF_2_CDBA_Migration
expect_success "a strict UTC timestamp suffix is managed" \
  mf_oem_is_managed_blackout_name MF_2_CDBA_Migration_20260917T130405Z
expect_failure "an arbitrary suffix is not part of the managed family" \
  mf_oem_is_managed_blackout_name MF_2_CDBA_Migration_manual
expect_failure "a similar CDB name is not part of the managed family" \
  mf_oem_is_managed_blackout_name MF_2_CDBA2_Migration

write_json "$TEST_TMP/all-names.json" '[
  {"id":"BASE","name":"MF_2_CDBA_Migration","status":"ENDED","type":"PATCHING","owner":"mf"},
  {"id":"STAMP","name":"MF_2_CDBA_Migration_20260917T130405Z","status":"STARTED","type":"PATCHING","owner":"mf"},
  {"id":"MANUAL","name":"MF_2_CDBA_Migration_manual","status":"STARTED","type":"PATCHING","owner":"operator"},
  {"id":"OTHER","name":"MF_2_CDBA2_Migration","status":"STARTED","type":"PATCHING","owner":"operator"}
]'
if (
  mf_oem_fetch_blackout_pages() { cp "$TEST_TMP/all-names.json" "$2"; }
  mf_oem_find_exact_blackouts "$TEST_TMP/managed.json" "$TEST_TMP/ignored.json" >/dev/null 2>&1
) && jq -e '(map(.id) | sort) == ["BASE","STAMP"]' "$TEST_TMP/managed.json" >/dev/null \
   && jq -e 'map(.id) == ["MANUAL"]' "$TEST_TMP/ignored.json" >/dev/null
then
  pass "lookup selects only the exact base and strict timestamp family"
else
  fail "lookup selects only the exact base and strict timestamp family"
fi

if [ "$(mf_oem_parse_duration '12:00')" = "12|0" ] \
   && [ "$(mf_oem_parse_duration '1 02:30')" = "26|30" ]
then
  pass "REST duration accepts legacy hour and day-hour formats"
else
  fail "REST duration accepts legacy hour and day-hour formats"
fi
expect_failure "zero duration is rejected" mf_oem_parse_duration '00:00'
expect_failure "invalid minutes are rejected" mf_oem_parse_duration '02:60'

write_json "$TEST_TMP/targets.json" '[
  {"id":"db-1","name":"exa1_CDBA_M1","typeName":"oracle_database"},
  {"id":"pdb-1","name":"exa1_CDBA_M1_APP","typeName":"oracle_pdb"}
]'
if mf_oem_build_payload MIG-42 "$TEST_TMP/targets.json" '02:30' \
     "$TEST_TMP/payload.json" MF_2_CDBA_Migration_20260917T130405Z \
   && jq -e '
     .name == "MF_2_CDBA_Migration_20260917T130405Z" and
     .durationHours == 2 and .durationMinutes == 30 and
     .targets == [{"id":"db-1"},{"id":"pdb-1"}]
   ' "$TEST_TMP/payload.json" >/dev/null
then
  pass "payload supports an explicit managed create name and exact target IDs"
else
  fail "payload supports an explicit managed create name and exact target IDs"
fi

write_json "$TEST_TMP/name-conflict.json" '{"message":"A blackout with this name already exists"}'
write_json "$TEST_TMP/not-name-conflict.json" '{"message":"Target validation failed"}'
expect_success "HTTP 409 with an explicit duplicate-name message enables suffix fallback" \
  mf_oem_is_explicit_name_conflict 409 "$TEST_TMP/name-conflict.json"
expect_failure "HTTP 409 without a name conflict does not enable suffix fallback" \
  mf_oem_is_explicit_name_conflict 409 "$TEST_TMP/not-name-conflict.json"
expect_failure "network-style status 000 does not enable suffix fallback" \
  mf_oem_is_explicit_name_conflict 000 "$TEST_TMP/name-conflict.json"

# -----------------------------------------------------------------------------
# Per-ID target and time qualification
# -----------------------------------------------------------------------------

write_json "$TEST_TMP/candidates-duplicate.json" '[
  {"id":"BLACKOUT-A","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf"},
  {"id":"BLACKOUT-B","name":"MF_2_CDBA_Migration_20260917T130405Z","status":"STARTED","type":"PATCHING","owner":"mf"}
]'
write_json "$TEST_TMP/detail-a.json" '{
  "id":"BLACKOUT-A","name":"MF_2_CDBA_Migration","status":"STARTED",
  "creationTimeToStart":"2026-08-10T11:00+02:00","creationTimeToEnd":"2026-08-10T15:00+02:00"
}'
write_json "$TEST_TMP/detail-b.json" '{
  "id":"BLACKOUT-B","name":"MF_2_CDBA_Migration_20260917T130405Z","status":"STARTED",
  "creationTimeToStart":"2026-08-10T11:30+02:00","creationTimeToEnd":"2026-08-10T14:30+02:00"
}'
write_json "$TEST_TMP/actual-exact.json" '[{"id":"pdb-1"},{"id":"db-1"}]'
write_json "$TEST_TMP/actual-partial.json" '[{"id":"db-1"}]'

if (
  set_fixed_window
  mf_oem_get_blackout() {
    case "$1" in
      BLACKOUT-A) cp "$TEST_TMP/detail-a.json" "$2" ;;
      BLACKOUT-B) cp "$TEST_TMP/detail-b.json" "$2" ;;
      *) return 1 ;;
    esac
  }
  mf_oem_fetch_blackout_targets() {
    case "$1" in
      BLACKOUT-A) cp "$TEST_TMP/actual-exact.json" "$2" ;;
      BLACKOUT-B) cp "$TEST_TMP/actual-exact.json" "$2" ;;
      *) return 1 ;;
    esac
  }
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidates-duplicate.json" \
    "$TEST_TMP/targets.json" "$TEST_TMP/inspection-duplicate.json"
) && jq -e '
  .candidateCount == 2 and
  .qualifyingCandidateCount == 2 and
  .exactStartedCandidateCount == 2 and
  .blockingCandidateCount == 0
' "$TEST_TMP/inspection-duplicate.json" >/dev/null
then
  pass "duplicate STARTED records are accepted only after each qualifies independently"
else
  fail "duplicate STARTED records are accepted only after each qualifies independently"
fi

if mf_oem_print_start_candidates "$TEST_TMP/inspection-duplicate.json" \
     > "$TEST_TMP/start-duplicates.out" \
   && mf_oem_print_inspection "$TEST_TMP/inspection-duplicate.json" \
     > "$TEST_TMP/is-on-duplicates.out" \
   && grep -F 'WARNING: Found 2 managed OEM blackout records.' \
        "$TEST_TMP/start-duplicates.out" >/dev/null \
   && grep -F 'WARNING: Found 2 managed blackout records; each ID was verified independently.' \
        "$TEST_TMP/is-on-duplicates.out" >/dev/null
then
  pass "START and IS_ON warn when accepted STARTED duplicates exist"
else
  fail "START and IS_ON warn when accepted STARTED duplicates exist"
fi

if (
  set_fixed_window
  mf_oem_get_blackout() { cp "$TEST_TMP/detail-a.json" "$2"; }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-partial.json" "$2"; }
  printf '[{"id":"BLACKOUT-A","name":"MF_2_CDBA_Migration","status":"STARTED"}]\n' \
    > "$TEST_TMP/candidate-mismatched.json"
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidate-mismatched.json" \
    "$TEST_TMP/targets.json" "$TEST_TMP/inspection-mismatched.json"
) && jq -e '
  .qualifyingCandidateCount == 0 and .mismatchedStartedCandidateCount == 1 and
  .blockingCandidateCount == 1
' "$TEST_TMP/inspection-mismatched.json" >/dev/null
then
  pass "a STARTED target mismatch is a fail-closed blocker"
else
  fail "a STARTED target mismatch is a fail-closed blocker"
fi

write_json "$TEST_TMP/detail-missing-time.json" \
  '{"id":"BLACKOUT-A","name":"MF_2_CDBA_Migration","status":"STARTED"}'
if (
  set_fixed_window
  mf_oem_get_blackout() { cp "$TEST_TMP/detail-missing-time.json" "$2"; }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-exact.json" "$2"; }
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidate-mismatched.json" \
    "$TEST_TMP/targets.json" "$TEST_TMP/inspection-missing-time.json"
) && jq -e '
  .unverifiableStartedCandidateCount == 1 and .blockingCandidateCount == 1
' "$TEST_TMP/inspection-missing-time.json" >/dev/null
then
  pass "a STARTED record without verifiable start/end times fails closed"
else
  fail "a STARTED record without verifiable start/end times fails closed"
fi

write_json "$TEST_TMP/candidates-started-terminal.json" '[
  {"id":"BLACKOUT-A","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf"},
  {"id":"BLACKOUT-HISTORY","name":"MF_2_CDBA_Migration","status":"ENDED","type":"PATCHING","owner":"mf"}
]'
write_json "$TEST_TMP/detail-history.json" '{
  "id":"BLACKOUT-HISTORY","name":"MF_2_CDBA_Migration","status":"ENDED",
  "creationTimeToStart":"2026-08-09T10:00+02:00","creationTimeToEnd":"2026-08-09T12:00+02:00"
}'
if (
  set_fixed_window
  mf_oem_get_blackout() {
    case "$1" in
      BLACKOUT-A) cp "$TEST_TMP/detail-a.json" "$2" ;;
      BLACKOUT-HISTORY) cp "$TEST_TMP/detail-history.json" "$2" ;;
      *) return 1 ;;
    esac
  }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-exact.json" "$2"; }
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidates-started-terminal.json" \
    "$TEST_TMP/targets.json" "$TEST_TMP/inspection-started-terminal.json"
) && jq -e '
  .qualifyingCandidateCount == 1 and .terminalCandidateCount == 1 and
  .transitionalCandidateCount == 0
' "$TEST_TMP/inspection-started-terminal.json" >/dev/null
then
  pass "STARTED plus terminal history remains ON"
else
  fail "STARTED plus terminal history remains ON"
fi

write_json "$TEST_TMP/candidate-short.json" '[
  {"id":"BLACKOUT-SHORT","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf"}
]'
write_json "$TEST_TMP/detail-short.json" '{
  "id":"BLACKOUT-SHORT","name":"MF_2_CDBA_Migration","status":"STARTED",
  "creationTimeToStart":"2026-08-10T11:00+02:00","creationTimeToEnd":"2026-08-10T13:00+02:00"
}'
if (
  set_fixed_window
  mf_oem_get_blackout() { cp "$TEST_TMP/detail-short.json" "$2"; }
  mf_oem_fetch_blackout_targets() { cp "$TEST_TMP/actual-exact.json" "$2"; }
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidate-short.json" \
    "$TEST_TMP/targets.json" "$TEST_TMP/inspection-short.json"
) && jq -e '
  .startedCandidateCount == 1 and .qualifyingCandidateCount == 0 and
  .inspectedCandidates[0].activeNow and
  (.inspectedCandidates[0].coversRequiredEnd | not)
' "$TEST_TMP/inspection-short.json" >/dev/null
then
  pass "a STARTED blackout that is active now but ends too early does not qualify"
else
  fail "a STARTED blackout that is active now but ends too early does not qualify"
fi

write_json "$TEST_TMP/candidates-terminal-only.json" '[
  {"id":"BLACKOUT-STOPPED","name":"MF_2_CDBA_Migration","status":"STOPPED","type":"PATCHING","owner":"mf"},
  {"id":"BLACKOUT-ENDED","name":"MF_2_CDBA_Migration_20260916T120000Z","status":"ENDED","type":"PATCHING","owner":"mf"}
]'
write_json "$TEST_TMP/detail-stopped.json" '{"id":"BLACKOUT-STOPPED","name":"MF_2_CDBA_Migration","status":"STOPPED"}'
write_json "$TEST_TMP/detail-ended.json" '{"id":"BLACKOUT-ENDED","name":"MF_2_CDBA_Migration_20260916T120000Z","status":"ENDED"}'
if (
  set_fixed_window
  mf_oem_get_blackout() {
    case "$1" in
      BLACKOUT-STOPPED) cp "$TEST_TMP/detail-stopped.json" "$2" ;;
      BLACKOUT-ENDED) cp "$TEST_TMP/detail-ended.json" "$2" ;;
      *) return 1 ;;
    esac
  }
  mf_oem_fetch_blackout_targets() { return 99; }
  mf_oem_inspect_exact_blackouts "$TEST_TMP/candidates-terminal-only.json" \
    "$TEST_TMP/targets.json" "$TEST_TMP/inspection-terminal-only.json"
) && jq -e '
  .terminalCandidateCount == 2 and .qualifyingCandidateCount == 0 and
  .transitionalCandidateCount == 0
' "$TEST_TMP/inspection-terminal-only.json" >/dev/null
then
  pass "STOPPED and ENDED records are history and do not require target lookup"
else
  fail "STOPPED and ENDED records are history and do not require target lookup"
fi

write_json "$TEST_TMP/inspection-transitional.json" '{
  "candidateCount":4,"qualifyingCandidateCount":0,"transitionalCandidateCount":4,"blockingCandidateCount":4,
  "inspectedCandidates":[
    {"id":"BLACKOUT-PENDING","status":"STOP_PENDING","exactTargetIds":false,"activeNow":false,"coversRequiredEnd":false,"qualifies":false},
    {"id":"BLACKOUT-FAILED","status":"START_FAILED","exactTargetIds":false,"activeNow":false,"coversRequiredEnd":false,"qualifies":false},
    {"id":"BLACKOUT-PARTIAL","status":"STOP_PARTIAL","exactTargetIds":false,"activeNow":false,"coversRequiredEnd":false,"qualifies":false},
    {"id":"BLACKOUT-UNKNOWN","status":"OEM_NEW_STATE","exactTargetIds":false,"activeNow":false,"coversRequiredEnd":false,"qualifies":false}
  ]
}'

# -----------------------------------------------------------------------------
# START and IS_ON contracts
# -----------------------------------------------------------------------------

if (
  mf_oem_validate_config() { :; }
  mf_oem_set_required_window() { set_fixed_window; }
  mf_oem_prepare_start_inspection() {
    cp "$TEST_TMP/targets.json" "$5"
    cp "$TEST_TMP/candidates-duplicate.json" "$6"
    cp "$TEST_TMP/inspection-duplicate.json" "$7"
  }
  mf_oem_create_and_verify_blackout() { printf 'unexpected-create\n' > "$TEST_TMP/reuse-create.log"; return 1; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 02:00 >/dev/null 2>&1 \
    && [ ! -e "$TEST_TMP/reuse-create.log" ]
)
then
  pass "START reuses any independently qualifying duplicate without mutation"
else
  fail "START reuses any independently qualifying duplicate without mutation"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_set_required_window() { set_fixed_window; }
  mf_oem_prepare_start_inspection() {
    cp "$TEST_TMP/targets.json" "$5"
    cp "$TEST_TMP/candidates-terminal-only.json" "$6"
    cp "$TEST_TMP/inspection-terminal-only.json" "$7"
  }
  mf_oem_create_and_verify_blackout() {
    printf '%s\n' "$4" >> "$TEST_TMP/terminal-create.log"
    cp "$TEST_TMP/detail-a.json" "$6"
  }
  mf_oem_print_start_result() { :; }
  mf_oem_stop_inadequate_started_blackouts() { :; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 02:00 >/dev/null 2>&1 \
    && [ "$(cat "$TEST_TMP/terminal-create.log")" = MF_2_CDBA_Migration ]
)
then
  pass "terminal-only history does not block a fresh exact-base create"
else
  fail "terminal-only history does not block a fresh exact-base create"
fi

: > "$TEST_TMP/fallback-create.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_set_required_window() { set_fixed_window; }
  mf_oem_prepare_start_inspection() {
    cp "$TEST_TMP/targets.json" "$5"
    cp "$TEST_TMP/candidates-terminal-only.json" "$6"
    cp "$TEST_TMP/inspection-terminal-only.json" "$7"
  }
  mf_oem_timestamped_blackout_name() { printf '%s\n' MF_2_CDBA_Migration_20260917T130405Z; }
  mf_oem_create_and_verify_blackout() {
    printf '%s\n' "$4" >> "$TEST_TMP/fallback-create.log"
    [ "$4" != MF_2_CDBA_Migration ] || return 5
    cp "$TEST_TMP/detail-b.json" "$6"
  }
  mf_oem_print_start_result() { :; }
  mf_oem_stop_inadequate_started_blackouts() { :; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 02:00 >/dev/null 2>&1 \
    && [ "$(sed -n '1p' "$TEST_TMP/fallback-create.log")" = MF_2_CDBA_Migration ] \
    && [ "$(sed -n '2p' "$TEST_TMP/fallback-create.log")" = MF_2_CDBA_Migration_20260917T130405Z ] \
    && [ "$(wc -l < "$TEST_TMP/fallback-create.log" | tr -d ' ')" -eq 2 ]
)
then
  pass "START uses a timestamped name only after an explicit base-name conflict"
else
  fail "START uses a timestamped name only after an explicit base-name conflict"
fi

: > "$TEST_TMP/uncertain-create.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_set_required_window() { set_fixed_window; }
  mf_oem_prepare_start_inspection() {
    cp "$TEST_TMP/targets.json" "$5"
    cp "$TEST_TMP/candidates-terminal-only.json" "$6"
    cp "$TEST_TMP/inspection-terminal-only.json" "$7"
  }
  mf_oem_create_and_verify_blackout() { printf '%s\n' "$4" >> "$TEST_TMP/uncertain-create.log"; return 1; }
  mf_oem_reconcile_started_blackouts() { return 1; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 02:00 >/dev/null 2>&1
  rc=$?
  [ "$rc" -ne 0 ] \
    && [ "$(cat "$TEST_TMP/uncertain-create.log")" = MF_2_CDBA_Migration ]
)
then
  pass "an uncertain create is reconciled but never retried under a new name"
else
  fail "an uncertain create is reconciled but never retried under a new name"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_set_required_window() { set_fixed_window; }
  mf_oem_prepare_start_inspection() {
    cp "$TEST_TMP/targets.json" "$5"
    cp "$TEST_TMP/candidates-duplicate.json" "$6"
    cp "$TEST_TMP/inspection-transitional.json" "$7"
  }
  mf_oem_create_and_verify_blackout() { printf 'unexpected-create\n' > "$TEST_TMP/transitional-create.log"; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 02:00 >/dev/null 2>&1
  rc=$?
  [ "$rc" -eq 3 ] && [ ! -e "$TEST_TMP/transitional-create.log" ]
)
then
  pass "transitional, failed, partial, or unknown records block competing START creation"
else
  fail "transitional, failed, partial, or unknown records block competing START creation"
fi

: > "$TEST_TMP/replace-sequence.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_set_required_window() { set_fixed_window; }
  mf_oem_prepare_start_inspection() {
    cp "$TEST_TMP/targets.json" "$5"
    cp "$TEST_TMP/candidate-short.json" "$6"
    cp "$TEST_TMP/inspection-short.json" "$7"
  }
  mf_oem_create_and_verify_blackout() {
    printf 'CREATE %s\n' "$4" >> "$TEST_TMP/replace-sequence.log"
    cp "$TEST_TMP/detail-a.json" "$6"
  }
  mf_oem_print_start_result() { :; }
  mf_oem_stop_inadequate_started_blackouts() { printf 'STOP_OLD\n' >> "$TEST_TMP/replace-sequence.log"; }
  mf_oem_start_blackout MIG-42 42 CDBA CDBA_M1 02:00 >/dev/null 2>&1 \
    && [ "$(sed -n '1p' "$TEST_TMP/replace-sequence.log")" = 'CREATE MF_2_CDBA_Migration' ] \
    && [ "$(sed -n '2p' "$TEST_TMP/replace-sequence.log")" = STOP_OLD ]
)
then
  pass "inadequate STARTED coverage is replaced before the old record is stopped"
else
  fail "inadequate STARTED coverage is replaced before the old record is stopped"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_set_required_window() { set_fixed_window; }
  mf_oem_prepare_inspection() { cp "$TEST_TMP/inspection-duplicate.json" "$7"; }
  mf_oem_print_inspection() { :; }
  mf_oem_is_blackout_on MIG-42 42 CDBA CDBA_M1 02:00 >/dev/null
)
then
  pass "IS_ON succeeds when any duplicate covers exact targets, now, and the required end"
else
  fail "IS_ON succeeds when any duplicate covers exact targets, now, and the required end"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_set_required_window() { set_fixed_window; }
  mf_oem_prepare_inspection() { cp "$TEST_TMP/inspection-short.json" "$7"; }
  mf_oem_print_inspection() { :; }
  mf_oem_is_blackout_on MIG-42 42 CDBA CDBA_M1 02:00 >/dev/null
  [ "$?" -eq 3 ]
)
then
  pass "IS_ON returns 3 when an active blackout ends before the required end"
else
  fail "IS_ON returns 3 when an active blackout ends before the required end"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_set_required_window() { set_fixed_window; }
  mf_oem_prepare_inspection() { cp "$TEST_TMP/inspection-transitional.json" "$7"; }
  mf_oem_print_inspection() { :; }
  mf_oem_is_blackout_on MIG-42 42 CDBA CDBA_M1 02:00 >/dev/null 2>&1
  [ "$?" -eq 1 ]
)
then
  pass "IS_ON reserves return code 3 for safe absence and errors on transitional duplicates"
else
  fail "IS_ON reserves return code 3 for safe absence and errors on transitional duplicates"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_set_required_window() { set_fixed_window; }
  mf_oem_prepare_inspection() { cp "$TEST_TMP/inspection-mismatched.json" "$7"; }
  mf_oem_print_inspection() { :; }
  mf_oem_is_blackout_on MIG-42 42 CDBA CDBA_M1 02:00 >/dev/null 2>&1
  [ "$?" -eq 1 ]
)
then
  pass "IS_ON fails closed on STARTED target mismatch instead of inviting START"
else
  fail "IS_ON fails closed on STARTED target mismatch instead of inviting START"
fi

# -----------------------------------------------------------------------------
# STOP and STATUS contracts
# -----------------------------------------------------------------------------

: > "$TEST_TMP/partial-stop.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_find_exact_blackouts() { cp "$TEST_TMP/candidates-duplicate.json" "$1"; printf '[]\n' > "$2"; }
  mf_oem_stop_verified_blackout() {
    printf '%s\n' "$1" >> "$TEST_TMP/partial-stop.log"
    [ "$1" != BLACKOUT-A ]
  }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null 2>&1
  rc=$?
  [ "$rc" -ne 0 ] \
    && [ "$(sed -n '1p' "$TEST_TMP/partial-stop.log")" = BLACKOUT-A ] \
    && [ "$(sed -n '2p' "$TEST_TMP/partial-stop.log")" = BLACKOUT-B ]
)
then
  pass "partial STOP failure still fans out to every managed blackout and returns nonzero"
else
  fail "partial STOP failure still fans out to every managed blackout and returns nonzero"
fi

: > "$TEST_TMP/changed-target-stop.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_find_exact_blackouts() { cp "$TEST_TMP/candidate-short.json" "$1"; printf '[]\n' > "$2"; }
  mf_oem_get_blackout() { cp "$TEST_TMP/detail-short.json" "$2"; }
  mf_oem_fetch_blackout_targets() { printf 'unexpected-target-read\n' >> "$TEST_TMP/changed-target-stop.log"; return 1; }
  mf_oem_http() {
    printf '%s\n' "$2" >> "$TEST_TMP/changed-target-stop.log"
    : > "$3"
    MF_OEM_HTTP_STATUS=204
  }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null 2>&1 \
    && [ "$(cat "$TEST_TMP/changed-target-stop.log")" = \
         'https://oms.example:7803/em/api/blackouts/BLACKOUT-SHORT/actions/stop' ]
)
then
  pass "STOP uses immutable managed IDs and is not blocked by changed target coverage"
else
  fail "STOP uses immutable managed IDs and is not blocked by changed target coverage"
fi

: > "$TEST_TMP/terminal-stop.log"
if (
  mf_oem_validate_config() { :; }
  mf_oem_find_exact_blackouts() { cp "$TEST_TMP/candidates-terminal-only.json" "$1"; printf '[]\n' > "$2"; }
  mf_oem_get_blackout() {
    case "$1" in
      BLACKOUT-STOPPED) cp "$TEST_TMP/detail-stopped.json" "$2" ;;
      BLACKOUT-ENDED) cp "$TEST_TMP/detail-ended.json" "$2" ;;
      *) return 1 ;;
    esac
  }
  mf_oem_http() { printf 'unexpected-mutation\n' >> "$TEST_TMP/terminal-stop.log"; return 1; }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null 2>&1 \
    && [ ! -s "$TEST_TMP/terminal-stop.log" ]
)
then
  pass "repeated STOP treats STOPPED and ENDED records as idempotent no-ops"
else
  fail "repeated STOP treats STOPPED and ENDED records as idempotent no-ops"
fi

if (
  mf_oem_validate_config() { :; }
  mf_oem_find_exact_blackouts() { cp "$TEST_TMP/candidate-short.json" "$1"; printf '[]\n' > "$2"; }
  mf_oem_get_blackout() { MF_OEM_HTTP_STATUS=404; return 1; }
  mf_oem_http() { return 99; }
  mf_oem_stop_blackout MIG-42 42 CDBA CDBA_M1 >/dev/null 2>&1
)
then
  pass "STOP treats a concurrently removed managed ID as idempotent success"
else
  fail "STOP treats a concurrently removed managed ID as idempotent success"
fi

write_json "$TEST_TMP/status-candidates.json" '[
  {"id":"BLACKOUT-A","name":"MF_2_CDBA_Migration","status":"STARTED","type":"PATCHING","owner":"mf"},
  {"id":"BLACKOUT-HISTORY","name":"MF_2_CDBA_Migration_20260916T120000Z","status":"ENDED","type":"PATCHING","owner":"mf"}
]'
write_json "$TEST_TMP/status-history.json" '{
  "id":"BLACKOUT-HISTORY","name":"MF_2_CDBA_Migration_20260916T120000Z","status":"ENDED",
  "creationTimeToStart":"2026-08-09T10:00+02:00","creationTimeToEnd":"2026-08-09T12:00+02:00"
}'
if (
  mf_oem_validate_config() { :; }
  mf_oem_find_exact_blackouts() { cp "$TEST_TMP/status-candidates.json" "$1"; printf '[]\n' > "$2"; }
  mf_oem_get_blackout() {
    case "$1" in
      BLACKOUT-A) cp "$TEST_TMP/detail-a.json" "$2" ;;
      BLACKOUT-HISTORY) cp "$TEST_TMP/status-history.json" "$2" ;;
      *) return 1 ;;
    esac
  }
  mf_oem_resolve_topology() { return 99; }
  mf_oem_discover_targets() { return 99; }
  mf_oem_status_blackout MIG-42 42 CDBA CDBA_M1 > "$TEST_TMP/status.out"
) && grep -F 'OEM blackout ID       : BLACKOUT-A' "$TEST_TMP/status.out" >/dev/null \
   && grep -F 'OEM blackout status   : STARTED' "$TEST_TMP/status.out" >/dev/null \
   && grep -F 'OEM blackout ID       : BLACKOUT-HISTORY' "$TEST_TMP/status.out" >/dev/null \
   && grep -F 'OEM blackout status   : ENDED' "$TEST_TMP/status.out" >/dev/null \
   && grep -F 'Blackout starts (UTC) :' "$TEST_TMP/status.out" >/dev/null \
   && grep -F 'Blackout ends (UTC)   :' "$TEST_TMP/status.out" >/dev/null
then
  pass "STATUS lists every managed record with ID, name, status, start, and end"
else
  fail "STATUS lists every managed record with ID, name, status, start, and end"
fi

# -----------------------------------------------------------------------------
# Entry point and caller boundary
# -----------------------------------------------------------------------------

if grep -F 'MF_OEM_BLACKOUT_NAME=MF_2_${cdb_name}_Migration' "$HELPER" >/dev/null \
   && grep -F 'mf_oem_timestamped_blackout_name' "$HELPER" >/dev/null \
   && grep -F 'mf_oem_is_explicit_name_conflict' "$HELPER" >/dev/null \
   && ! grep -F 'mf_oem_http DELETE' "$HELPER" >/dev/null \
   && ! grep -F 'mf_oem_http PATCH' "$HELPER" >/dev/null
then
  pass "implementation keeps the base name, bounded suffix fallback, and no delete/edit path"
else
  fail "implementation keeps the base name, bounded suffix fallback, and no delete/edit path"
fi

if grep -F "when row_count != 1 or go_live <= sysdate then '02:00'" "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'ceil((go_live + 2/24 - sysdate) * 1440)' "$MAIN_SCRIPT" >/dev/null \
   && grep -F "[ \"\$DURATION\" = \"\" ] && DURATION='02:00'" "$MAIN_SCRIPT" >/dev/null \
   && grep -F '"$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME" "$DURATION"' "$MAIN_SCRIPT" >/dev/null
then
  pass "START and IS_ON share the future GO-LIVE-plus-two-hours or default-two-hours duration"
else
  fail "START and IS_ON share the future GO-LIVE-plus-two-hours or default-two-hours duration"
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
  if grep -F 'mfEmBlackout.sh -m $MF_MIGRATION_ID -r -A IS_ON' "$caller" >/dev/null \
     && grep -F 'BLACKOUT_RC=$?' "$caller" >/dev/null \
     && grep -F '[ "$BLACKOUT_RC" -eq 3 ] || die "Unable to verify the OEM blackout"' "$caller" >/dev/null \
     && grep -F 'mfEmBlackout.sh -m $MF_MIGRATION_ID -r -A START' "$caller" >/dev/null \
     && grep -F 'die "Unable to create blackout"' "$caller" >/dev/null
  then
    pass "$(basename "$caller") starts only after definitive IS_ON=false and keeps START failure fatal"
  else
    fail "$(basename "$caller") starts only after definitive IS_ON=false and keeps START failure fatal"
  fi
done

for caller in \
  "$RELEASE_ROOT/bin/mfDbActions.sh" \
  "$RELEASE_ROOT/bin/mfUpdateparams.sh" \
  "$RELEASE_ROOT/unstable_bin/mfDbActions.sh" \
  "$RELEASE_ROOT/unstable_bin/mfUpdateparams.sh"
do
  if grep -F -- '-A IS_ON -d "00:30"' "$caller" >/dev/null \
     && grep -F -- '-A START -d "00:30"' "$caller" >/dev/null
  then
    pass "$(basename "$caller") uses the same explicit 00:30 window for IS_ON and START"
  else
    fail "$(basename "$caller") uses the same explicit 00:30 window for IS_ON and START"
  fi
done

if grep -F 'if [ "$USE_REST_API" != "Y" ]' "$MAIN_SCRIPT" >/dev/null \
   && grep -F 'start blackout MF_2_${CDB_NAME}_Migration' "$MAIN_SCRIPT" >/dev/null
then
  pass "the local emctl path remains available when -r is not passed"
else
  fail "the local emctl path remains available when -r is not passed"
fi

printf '%s\n' "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
