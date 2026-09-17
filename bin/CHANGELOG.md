# Migration Factory `bin` changelog

## 2026-09-17 - Time-qualified OEM blackout family - helper v1.18 / entry point v1.18

### Changed

- `MF_2_<CDB>_Migration` remains the preferred create name, but it is no longer
  treated as a unique record. Migration Factory manages the exact base name and
  names with the strict `_YYYYMMDDTHHMMSSZ` suffix. A timestamped name is tried
  only when OEM explicitly rejects the base name as a duplicate/name-uniqueness
  conflict; transport errors and uncertain responses are reconciled without a
  second create under another name.
- `START` and `IS_ON` now use the same contract. At least one individual
  `STARTED` record must have the exact discovered target-ID set, include the
  current time, and last through the requested end. Duplicate coverage is never
  combined across OEM IDs.
- Without `-d`, both actions require coverage through planned GO-LIVE plus two
  hours when GO-LIVE is uniquely defined and still in the future. Missing,
  ambiguous, current, or past GO-LIVE falls back to two hours from now. An
  explicit `-d` overrides this rule for both actions.
- `STOPPED` and `ENDED` records are historical: they remain visible in `STATUS`
  but never block `START` and are never deleted. `STATUS` lists every managed
  record with its immutable ID, name, status, start, and end.
- When only inadequate `STARTED` records exist, `START` first creates and
  verifies replacement coverage, then best-effort stops the old records.
  Transitional, failed, partial, unknown, or unverifiable records still fail
  closed and do not permit a competing create.
- `STOP` processes every managed-family ID. It requests stop for every
  `STARTED` record regardless of current target coverage, treats
  `STOP_PENDING`/`STOPPED`/`ENDED` as idempotent no-ops, continues after an
  individual failure, treats an ID concurrently removed from OEM as already
  stopped, and returns nonzero when any result remains unverified.
- The stable and unstable callers run `START` only when `IS_ON` returns the
  definitive not-covered code `3`. Other `IS_ON` failures remain fatal. The
  30-minute callers pass the same `-d 00:30` to both checks; the target-PDB flow
  uses the shared GO-LIVE/default duration rule.
- The local `emctl` workflow is unchanged when `-r` is not supplied.

## 2026-09-17 - OEM REST blackout ensure-on - helper v1.17 / entry point v1.17

### Changed

- `START` is now an ensure-on operation. It succeeds without mutation when at
  least one same-name blackout is independently verified as `STARTED` with the
  exact currently discovered target-ID set. Otherwise it creates a new
  same-name blackout; `STOPPED`, `ENDED`, scheduled, transitional, failed,
  partial, unknown, and coverage-mismatched records do not block that create.
- A newly created blackout must reach `STARTED` and exact target coverage before
  `START` reports success. A lost or unexpected create response is reconciled by
  re-listing and re-verifying the same-name records; uncertainty remains an
  error.
- Before creation, a failed list/detail snapshot is retried as a complete unit.
  Creation still requires one successful snapshot that proves no exact
  `STARTED` candidate exists.
- `IS_ON` uses the same existential rule: any independently verified exact
  `STARTED` record means ON, even when lifecycle history or transitional records
  also exist.
- The obsolete target `PATCH`, terminal `DELETE`, and STOP_PENDING cleanup paths
  were removed. Existing records are not altered or deleted by `START`.
- `STOP` retries can proceed past a duplicate already in `STOP_PENDING` and stop
  the remaining independently verified exact `STARTED` duplicates. Changed
  coverage, failed, partial, and unknown states still fail closed.
- A lost or unexpected STOP response is reconciled against the same immutable
  blackout ID. Duplicate fan-out continues for the remaining verified IDs, and
  the command returns nonzero if any individual outcome remains unverified.
- Selecting REST with `-r` no longer falls back to local `emctl` after a REST
  failure. Without `-r`, the local `emctl` path is unchanged.
- REST mode now requires an explicit `-A`. The parser rejects unknown options,
  missing option values, stray positional arguments, and non-ASCII option
  dashes before any REST helper can run. Local mode still defaults to `START`
  when `-A` is omitted.
- Without an explicit `-d`, a past GO-LIVE date now means a fresh two-hour REST
  blackout; it does not reuse the expired planned end time.

### Caller boundary

- `mfDbActions.sh`, `mfCreateTargetPDB.sh`, and `mfUpdateparams.sh` (stable and
  unstable copies) already stop their workflow when REST `START` returns
  nonzero. This preserves the required boundary: an unavailable OEM or an
  unverified exact `STARTED` blackout cannot be reported as success.

## 2026-09-16 - `mfEmBlackout_oemRest.sh` - v1.16

### Changed

- REST inspection now verifies every exact-name blackout independently by immutable
  OEM ID, status, and exact target-ID coverage. `STOPPED` and `ENDED` records
  are historical records for Migration Factory. They remain in OEM but do not
  make the canonical blackout ambiguous and are never deleted by this flow.
- `START` and `IS_ON` continue when one or more same-name `STARTED` blackouts
  have exact coverage of the discovered target set. The log lists every
  candidate ID and status and warns when duplicates or historical records exist.
- `STOP` requests a stop for every verified same-name `STARTED` blackout with
  exact target coverage. If any candidate is transitional, unsupported, or has
  different coverage, STOP fails rather than leaving an uncertain result.

### Accepted and blocked edge cases

- Accepted with a warning: one or more `STARTED` blackouts with exact target
  coverage, optionally alongside any number of `STOPPED` or `ENDED` records.
- Accepted as no active blackout: only `STOPPED` or `ENDED` records exist.
- Blocked: `SCHEDULED`, `STOP_PENDING`, edit, partial, failed, unknown, or
  otherwise non-terminal same-name records coexist with duplicates. A STARTED
  record that does not exactly match the discovered target set is also blocked.
- The change does not extend, shorten, recreate, or physically delete an active
  blackout to correct its end time. Duration management remains unchanged.

## 2026-08-18 - `mfStatistics.sh` - v1.9

### Changed

- `bin/mfStatistics.sh` now writes a warning and continues with the next schema
  when `DBMS_STATS.GATHER_SCHEMA_STATS` reports the known `ORA-20011` approximate
  NDV failure containing `qeaeMinmaxFastFIV:inputlen` `ORA-00600`.

### Note

- This is a targeted workaround for a probable Oracle Database internal bug.

## 2026-08-15 - `mfPDBCopy.sh` - v1.8.1

### Fixed

- Stop the PDB Copy workflow immediately when `noncdb_to_pdb.sql` fails. The
  previous implementation could continue to datapatch and the RAC open after a
  catalog conversion or recompilation failure.
- Propagate SQL*Plus operating-system and SQL errors from PDB close, open, and
  drop operations by using `whenever oserror` and `whenever sqlerror` and by
  checking the remote command return code.
- Treat datapatch execution failure as fatal. The datapatch log is retained and
  displayed before the workflow stops.
- Detect `ORA-00600` and `ORA-04045` in the datapatch log and stop before the
  temporary PDB is reopened or switched. This protects against continuing after
  failures such as the revalidation of
  `PUBLIC.REDACTION_VALUES_FOR_TYPE_FULL`.
- Check `PDB_PLUG_IN_VIOLATIONS` for pending errors before the final RAC open.
  A database-option mismatch is allowed only during the controlled intermediate
  close/reopen; all pending errors are required to be cleared afterward.

### Changed

- Replace the unconditional `catclust.sql` execution with a validation that the
  target CDB has the RAC option enabled. PDB Copy now fails with a clear message
  when RAC provisioning is incomplete instead of attempting to modify the CDB
  catalog.
- Open the temporary PDB `READ WRITE` sequentially on each running RAC instance
  to avoid overlapping cluster-wide PDB open operations that can result in
  `ORA-65197`/`ORA-65199`.
- Verify through `GV$PDBS` that the PDB is `READ WRITE` and unrestricted on
  every running RAC instance before continuing.
- Save the successful PDB open state with `INSTANCES=ALL` so the state is
  restored consistently across RAC restarts.
- Make PDB open-state tests RAC-aware by querying `GV$PDBS` rather than only the
  instance servicing the current connection.

# 2026-08-12 - mf_Utils_03_rspManagement.sh - v1.8

Migration Factory fix – duplicate EXCLUDEOBJECTS-1 / PRGZ-3621
During ZDM response-file generation, we identified an issue affecting table-only exclusions such as %OGG_BAD_COLS_YES%.
When no OWNER: exclusion was configured, MF_ZDM_EXCLUDED_SCHEMAS was empty. The response generator retained the original blank template entry:
EXCLUDEOBJECTS-1=
It then generated the first table exclusion using the same parameter number:
EXCLUDEOBJECTS-1=owner:PR_TOR,objectType:TABLE,objectName:PLAN_TABLE
ZDM consequently raised PRGZ-3621, reporting the same parameter with a blank first value and a populated second value.
The fix changes the response generator so that the blank template entry is retained only when both schema and table exclusion lists are empty. If table exclusions exist, they replace the placeholder directly.
The correction was applied to the stable and unstable versions of mfUtils_03_rspManagement.sh. Change history was added with date 12/08/2026 and responsible AIN. Regression validation passed with 4/4 tests.
This correction fixes the duplicate-number problem only. It does not permit combining INCLUDEOBJECTS and EXCLUDEOBJECTS; ZDM rejects that separate configuration with PRGT-1073. A migration must use either an include-only strategy or an exclusion-only strategy.

## 2026-08-10 - OEM REST Blackout Changelog - v1.15

### Scope

This document records the OEM REST blackout feature delivered on branch

### Implemented feature

- `bin/mfEmBlackout.sh` supports `-r` to use the centralized OEM REST API for
  `START`, `STOP`, `STATUS`, and `IS_ON`; without `-r`, the original local
  `emctl` workflow remains unchanged.
- `bin/mfEmBlackout_oemRest.sh` resolves Migration Factory attempt/peer-cluster
  topology, discovers the authoritative OEM database/PDB targets, creates the
  blackout through `/em/api/blackouts`, and verifies exact target-ID coverage.
- One canonical name, `MF_2_<CDB>_Migration`, identifies the REST blackout.
  Duplicate exact-name blackouts conflict; timestamp-suffixed legacy names are
  ignored.
- `START` reuses a complete `SCHEDULED` or `STARTED` blackout. It deletes a
  terminal blackout, confirms its absence, and recreates the canonical name;
  `-d` is translated to REST duration hours and minutes.
- `STOP` submits the REST stop action for one verified `STARTED` blackout and
  remains non-blocking. `STOP_PENDING` is a successful no-op; bounded terminal
  cleanup is owned by the next `START` (`MF_OEM_STOP_PENDING_TIMEOUT`, 300s by
  default).
- `IS_ON` reports ON only for one `STARTED` canonical blackout covering every
  discovered target; `STATUS` reports the inspected state and coverage.

### Decisions and safeguards

- REST is opt-in to preserve existing local-agent behavior, names, durations,
  and fallback paths.
- Local `emctl` fallback is permitted only before a REST mutation and only when
  no exact canonical candidate requires verification. An uncertain create,
  stop, or delete response blocks fallback to avoid conflicting blackouts.
- Target discovery fails closed for missing, ambiguous, conflicting, or
  incomplete topology/target data. Coverage is checked against one exact ID,
  never by unioning multiple blackouts.
- REST requires HTTPS (`MF_OEM_API_BASE_URL`), TLS verification (optionally
  `MF_OEM_CA_CERT`), and `curl`, `jq`, and `base64`. Pagination is bounded and
  restricted to the configured OEM origin.
- The existing KeePass store supplies the `MF_BLACKOUT` account password.
  Credentials are passed to `curl` through stdin; temporary files are mode 600
  and cleanup removes them and unsets the password.

### Operational workflow

1. Select REST explicitly, for example:
   `mfEmBlackout.sh -m <migration-id> -r -A START -d 02:00`.
2. The script validates configuration and credentials, resolves topology, and
   discovers matching OEM targets.
3. It inspects the canonical blackout and validates one candidate's state and
   exact target IDs before mutating OEM.
4. `START` reuses, safely clears, or creates-and-verifies a blackout. `STOP`
   submits the request and returns without polling or deletion.
5. A safe pre-mutation REST failure can use the local `emctl` path; otherwise
   the script fails or warns without issuing a contradictory local action.
