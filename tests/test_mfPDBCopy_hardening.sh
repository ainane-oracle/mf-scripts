#!/usr/bin/env bash

set -euo pipefail

test_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
project_dir=$(cd "$test_dir/.." && pwd)
stable="$project_dir/bin/mfPDBCopy.sh"
unstable="$project_dir/unstable_bin/mfPDBCopy.sh"

fail()
{
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains()
{
  local file="$1"
  local text="$2"
  grep -Fq "$text" "$file" || fail "$(basename "$file") is missing: $text"
}

assert_not_contains()
{
  local file="$1"
  local text="$2"
  if grep -Fq "$text" "$file"
  then
    fail "$(basename "$file") still contains: $text"
  fi
}

for script in "$stable" "$unstable"
do
  assert_contains "$script" "whenever sqlerror exit sql.sqlcode"
  assert_contains "$script" 'grep -Eq "ORA-00600:|ORA-04045:"'
  assert_contains "$script" 'noncdb_to_pdb.sql failed for $TMP_PDB; do not continue to datapatch or RAC open'
  assert_contains "$script" 'assertNoPendingPdbErrors "$TMP_PDB" "ALLOW_OPTION_MISMATCH"'
  assert_contains "$script" 'assertNoPendingPdbErrors "$PDB"'
  assert_contains "$script" 'openPDBReadWriteOnAllInstances "$TMP_PDB" "$I2"'
  assert_contains "$script" 'save state instances=all'
  assert_contains "$script" 'join gv\$instance i on i.inst_id=p.inst_id'
  assert_not_contains "$script" '@?/rdbms/admin/catclust.sql'
done

cmp -s "$stable" "$unstable" || fail "stable and unstable mfPDBCopy.sh differ"

echo "PASS: mfPDBCopy hardening checks"
