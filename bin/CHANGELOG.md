# Migration Factory `bin` changelog

## 2026-08-15 — `mfPDBCopy.sh` 1.8.1

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

### Validation

- Added `tests/test_mfPDBCopy_hardening.sh` to verify the new fail-fast catalog
  conversion behavior, datapatch error detection, plug-in violation checks,
  serialized RAC open, and all-instance state persistence.
- Applied the same `mfPDBCopy.sh` implementation to both `bin` and
  `unstable_bin` to prevent behavior drift between deployment paths.

# 2026-08-12
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

