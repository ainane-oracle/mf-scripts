# Migration Factory `bin` changelog

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
