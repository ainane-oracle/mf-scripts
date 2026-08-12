
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