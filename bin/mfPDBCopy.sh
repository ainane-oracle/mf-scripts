#
# -----------------------------------------------------------------------------
#
#  Generation marker  : MF_DOC_GENERATED
#  File               : mfPDBCopy.sh
#
#  Purpose            : Copy PDB via DBLINK.
#
#  Description        : Initializes the Migration Factory environment, validates the selected
#                       context, and executes the operational workflow for this entry point.
#
#  Functions           : 
#                        - addRollingEndSteps
#                        - assertNoPendingPdbErrors
#                        - closePDB
#                        - copyUserDefinition
#                        - createRollingDB
#                        - createRollingDBControlFileAfterCopy
#                        - detailed_usage
#                        - DO_ADD_STEPS
#                        - DO_CLEANUP
#                        - DO_COPY
#                        - DO_DG_ALL
#                        - DO_DROP
#                        - DO_ENCRYPT_ALL
#                        - DO_ENCRYPT_BIGFILE
#                        - DO_END_COPY
#                        - DO_INIT
#                        - DO_MOVE
#                        - DO_OGG
#                        - DO_ROLLING_INFO
#                        - DO_SETUP
#                        - DO_STATUS
#                        - DO_SWITCH
#                        - DO_SYNCH_COPY
#                        - DO_UNIT_TEST
#                        - DO_USERS
#                        - exchangePDB
#                        - failIfRestricted
#                        - getAL
#                        - isDb
#                        - moveObjects
#                        - openPDB
#                        - openPDBReadWriteOnAllInstances
#                        - parallelEncryption
#                        - postCopyActions
#                        - renamePDB
#                        - revokeReadOnUser
#                        - rollingDBAction
#                        - rollingRecover
#                        - rollingRestore
#                        - setReadOnUser
#                        - showKeyInfo
#                        - testIfPDBIsOpened
#                        - usage
#                        - verifyTargetRacEnabled
#
# *****************************************************************************

VERSION=1.8.1
# ************************************************************************** 
# Modifications :
# =============
# 
# 13/09/2024 MBO - Delivery MF 1.2 @ BNP, change logging mechanism to avoid
#                  sub processes, temporary files cleanup (mktemp with suffixes)
#
# 15/11/2024 MBO - Version 1.2.5, before LOT-0 start,
#
# 15/08/2026     - Stop after non-CDB conversion or datapatch catalog errors,
#                  validate plug-in violations, and serialize the final RAC open.
#
# ************************************************************************** 
SCRIPT_LIB="Migration Factory 2.0 : Copy PDB via DBLINK"
CATEGORY="30-Migration execution"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  Usage
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : detailed_usage
#
#  Description         : Prints the detailed usage information for mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Iterate over the selected objects or command output.
# -----------------------------------------------------------------------------
#

# MF_OLD_DETAILED_USAGE_START - old detailed_usage block preserved for easy deletion after validation
#
# detailed_usage()
# {
# echo "
#   =======================================================================================
#   $(basename $0) : Detailed information
#   =======================================================================================
#   
#   
#   - Functionalities
#     ========================
#     
#       This script implements the PDB COPY migration methodology, it is called by mfMigrate_logical.sh
#     in place of exprot/import after the verifications have been made and the extract has been 
#     created by ZDM.
#     
#       This script is to be used for large databases of for databases which have a huge number
#     of partitions.
#     
#       The principle is to 
#       - physically copy the source database to the target
#       - based on these datafiles, a temporary PDB is created
#       - activate golden-gate for online migrations
#       - encrypt the datafiles
#       - move the objects in BIGFILES tablespaces
#       - *Replace the target PDB by the temporary one 
#
#     NOTE : This method is only valid for 19c+ source databases running on LINUX      
#           
#     The main functions are :
#     
#     - Status
#       --------------
#       
#         Simply prints the status of the migration and the run-state
#          
#     - Init
#       --------------
#       
#         Initialize the process and create the CDB level DATABASE LINK which will be used to
#       copy the datafiles
#       
#     - Copy
#       --------------
#       
#         Copies the source datafiles to the target (in a temporary PDB) and transforms a 
#       NON CDB database in RAC/MULTI-TENANT database.
#       
#         Once the temporary PDB is created, datapatch is run to upgrade to the current 
#       version.
#       
#     - Setup/Users
#       --------------
#       
#         Creates the migrat ion user on the target temporary PDB and copies the standard
#       users definitions from the real target PDB to the temporary one.
#       
#         Copy master encryption Key from teh target PDB to the temporary one)
#       
#         After this step the database is usable, but not encrypted, we can start replication 
#       to start synchroising the data and run reminder operations ONLINE.
#       
#     - Golden-Gate
#       --------------
#       
#         For online migrations, we create and start the replicat 
#         
#     - Encrypt BIGFILE tablespaces
#       --------------
#       
#         If the source database already contains BIGFILE tablespaces, we encrypt them ONLINE
#       (it is not necessary to move data)
#             
#     - Move
#       --------------
#
#         This phase may be skipped, it consiste in movin SMALLFILE located objects to
#       BIGFILE tablespaces to meet customer's standards.
#
#         This operation can be long, it can be postponed to post-golive or simply ignored.
#         
#     - ENcrypt ALL
#       --------------
#         
#         Here we encrypt all remaining tablespaces (SYS,SYSTEM) and all application tablespaces still containing 
#       data
#       
#     - Switch
#       --------------
#       
#         Exchange \"normal\" and temporary databases
#         
#     - cleanup
#       --------------
#         
#         Removes the \"normal\" PDB after it has been replaced by the temporary one .
#         
#   - Specific cases/variants
#     =======================
#     
#         Not applicable
#     
#   - Knonwn Issues/Evolutions needed
#     ===============================
#
#         Not applicable
#     
# "
# }
# MF_OLD_DETAILED_USAGE_END

detailed_usage()
{
  cat <<EOF
  =======================================================================================
  $(basename "$0") : Detailed information
  =======================================================================================

  Purpose
  =======

    Copy PDB via DBLINK.

    This detailed help focuses on behavior and operational context. Command-line
    syntax, parameters, and short examples are documented by usage().

  Main workflow
  =============

    The script follows the standard Migration Factory entry point lifecycle:

      1. Load common utility libraries and initialize logging.
      2. Read the migration context and derive environment-dependent values.
      3. Validate required connections and preconditions.
      4. Execute the script-specific actions listed below.
      5. Update logs, progress information, and final status before exiting.

    The main reported actions in this script are:

      - Grants on source
      - User existence on TARGET
      - Get Password on Temporary PDB
      - Grants on temporary PDB
      - Get Golden-Gate status
      - Replication is running
      - Stopping replication
      - Replication is stopped
      - Change CATALOG name
      - Change Alias configuration for forward replication
      - Alias
      - Replication was running before echange
      - Starting replication
      - Replication was NOT running before echange

  Integration points
  ==================

    The script interacts with or delegates work to:

      - mfReplMgmt.sh
      - mfDbActions.sh
      - mfRunMonitor.sh
      - GoldenGate
      - ASM

  Operational notes
  =================

    - This workflow can modify database objects, runtime artifacts, generated
      files, or repository state. Confirm the selected migration context before
      running it.
    - Some operations require remote host access through the configured
      Migration Factory OS account.
    - Repository progress and status information may be updated during the
      run.
    - When the script reports an error, use the generated log file together
      with the displayed step name to identify the failing operation.
EOF
}
# MF_OLD_USAGE_START - old usage block preserved for easy deletion after validation
#
#
# #
# # -----------------------------------------------------------------------------
# #
# #  Generation marker   : MF_DOC_GENERATED
# #  Function            : usage
# #
# #  Description         : Prints the short usage information for mfPDBCopy.sh.
# #
# #  Input Parameters    : - None.
# #
# #  Output              : Prints information to stdout or the configured log.
# #
# #  Return Code         : Not explicitly defined.
# #
# #  Algorithm           : 
# #                        - Iterate over the selected objects or command output.
# #                        - Parse command output to derive status or generated values.
# #
# #  Possible issues     : 
# #                        - Uses eval, so quoting or special characters may alter command
# #                          execution.
# # -----------------------------------------------------------------------------
# #
#
# usage() 
#
# {
#  echo "Usage :
#  $(basename $0) -m MIGRATION_ID [-S \"STEPS\"] [-f] [-F] [-Q|-V] [-n] [-h|-?]
#
#       $SCRIPT_LIB
#          -S Steps         : Steps to be run
#          -m MIGRATION_ID  : ID of the migration (base name for files)  MANDATORY
#          -f               : Finish copy when using rolling copy mode
#          -F               : FORCE operation even if Status is not correct
#          -Q               : Quiet mode (remove progress output)
#          -V               : Print all loging information
#          -?|-h            : Help"
# echo
# for g in ALL_STEPS
# do
#   echo "         - $g"
#   tmp=$(eval echo \$$g)
#   for s in $tmp
#   do
#     lib=$(echo "$STEP_LIST" | grep "^$s:" | cut -f2 -d":")
#     printf  "           - %-20.20s : %s\n" "$s" "$lib"
#   done
# done
#
# echo "
#   Version : $VERSION
#   "
#   [ "$MF_DETAILED_USAGE" = "Y" ] && detailed_usage
# exit
# }
# MF_OLD_USAGE_END

#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : usage
#
#  Description         : Prints command-line usage and optionally appends
#                        detailed usage information.
#
#  Input Parameters    : None.
#
#  Output              : Writes usage information to standard output and exits.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Print concise command-line help from a here-document.
#                        - Append detailed usage when MF_DETAILED_USAGE is enabled.
# -----------------------------------------------------------------------------
#

usage()
{
  cat <<EOF
Usage:
  $(basename "$0") -m MIGRATION_ID [OPTIONS]
  $(basename "$0") -h | -?
  $(basename "$0") --help

Description:
  Copy PDB via DBLINK.

Required:
  -m MIGRATION_ID        : ID of the migration (base name for files).

Options:
  -S Steps               : Steps to be run.
  -F                     : FORCE operation even if Status is not correct.
  -f                     : Finish copy when using rolling copy mode.
  -Q                     : Quiet mode (remove progress output).
  -V                     : Print all logging information.
  -n                     : Disable log output.
  -h, -?                 : Show this help and exit.
  --help                 : Show this help plus the detailed usage section and exit.

Examples:
  $(basename "$0") -m MIGRATION_ID
$(basename "$0") -m MIGRATION_ID -S Steps

Notes:
  Use --help to display the detailed usage section when available.

Version:
  $VERSION
EOF
  [ "$MF_DETAILED_USAGE" = "Y" ] && detailed_usage
  exit
}



_____________________________scriptSpecificFunctions() { : ; }


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : testIfPDBIsOpened
#
#  Description         : Performs the test If PDBIs Opened step used by
#                        mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Not applicable.
#
#  Return Code         : Returns a status code derived from the operation
#                        result.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Return a status code derived from the operation result.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

testIfPDBIsOpened()
{
  local pdb="$1"
  local mode="$2"
  tmp=$(exec_sql "$MF_TGT_CDB_CONNECT" "
    select to_char(
             case
               when count(*) = (select count(*) from gv\$instance) then 1
               else 0
             end)
    from gv\$pdbs
    where name='$pdb'
    and   open_mode='$mode';") || die "ERROR:\n $tmp"
  mfDebugLog "tmp=$tmp"
  [ $tmp -eq 1 ] && return 0 || return 1
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : showKeyInfo
#
#  Description         : Performs the show Key Info step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Not applicable.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Parse command-line options and dispatch the requested action.
#                        - Execute SQL statements through the configured database connection.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
# -----------------------------------------------------------------------------
#

showKeyInfo()
{
    exec_sql -verbose "$MF_TGT_CDB_CONNECT" "
    set lines 200 tab off head on pages 200
    col con_id format 99
    col wrl_parameter format a80
    col name format a15
    col status format a25
    col wallet_type format a15
    col wallet_order format a15
    select 
       ew.con_id
      ,case  
         when p.name is null then '** CDB ***'
         else p.name
       end name
      ,ew.wrl_parameter
      ,ew.status
      ,ew.wallet_type 
      ,ew.wallet_order
    from 
      v\$encryption_wallet ew
      left join v\$pdbs p on ( p.con_id=ew.con_id) 
    order by ew.con_id ;
    
    select
       ki.con_id
      ,case  
         when p.name is null then '** CDB ***'
         else p.name
       end name
      ,ki.encryptionalg
      ,ki.masterkeyid
      ,ki.masterkey_activated
    from
      v\$database_key_info ki
      left join v\$pdbs p on ( p.con_id=ki.con_id) 
    order by
      ki.con_id ;
    " "$1" "$I2"
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : renamePDB
#
#  Description         : Performs the rename PDB step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
# -----------------------------------------------------------------------------
#

renamePDB()
{
 local from="$1"
 local to="$2"
 local mess="$3"
 local indent="$4"
    remoteCommand=$(cat <<%%
if [ ! -f /home/oracle/$CDB_NAME.env ]
then
  echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
else
  . $CDB_NAME.env
  sqlplus / as sysdba << SQL_AT_TARGET
alter pluggable database $from rename global_name to $to ;
show pdbs
SQL_AT_TARGET
fi
%%
)
    exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" "$mess" "$indent"
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : closePDB
#
#  Description         : Performs the close PDB step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
# -----------------------------------------------------------------------------
#

closePDB()
{
 local PDB="$1"
 local mess="$2"
 local indent="$3"
 local openCount
 openCount=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(count(*)) from gv\$pdbs where name='$PDB' and open_mode != 'MOUNTED';") \
   || die "Unable to determine the RAC open state of $PDB"
 if [ "${openCount:-0}" -eq 0 ]
 then
   libAction "$PDB is already closed on all running instances" "$indent"
   return 0
 fi
    remoteCommand=$(cat <<%%
if [ ! -f /home/oracle/$CDB_NAME.env ]
then
  echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
else
  . $CDB_NAME.env
  sqlplus -s / as sysdba << SQL_AT_TARGET
whenever oserror exit failure
whenever sqlerror exit sql.sqlcode
alter pluggable database $PDB close immediate instances=all ;
show pdbs
exit success
SQL_AT_TARGET
exit \$?
fi
%%
)
    exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" "$mess" "$indent" \
      || die "Unable to close $PDB on all RAC instances"
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : openPDB
#
#  Description         : Performs the open PDB step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
# -----------------------------------------------------------------------------
#

openPDB()
{
  local PDB="$1"
  local mode="$2"
  local mess="$3"
  local indent="$4"  
    remoteCommand=$(cat <<%%
if [ ! -f /home/oracle/$CDB_NAME.env ]
then
  echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
else
  . $CDB_NAME.env
  sqlplus -s / as sysdba << SQL_AT_TARGET
whenever oserror exit failure
whenever sqlerror exit sql.sqlcode
alter pluggable database $PDB open $mode instances=all ;
show pdbs
exit success
SQL_AT_TARGET
exit \$?
fi
%%
)
    exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" "$mess" "$indent" \
      || die "Unable to open $PDB on all RAC instances"
}


openPDBReadWriteOnAllInstances()
{
  local PDB="$1"
  local indent="$2"
  local instanceList
  local instanceName
  local expectedInstances
  local openedInstances

  instanceList=$(exec_sql "$MF_TGT_CDB_CONNECT" "select instance_name from gv\$instance order by inst_id;") \
    || die "Unable to list target RAC instances"
  [ "$instanceList" != "" ] || die "No running target RAC instance was found"

  for instanceName in $instanceList
  do
    exec_sql "$MF_TGT_CDB_CONNECT" \
      "alter pluggable database $PDB open read write instances=('$instanceName');" \
      "Open $PDB READ WRITE on $instanceName" "$indent" \
      || die "Unable to open $PDB READ WRITE on $instanceName"
  done

  assertNoPendingPdbErrors "$PDB"

  expectedInstances=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(count(*)) from gv\$instance;") \
    || die "Unable to count target RAC instances"
  openedInstances=$(exec_sql "$MF_TGT_CDB_CONNECT" "
    select to_char(count(*))
    from gv\$pdbs
    where name='$PDB'
    and   open_mode='READ WRITE'
    and   restricted='NO';") || die "Unable to verify the RAC open state of $PDB"

  [ "$openedInstances" -eq "$expectedInstances" ] \
    || die "$PDB is READ WRITE and unrestricted on $openedInstances of $expectedInstances running RAC instances"
}


verifyTargetRacEnabled()
{
  local racEnabled
  racEnabled=$(exec_sql "$MF_TGT_CDB_CONNECT" "select value from v\$option where parameter='Real Application Clusters';") \
    || die "Unable to verify the target RAC option"
  [ "$racEnabled" = "TRUE" ] \
    || die "Target CDB is not RAC-enabled; RAC provisioning must be completed outside PDB Copy"
  libAction "Target CDB is already RAC-enabled; catclust.sql is not required" "$I2"
}


assertNoPendingPdbErrors()
{
  local PDB="$1"
  local allowOptionMismatch="$2"
  local errorFilter=""
  local pendingErrors
  if [ "$allowOptionMismatch" = "ALLOW_OPTION_MISMATCH" ]
  then
    errorFilter="and message not like 'Database option % mismatch:%'"
  fi
  pendingErrors=$(exec_sql "$MF_TGT_CDB_CONNECT" "
    select to_char(count(*))
    from pdb_plug_in_violations
    where name='$PDB'
    and   type='ERROR'
    and   status='PENDING'
    $errorFilter;") || die "Unable to check pending PDB plug-in errors for $PDB"

  if [ "${pendingErrors:-0}" -ne 0 ]
  then
    exec_sql -verbose "$MF_TGT_CDB_CONNECT" "
      set lines 250 pages 200 tab off head on
      col cause format a30
      col message format a120
      col action format a80
      select time,cause,error_number,message,action
      from pdb_plug_in_violations
      where name='$PDB'
      and   type='ERROR'
      and   status='PENDING'
      $errorFilter
      order by time;" "Pending PDB plug-in errors for $PDB" "$I2"
    die "$PDB has $pendingErrors pending plug-in error(s); do not continue to RAC open or switch"
  fi
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : revokeReadOnUser
#
#  Description         : Performs the revoke Read On User step used by
#                        mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

revokeReadOnUser()
{
  local db="$1"
  local pdb="$2"
  local user="$3"
  local cnx="$4"

     remoteCommand=$(cat <<%%
if [ ! -f /home/oracle/$db.env ]
then
echo "Unable to find the env file for $db"; exit 1 ;
else
. \$HOME/$db.env
id
echo \$ORACLE_SID
sqlplus -s / as sysdba <<SQL_AT_TARGET
whenever sqlerror exit failure
prompt Go to PDB : $pdb
alter session set container=$pdb ;
show pdbs
whenever sqlerror continue
revoke select on user$ from $user;
SQL_AT_TARGET
exit $?
fi
%%
)
      exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                              "Revoke select on USER$ db=$db pdb=$pdb user=$user" "$I2" || die "Unable to revoke privileges"
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : setReadOnUser
#
#  Description         : Performs the set Read On User step used by
#                        mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

setReadOnUser()
{
  local db="$1"
  local pdb="$2"
  local user="$3"
  local cnx="$4"
  mfDebugLog "Parameters : [$*]"
  exec_sql "$cnx" "select 1 from sys.user$ where rownum=1 ;" "Test if $user can read sys.user$ TARGET ($db/$pdb)" "$I1" 
  if [ $? -ne 0 ]
  then
     remoteCommand=$(cat <<%%
if [ ! -f /home/oracle/$db.env ]
then
echo "Unable to find the env file for $db"; exit 1 ;
else
. \$HOME/$db.env
id
echo \$ORACLE_SID
srvctl status service -d \$ORACLE_UNQNAME
sqlplus -s / as sysdba <<SQL_AT_TARGET
whenever sqlerror exit failure
prompt Go to PDB : $pdb
alter session set container=$pdb ;
show pdbs
col network_name format a20
select inst_id,network_name from gv\\\\\$active_services order by 2,1;
whenever sqlerror continue
grant select on user$ to $user;
SQL_AT_TARGET
exit $?
fi
%%
)

    for h in $MF_TGT_CLUSTER_HOSTS
    do
      exec_on_target -verbose "${MF_SUDOER:-opc}@$h" "oracle" "$remoteCommand" \
                              "Grant select on USER$ ($h)" "$I2" || die "Unable to grant missing privileges"
    done
    # for i in $(seq 10)
    # do
      exec_sql -verbose "$cnx" "
      select instance_name from v\$instance ;
      select 1 from sys.user$ where rownum=1 ;" "Test if $user can read sys.user$ on ($db/$pdb)(Again)" "$I2" #|| die "Unable to read SYS.USER$"
      # sleep 5
    # done
  fi
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : copyUserDefinition
#
#  Description         : Performs the copy User Definition step used by
#                        mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

copyUserDefinition()
{
  local usr="$1"
  local cup="$2"
  echo
  infoAction "Copy user definition for : $usr" "$I2"
  infoAction "From : $ref_pdb ===> to : $tgt_pdb" "$B2"
  
  libAction "$usr is using profile" "$I3"
  prof=$(exec_sql "$MF_TGT_PDB_CONNECT" "select profile from dba_users where username='$usr';")
  echo $prof
  libAction "Does $prof exists on target" "$I3"
  prof_ok="NO"
  prof_ok=$(exec_sql "$MF_TGT_TMPPDB_CONNECT" "select 'YES' from dba_profiles where profile='$prof' and rownum=1;")
  [ "$prof_ok" = "" ] && prof_ok="NO"
  echo $prof_ok 
  if [ "$prof_ok" = "NO" ]
  then
    infoAction "Get $prof DDL" "$I4"
    prof_ddl=$(exec_sql "$MF_TGT_PDB_CONNECT" "
          set long 10000 lines 10000 head off
          col ddl format a500
          begin
             dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
             dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);
          end;
          /
          select 
            dbms_metadata.get_ddl ('PROFILE','$prof') ddl
          from dual ;     ")
    # echo "$prof_ddl"
    exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" "
    . $CDB_NAME.env  || exit 1
    sqlplus / as sysdba <<_SQL_
    whenever sqlerror exit 1
    alter session set container=$tgt_pdb ;
    $prof_ddl
_SQL_
    " "Create $prof on temporary PDB (via SSH & SYSDBA on $CDB_NAME)" "$I4" || die "Unable to create profile $prof"
  fi
  
  libAction "Get Password on $ref_pdb" "$I3"
  
  # pass=$(exec_sql "$ref" "
          # set long 10000 lines 10000
          # col pass format a500
          # select 
            # regexp_replace(replace(dbms_metadata.get_ddl ('USER','$usr'),chr(10),' ')
                          # ,q'[^.*IDENTIFIED BY VALUES '([^']*)'.*$]'
                          # ,'\1'
                          # ) pass
          # from dual ;
                         # ") || die "Get on $ref_pdb\n$pass"
  pass=$(exec_on_target -tty "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$(cat <<%%
  . $CDB_NAME.env || exit 1
  echo "
          set feed off
          whenever sqlerror exit 1
          alter session set container=$ref_pdb ;
          set long 10000 lines 10000 head off
          col pass format a500
          select 
            regexp_replace(replace(dbms_metadata.get_ddl ('USER','$usr'),chr(10),' ')
                          ,q'[^.*IDENTIFIED BY VALUES '([^']*)'.*$]'
                          ,'\1'
                          ) pass
          from dual ; " | sqlplus -s / as sysdba
%%
)
                         " | sed -e "/^ *$/ d") || die "Get on $ref_pdb\n$pass"

  echo $(echo "$pass" | sed -e "s;^\(......\).*;\1xxxxx;")
  # [ "$(echo "$pass" | grep -i "IDENTIFIED")" = "" ] && { echo "Error" ; die "Unable to read the password (check that $MF_TGT_PDB_USER can read user$ en $PDB_NAME)" ; } || echo $(echo "$pass" | sed -e "s;^\(......\).*;\1xxxxx;")
    
  # libAction "Grants on source" "$I3"
  # grants=$(exec_sql "$MF_TGT_PDB_CONNECT" "
    # select listagg(cnt,' ') 
    # from (
                # select 'Object grants : '     || count(*) cnt from dba_tab_privs where grantee='$usr'
          # union select 'System privileges : ' || count(*)     from dba_sys_privs where grantee='$usr'
          # union select 'Role grants : '       || count(*)     from dba_role_privs where grantee='$usr'
         # ) ;
                         # ") || die "ERROR\n$grants"
  # echo $grants

  libAction "User existence on TARGET" "$I3"
  exist=$(exec_sql "$tgt" "select '1' from dba_users where username='$usr' ;") || die "ERROR: \n $exist"
  if [ "$exist" = "1" ]
  then
    echo "Exists"
    exec_sql "$tgt" "
  col profile new_value profile noprint
  set verify off
  select profile from dba_users where username='$usr' ;
  begin
    execute immediate 'create profile MIG_EXACC_NO_VERIF limit PASSWORD_REUSE_TIME unlimited PASSWORD_REUSE_MAX unlimited' ;
  exception
    when others then if (sqlcode = -2379) then null ; else raise ; end if ;
  end ;
  /
  
  alter user \"$usr\" profile MIG_EXACC_NO_VERIF ;
  alter user \"$usr\" identified by values '$pass';
  alter user \"$usr\" profile &profile ;

  begin
    execute immediate 'drop profile MIG_EXACC_NO_VERIF cascade' ;
  exception
    when others then if (sqlcode = -2380) then null ; else raise ; end if ;
  end ;
  /

                                      " "Set Password on temporary PDB" "$I4" || die "Unable to set password"
  else
    echo "To Create"
    user_def=$(exec_on_target -tty "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$(cat <<%%
  . $CDB_NAME.env || exit 1
  echo "
          set feed off
          whenever sqlerror exit 1
          alter session set container=$ref_pdb ;
          set long 20000 longchunksize 20000 pagesize 0 linesize 1000 feedback off verify off trimspool on feed off
column ddl format a1000
set lines 1000
begin
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);
end;
/
select replace(replace(dbms_metadata.get_ddl        ('USER'         , '$usr'),'C##','$cup'),'C__','$cup') from dual ;" | sqlplus -s / as sysdba
%%
)
" | sed -e "/^ *$/ d") || die "ERROR: \n $user_def"
    exec_sql "$MF_TGT_TMPPDB_CONNECT" "$user_def" "Create $usr user on temporary target" "$I4"   
  fi
  
  user_grants=$(exec_sql "$MF_SRC_CDB_CONNECT" "
set long 20000 longchunksize 20000 pagesize 0 linesize 1000 feedback off verify off trimspool on
column ddl format a1000
set lines 1000
begin
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);
end;
/
select dbms_metadata.get_granted_ddl('ROLE_GRANT'   , grantee) as ddl from dba_role_privs  where  grantee = '$usr' ;
select dbms_metadata.get_granted_ddl('SYSTEM_GRANT' , grantee) as ddl from dba_sys_privs where  grantee = '$usr' ;
select dbms_metadata.get_granted_ddl('OBJECT_GRANT' , grantee) as ddl from dba_tab_privs where  grantee = '$usr' ;
" | sort -u) || die "Unable to get user privs ($user_grants)"


remoteCommand=$(cat <<%%
. $CDB_NAME.env || exit 1
sqlplus -s / as sysdba <<_SQL_
alter session set container=$tgt_pdb ;
set feed on
$user_grants
_SQL_
%%
)
  exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" "Add grants to $usr" "$I4" || die "Unable to give grants"
  
       # exec_sql "$MF_TGT_TMPPDB_CONNECT" "
       # set feed on
       # $user_grants" "Add grants to $usr" "$I4" || die "Unable to give grants"
  
  
  libAction "Get Password on Temporary PDB" "$I3"
  pass=$(exec_sql "$tgt" "
          set long 10000 lines 10000
          col pass format a500
          select 
            regexp_replace(replace(dbms_metadata.get_ddl ('USER','$usr'),chr(10),' ')
                          ,q'[^.*IDENTIFIED BY VALUES '([^']*)'.*$]'
                          ,'\1'
                          ) pass
          from dual ;
                         ") || die "\n$pass"
  echo $(echo "$pass" | sed -e "s;^\(......\).*;\1xxxxx;")
  # libAction "Grants on temporary PDB" "$I3"
  # grants=$(exec_sql "$MF_TGT_TMPPDB_CONNECT" "
    # select listagg(cnt,' ') 
    # from (
                # select 'Object grants : '     || count(*) cnt from dba_tab_privs where grantee='$usr'
          # union select 'System privileges : ' || count(*)     from dba_sys_privs where grantee='$usr'
          # union select 'Role grants : '       || count(*)     from dba_role_privs where grantee='$usr'
         # ) ;
                         # ") || die "ERROR\n$grants"
  # echo $grants
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : exchangePDB
#
#  Description         : Performs the exchange PDB step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Parse command-line options and dispatch the requested action.
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - Some file paths are redirected without quotes and may fail with
#                          spaces.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

exchangePDB()
{
  local direction="$1"
  echo
  infoAction "Switching  $direction" "$I1"
  exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" ". \$HOME/$CDB_NAME.env && srvctl start service -d \$ORACLE_UNQNAME ; srvctl status service -d \$ORACLE_UNQNAME" \
                                          "Start services on target, just in case" "$I2" || die "Error starting services"
  echo
  mfRepo_updateProgress "SW_$direction"
  if [ "$direction" = "FORWARD" ]
  then
    sourcePDBname="$TMP_PDB"
    sourcePDBConnect="$MF_TGT_TMPPDB_CONNECT"
    targetPDBname="$MF_TGT_DBNAME"
    targetPDBConnect="$MF_TGT_PDB_CONNECT"
    parkedPDBname="$OLD_PDB"
    parkedPDBConnect="$MF_TGT_OLDPDB_CONNECT"

    targetOGGUser=$MF_TGT_PDB_USER
    targetOGGPassword=$MF_TGT_PDB_PASSWORD
    targetOGGTNS=$MF_TGT_PDB_TNS
  else
    sourcePDBname="$OLD_PDB"
    sourcePDBConnect="$MF_TGT_OLDPDB_CONNECT"
    targetPDBname="$MF_TGT_DBNAME"
    targetPDBConnect="$MF_TGT_PDB_CONNECT"
    parkedPDBname="$TMP_PDB"
    parkedPDBConnect="$MF_TGT_TMPPDB_CONNECT"

    targetOGGUser=$MF_TGT_TMPPDB_USER
    targetOGGPassword=$MF_TGT_TMPPDB_PASSWORD
    targetOGGTNS=$MF_TGT_TMPPDB_TNS
  fi
  if [ "$MIGRATION_METHOD" = "ONLINE_LOGICAL" ]
  then
    infoAction "Get Golden-Gate status" "$I1"
    infoAction "----------------------" "$B1"
    echo
    mfTestOGG
    echo
    if [ "$MF_TGT_REPLICA" != "" ]
    then
      infoAction "Target replicat ($MF_TGT_REPLICA) exists" "$I2"
      if [ "$MF_REPLICATION_STATE" != "NO" ]
      then
        infoAction "Replication is running" "$I2"
        OGG_WAS_RUNNING=Y
        libAction "Stopping replication" "$I3"
        $MF_BIN/mfReplMgmt.sh -m $MF_MIGRATION_ID -A STOP -D FWD >$TMPFILE2 >&1 && { echo OK ; rm -f $TMPFILE2 ; } \
                                                                                     || { echo Error ; cat $TMPFILE2 ; rm -f $TMPFILE2 ; die "Error stopping the replication" ; }
        mfTestOGG > /dev/null
      else
        OGG_WAS_RUNNING=N
      fi
      [ "$MF_REPLICATION_STATE" != "NO" ] && die "Replication is still running"
      infoAction "Replication is stopped" "$I2"
      infoAction "Change CATALOG name" "$I1"
      newConf=$(mfOGG_GetConfig $MF_TGT_REPLICA.prm | sed -e "/^MAP/ s;^\(MAP.*TARGET *\)\([^\.]*\)\(.*\)$;\1$targetPDBname\3;")
      echo "$newConf"
      mfOGG_ReplaceConfig $MF_TGT_REPLICA.prm "$newConf" "$I3"
      infoAction "Change Alias configuration for forward replication" "$I1"
      libAction "Alias" "$I2"
      CONNECTION_REPLICA=$(mfOGG_GetConnectionFromReplica  $MF_TGT_REPLICA)
      echo $CONNECTION_REPLICAT
      infoAction "Replicate to $targetOGGTNS" "$B2"
      CONNECTION_ID=$(echo "${CONNECTION_REPLICA}" | cut -d '.' -f1 | sed 's/[A-Za-z]//g')
      if [ ! -z "${CONNECTION_ID}" ]; then
        mfOGG_DeleteAlias "domain${CONNECTION_ID}" "tgtalias${CONNECTION_ID}" | sed 's/delete /Delete /gi' | egrep -v "^[[:space:]]*$"
      fi
      mfOGG_CreateAlias "${CONNECTION_ID}" "tgtalias" "${targetOGGUser}" "${targetOGGPassword}" "${targetOGGTNS}" | egrep -v "^[[:space:]]*$"
    fi
  fi
  
  tcpsFolderOrig=$(exec_sql "$MF_TGT_PDB_CONNECT" "select p.value||'/'||pdbs.guid 
                                             from v\$parameter p, v\$pdbs pdbs
                                             where p.name ='wallet_root'
                                             and   pdbs.NAME = '$targetPDBname';")
  infoAction "Original TCPS folder : $tcpsFolderOrig" "$I2" 
  exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" "[ -d $tcpsFolderOrig ] && exit 0 || exit 1" \
                   "Test for ORIGINAL TCPS Folder" "$I2" || die "The TCPS Folder for $targetPDBname does not exist"

  
  infoAction "Move the services from $targetPDBname to $sourcePDBname (before switch)" "$I2"
    remoteCommand=$(cat <<%% 
if [ ! -f /home/oracle/$CDB_NAME.env ]
then
  echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
else
  . $CDB_NAME.env
  srvctl config service -d \$ORACLE_UNQNAME | sed -e "s; *: *;:;g" |awk -F ":" '
/Service name:/ {s=\$2}
/Pluggable database name:/ {p=\$2 ; printf("%s;%s\n",s,p) }
'

fi
%%
)
  exec_on_target -tty "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" | grep -i ";$targetPDBname$" > $TMPFILE3

  while read line
  do
    srv=$(echo "$line" | cut -f1 -d ";")
    exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" ". $CDB_NAME.env && srvctl modify service -d \$ORACLE_UNQNAME -s $srv -pdb $sourcePDBname" \
                   "Move $srv to $sourcePDBname" "$I3" || die "Unable to move database service"
  done < $TMPFILE3
  rm -f $TMPFILE3  
                                                
  closePDB "$targetPDBname" "Closing $targetPDBname" "$I2"
  # openPDB  "$targetPDBname" "restricted" "Opening $targetPDBname (restricted)" "$I2"
  closePDB "$sourcePDBname" "Closing $sourcePDBname" "$I2"
  # openPDB  "$sourcePDBname" "restricted" "Opening $sourcePDBname (restricted)" "$I2"

  renamePDB "$targetPDBname" "$parkedPDBname" "Renaming $targetPDBname to $parkedPDBname" "$I2"
  closePDB "$parkedPDBname" "Closing $parkedPDBname" "$I2"
  
  renamePDB "$sourcePDBname" "$targetPDBname" "Renaming $sourcePDBname to $targetPDBname" "$I2"
  closePDB "$targetPDBname" "Closing $targetPDBname" "$I2"


  openPDB "$targetPDBname" "" "Opening $targetPDBname" "$I2"
  openPDB "$parkedPDBname" "" "Opening $parkedPDBname" "$I2"

  exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" ". \$HOME/$CDB_NAME.env && srvctl start service -d \$ORACLE_UNQNAME ; srvctl status service -d \$ORACLE_UNQNAME" \
                                          "Start services on target, just in case" "$I2" || die "Error starting services"

  tcpsFolderNew=$(exec_sql "$MF_TGT_PDB_CONNECT" "select p.value||'/'||pdbs.guid 
                                             from v\$parameter p, v\$pdbs pdbs
                                             where p.name ='wallet_root'
                                             and   pdbs.NAME = '$targetPDBname';")
  infoAction "New TCPS folder : $tcpsFolderNew" "$I2" 
  if [ "$tcpsFolderOrig" != "" -a "$tcpsFolderNew" != "" ]
  then
    exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" "mkdir -p $tcpsFolderNew && mv $tcpsFolderOrig/tls $tcpsFolderNew && exit 0 || exit 1" \
                     "Rename TCPS Folder" "$I2" || die "Error renaming TCPS Folder"
  fi
  
  exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" ". $CDB_NAME.env && srvctl start service -d \$ORACLE_UNQNAME ; exit 0" \
                   "Start services on $targetPDBname" "$I2" || die "Service Start"
  exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" ". $CDB_NAME.env && srvctl status service -d \$ORACLE_UNQNAME" \
                   "Service status on $targetPDBname" "$I2" || die "Service Status"
  testConnectionsToTarget  MF_TCP
  # testConnectionsToTarget  MF_TCPS
  # testConnectionsToTarget  DG_TCP
  # testConnectionsToTarget  DG_TCPS
  testConnectionsToTarget  APPL_TCP
  # testConnectionsToTarget  APPL_TCPS

  if [ "$OGG_WAS_RUNNING" = "Y" ]
  then  
    infoAction "Replication was running before echange" "$I2"
    libAction "Starting replication" "$I3"
    $MF_BIN/mfReplMgmt.sh -m $MF_MIGRATION_ID -A START -D FWD >$TMPFILE2 >&1 && { echo OK ; rm -f $TMPFILE2 ; } \
                                                                                  || { echo Error ; cat $TMPFILE2 ; rm -f $TMPFILE2 ; die "Error stopping the replication" ; }
  else
    infoAction "Replication was NOT running before echange" "$I2"
  fi  
}

  # ------------------------------------------------------------------------------------------------------


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_STATUS
#
#  Description         : Performs the DO STATUS step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Prepare local variables and perform the operation described above.
#
#  Possible issues     : 
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_STATUS() 
{ 
  startStep "DO_STATUS : PDB_COPY /ROLLING_PDB_COPY status"
  $MF_BIN/mfDbActions.sh -m $MF_MIGRATION_ID -A STATUS || die "unable to show database status"
  if [ "$MF_PDB_COPY_RUN_STATE" = "COPY" ]
  then
    cnx="$MF_TGT_TMPPDB_CONNECT"
    pdb=$TMP_PDB
  else
    cnx="$MF_TGT_PDB_CONNECT"
    pdb=$MF_TGT_DBNAME
  fi
  echo 
  mfDefragTbsContents
  testConnectionsToTarget
  pdbCopyStatus
  endStep
  endRun
} 


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_DROP
#
#  Description         : Performs the DO DROP step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_DROP() 
{
  if [ "$DO_DROP" = "Y" ]
  then
    [ "$MF_PDB_COPY_RUN_STATE" = "SWITCHED" -o "$MF_PDB_COPY_RUN_STATE" = "INITIAL" ] && die "Invalid status ($MF_PDB_COPY_RUN_STATE) for DROP temporary PDB operation"
    startStep "DO_DROP : Drop temporary database"
    mfRepo_updateProgress DROP

    infoAction "Drop Database" "$I1"
    infoAction "-------------" "$B1"
    echo    
    closePDB "$TMP_PDB" "Close temporary PDB" "$I2"

    remoteCommand=$(cat <<%%
if [ ! -f /home/oracle/$CDB_NAME.env ]
then
  echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
else
  . $CDB_NAME.env
  sqlplus -s / as sysdba << SQL_AT_TARGET
whenever oserror exit failure
whenever sqlerror exit sql.sqlcode
drop pluggable database $TMP_PDB including datafiles ;
exit success
SQL_AT_TARGET
exit \$?
fi
%%
)
    exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" "Drop pluggable database $TMP_PDB" "$I2" \
      || die "Unable to drop temporary PDB $TMP_PDB"

    if [ "$ROLLING_PDB_COPY" = "Y" ]
    then
      infoAction "Remove a temporary DB on NODE 1" "$I1"
      infoAction "-------------------------------------" "$B1"

      rollingDBAction "shutdown abort"
      remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    rm -f \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    rm -rf /acfs01/app_acfs/$ROLLING_DB
    sed -i "/^MF_${MF_SRC_DBNAME}=/ d" \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora
    [ -f \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora ] || echo "Non existent"
    exit 0
%%
)


      libAction "Rolling database Status" "$I2"
      rollingDBStatus=$(exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" oracle "$remoteCommand") || die "Unable to get rolling database status ($?)\n $rollingDB"
      echo $rollingDBStatus
    
      remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    asmcmd --privilege sysdba rm -rf $targetDg/$ROLLING_DB
%%
)
      exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" oracle "$remoteCommand" "Remove old datafiles" "$I2" 
    fi
  fi
} 

  
  # ------------------------------------------------------------------------------------------------------


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : rollingDBAction
#
#  Description         : Performs the rolling DBAction step used by
#                        mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
# -----------------------------------------------------------------------------
#

rollingDBAction()
{
  local action="$1"
  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo "$action" | sqlplus -s / as sysdba
%%
)
  exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "$action on $ROLLING_DB database" "$I2"
}

  # ALLOCATE CHANNEL ch09 DEVICE TYPE DISK;
  # ALLOCATE CHANNEL ch10 DEVICE TYPE DISK;
  # ALLOCATE CHANNEL ch11 DEVICE TYPE DISK;
  # ALLOCATE CHANNEL ch12 DEVICE TYPE DISK;
  # ALLOCATE CHANNEL ch13 DEVICE TYPE DISK;
  # ALLOCATE CHANNEL ch14 DEVICE TYPE DISK;
  # ALLOCATE CHANNEL ch15 DEVICE TYPE DISK;
  # ALLOCATE CHANNEL ch16 DEVICE TYPE DISK;


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : rollingRestore
#
#  Description         : Performs the rolling Restore step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

rollingRestore()
{
  local action="$1"

  new_names=$(exec_sql "$MF_SRC_PDB_CONNECT" "select 'set newname for datafile ' || file# || ' to ''+$targetDg'' ; ' from v\$datafile ;")
  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    [ -f \$ORACLE_HOME/network/admin/tnsnames.ora.orig ] || { cp -p \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora.orig || exit 1 ; }
    sed -i "/^MF_${MF_SRC_DBNAME}=/ d" \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora || exit 1
    echo "MF_${MF_SRC_DBNAME}=$MF_SRC_PDB_TNS" >> \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora || exit 1
    rman target / <<_RMAN_
RUN
{ 
  $new_names
  ALLOCATE CHANNEL ch01 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch02 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch03 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch04 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch05 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch06 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch07 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch08 DEVICE TYPE DISK;
  restore database from service 'MF_${MF_SRC_DBNAME}';
}
_RMAN_
%%
)
  exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Restore $ROLLING_DB database" "$I2" || die "Error restoring the database"

  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    rman target / <<_RMAN_
    switch database to copy ;
%%
)
  exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Switch database to COPY" "$I2" || die "Switch to copy error"


}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : rollingRecover
#
#  Description         : Performs the rolling Recover step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Run remote operations on the configured host when required.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - Remote operations depend on SSH access and the configured target
#                          account.
# -----------------------------------------------------------------------------
#

rollingRecover()
{
  local action="$1"
  
  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    [ -f \$ORACLE_HOME/network/admin/tnsnames.ora.orig ] || { cp -p \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora.orig || exit 1 ; }
    sed -i "/^MF_${MF_SRC_DBNAME}=/ d" \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora || exit 1
    echo "MF_${MF_SRC_DBNAME}=$MF_SRC_PDB_TNS" >> \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora || exit 1
    rman target / <<_RMAN_
    delete noprompt archivelog all ;
RUN
{ 
  ALLOCATE CHANNEL ch01 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch02 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch03 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch04 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch05 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch06 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch07 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch08 DEVICE TYPE DISK;
  recover database from service 'MF_${MF_SRC_DBNAME}';
}
_RMAN_
%%
)
  exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Recover $ROLLING_DB database" "$I2"
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : createRollingDBControlFileAfterCopy
#
#  Description         : Performs the create Rolling DBControl File After Copy
#                        step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

createRollingDBControlFileAfterCopy()
{
  
  mfRepo_updateProgress LAST_CTRFILE
  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    cp \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora.ok
    sed -i "/control_files/ d" \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    sqlplus -s / as sysdba << _SQL_
    shutdown immediate
    startup nomount pfile='?/dbs/init_$ROLLING_DB.ora'
_SQL_
%%
)
  exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Stop database $ROLLING_DB and restart (nomount)" "$I2" || die "Unable to start the DB in mount mode"

  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    rman target / << _RMAN_
    restore standby controlfile from service 'MF_${MF_SRC_DBNAME}';
_RMAN_
%%
)
  exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Recreate the controlfile" "$I2" | tee $TMPFILE2
  [ $? -ne 0 ] && die "Unable to recreate the controlfile"

  libAction "Control file" "$I2"
  control_file=$(grep "output file name" $TMPFILE2 | cut -f2 -d"=")
  echo $control_file
  
  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo "control_files=($control_file)"        >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    echo "shutdown immediate" | sqlplus -s / as sysdba
    echo "startup mount pfile='?/dbs/init_$ROLLING_DB.ora'" | sqlplus -s / as sysdba || exit 1
    rman target / << _RMAN_
    catalog start with '+$targetDg/$ROLLING_DB' noprompt;
_RMAN_
%%
)
  exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Start database $ROLLING_DB (mount) and catalog files" "$I2"

  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    rman target / << _RMAN_
    switch database to copy ;
_RMAN_
%%
)
  exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Switch database to copy" "$I2"
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : createRollingDB
#
#  Description         : Performs the create Rolling DB step used by
#                        mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - Some file paths are redirected without quotes and may fail with
#                          spaces.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

createRollingDB()
{
  #
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  #
  #     Create a basic standalone (non rac) DB which is only used to perform rolling
  # restore of the source DB. This database is not known from the clusterware and from
  # the cloud. If the machine crashed, th migration is lost.
  #
  #     if there are not enough HUGPAGES on the target machine, the db will not start
  # either stop one of the DATABASES or add 4 GB Husge pages : 2048 HP
  #
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  #
  libAction "Source block size is" "$I2"
  block_size=$(exec_sql "$MF_SRC_PDB_CONNECT" "select value from v\$parameter where name='db_block_size';")
  libAction "Source string size is" "$I2"
  string_size=$(exec_sql "$MF_SRC_PDB_CONNECT" "select value from v\$parameter where name='max_string_size';")
  echo $string_size
  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    echo "db_name=$MF_SRC_DBNAME"               >  \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    echo "db_unique_name=$ROLLING_DB"           >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    echo "db_files=4096"                        >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    # echo "sga_target=1230M"                        >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    echo "sga_target=5G"                        >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
#    echo "cpu_count=1"                         >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    echo "db_create_file_dest=+$targetDg"       >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    echo "compatible=19.0.0"                    >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    echo "_client_enable_auto_unregister=TRUE"  >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    echo "_emon_send_timeout=5000"              >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    echo "db_files=4096"                        >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    if [ "$block_size" != "" ]
    then
      echo "db_block_size=$block_size"                        >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    fi
    if [ "$string_size" != "" ]
    then
      echo "max_string_size=$string_size"                        >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    fi
%%
)
  exec_on_target "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Create Rolling DB init file" "$I2" || die "Error"
  srcDUN=$(exec_sql "$MF_SRC_PDB_CONNECT" "select db_unique_name from v\$database;") || die "$srcDUN"

  libAction "Copy Password file to target" "$I2" 
  scp -q $MF_HOME/data/pwdfiles/orapw${srcDUN} ${MF_SUDOER:-opc}@$targetNode1:/tmp/orapw$ROLLING_DB > $TMPFILE1 \
     && { echo "Ok" ; rm -f $TMPFILE1 ; } \
     || { echo "Error" ; cat $TMPFILE1 ; rm -f $TMPFILE1 ; die "Unable to copy the password file" ; } 
  exec_on_target "${MF_SUDOER:-opc}@$targetNode1" "" "chmod 775 /tmp/orapw$ROLLING_DB"
  exec_on_target "${MF_SUDOER:-opc}@$targetNode1" "oracle" ". $CDB_NAME.env && cp /tmp/orapw$ROLLING_DB \$ORACLE_HOME/dbs || exit 1"
  exec_on_target "${MF_SUDOER:-opc}@$targetNode1" "" "rm -f /tmp/orapw$ROLLING_DB"

  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    [ -f \$ORACLE_HOME/network/admin/tnsnames.ora.orig ] || { cp -p \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora.orig || exit 1 ; }
    sed -i "/^MF_${MF_SRC_DBNAME}=/ d" \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora || exit 1
    echo "MF_${MF_SRC_DBNAME}=$MF_SRC_PDB_TNS" >> \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora || exit 1
%%
)
  exec_on_target "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Add TNS entry (copy service: MF_${MF_SRC_DBNAME})" "$I2"

  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo "
    whenever sqlerror exit failure
    startup nomount pfile='?/dbs/init_$ROLLING_DB.ora'" | sqlplus -s / as sysdba || exit 1
%%
)
  exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Start database $ROLLING_DB (nomount)" "$I2" || die "Unable to start auxiliary DB ($ROLLING_DB)"

  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo "restore standby controlfile from service 'MF_${MF_SRC_DBNAME}';" | rman target /
%%
)
  exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Restore controlfile from (MF_${MF_SRC_DBNAME})" "$I2" | tee $TMPFILE2
  libAction "Control file" "$I2"
  control_file=$(grep "output file name" $TMPFILE2 | cut -f2 -d"=")
  echo $control_file
  
  remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo "control_files=($control_file)"        >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    echo "shutdown immediate" | sqlplus -s / as sysdba
    echo "startup mount pfile='?/dbs/init_$ROLLING_DB.ora'" | sqlplus -s / as sysdba
    echo "alter database flashback off ; " | sqlplus -s / as sysdba
%%
)
  exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Start database $ROLLING_DB (mount)" "$I2"

} 


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_INIT
#
#  Description         : Performs the DO INIT step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_INIT() 
{ 
  [ "$MF_PDB_COPY_RUN_STATE" != "INITIAL" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with INIT operations"
  startStep "DO_INIT : Prepare and check (ROLLING_PDB_COPY=$ROLLING_PDB_COPY)"
  mfRepo_updateProgress INIT

  if [ "$ROLLING_PDB_COPY" = "Y" ]
  then
    infoAction "Create/Start a temporary DB on NODE 1" "$I1"
    infoAction "-------------------------------------" "$B1"

    rollingDBAction "shutdown abort"
    remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    rm -f \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    rm -rf /acfs01/app_acfs/$ROLLING_DB
    sed -i "/^MF_${MF_SRC_DBNAME}=/ d" \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora
    [ -f \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora ] || echo "Non existent"
    exit 0
%%
)


    libAction "Rolling database Status" "$I2"
    rollingDBStatus=$(exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" oracle "$remoteCommand") || die "Unable to get rolling database status ($?)\n $rollingDB"
    echo $rollingDBStatus
    
    remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    asmcmd --privilege sysdba rm -rf $targetDg/$ROLLING_DB
%%
)
    exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" oracle "$remoteCommand" "Remove old datafiles" "$I2" 
    if [ "$rollingDBStatus" = "Non existent" ]
    then
      createRollingDB
    else
      echo "$rollingDBStatus"
    fi
      
    
  else
    infoAction "Prepare target CDB" "$I1"
    infoAction "------------------" "$B1"
    echo    
    exec_sql -no_error "$MF_TGT_CDB_CONNECT" "
    set term off 
    whenever sqlerror continue
    drop database link $COPY_DB_LINK ;
      " "Drop the copy database Link in TARGET CDB" "$I2"
      
    mfDebugLog "create database link $COPY_DB_LINK connect to $MF_SRC_PDB_USER identified by \"$MF_SRC_PDB_PASSWORD\" using  '$MF_SRC_PDB_TNS' ;" 
    exec_sql "$MF_TGT_CDB_CONNECT" "
    alter system set global_names=FALSE ;
    create database link $COPY_DB_LINK connect to $MF_SRC_PDB_USER identified by \"$MF_SRC_PDB_PASSWORD\" using  '$MF_SRC_PDB_TNS' ;
      " "Create the copy database Link in TARGET CDB" "$I2"
      
    infoAction "Test initial Conditions on Source Database" "$I2"
    libAction "User must have the CREATE PLUGGABLE DATABASE privilege" "$I3"
    tmp=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(count(*)) from user_sys_privs@$COPY_DB_LINK where privilege='CREATE PLUGGABLE DATABASE' ;") || die "ERROR: \n$tmp"
    [ "$tmp" != "0" ] && echo "OK" || die "Source user must have the CREATE PLUGGABLE DATABASE privilege granted"     

    libAction "Version must be >=19c" "$I3"
    tmp=$(exec_sql "$MF_TGT_CDB_CONNECT" "select version_full from v\$instance@$COPY_DB_LINK  ;") || die "ERROR: \n$tmp"
    echo $tmp
    [ $(echo "${tmp}0.0" | cut -f1 -d ".") -lt 19 ] && die "Source DB version is too low"
    
    endStep
  fi 
  MF_PDB_COPY_RUN_STATE="INITIAL"
} 


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : getAL
#
#  Description         : Performs the get AL step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Not applicable.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
# -----------------------------------------------------------------------------
#

getAL()
{
  local file="$1"
  local dest="$2"
  dir=$(dirname $file)
  f=$(basename $file)
  # We use the "real" target since the temportry DB is not opened'
  exec_sql "$MF_SRC_PDB_CONNECT" "create or replace directory MF_SRC_ALCOPY as '$dir';" "Create oracle $dir at source" "$I3"
  exec_sql "$MF_TGT_PDB_CONNECT" "create or replace directory MF_TGT_ALCOPY as '$dest';" "Create oracle directory at target ($dest)" "$I3"
  copyFile $f MF_SRC_ALCOPY MF_TGT_ALCOPY
}
  
  # ------------------------------------------------------------------------------------------------------


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_SYNCH_COPY
#
#  Description         : Performs the DO SYNCH COPY step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_SYNCH_COPY()
{
  [ "$MF_PDB_COPY_RUN_STATE" != "COPY" -a "$FORCE" = "N" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with SYNCH_COPY operations"
  startStep "DO_SYNCH_COPY : Roll forward the copied database"
  mfRepo_updateProgress ROLL_FWD

      remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo "Stop managed recovery"
    echo -e "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;" | sqlplus -s / as sysdba
%%
)
      echo
      exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Stop managed recovery (if any)" "$I2"  || die "Error recovering copy"


  if [ "$ROLLING_PDB_COPY" = "Y" ]
  then
    export PDB_COPY_PHASE=ROLLING_RECOVER
    rollingRecover
    
      remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo "
      set head off
      set lines 200
      select to_char(max(checkpoint_time),'dd/mm/yyyy hh24:mi:ss') from v\\\\\$datafile_header;" | sqlplus -s / as sysdba
%%
)
      echo
      mfRepo_updateProgress GET_PITR
      dat=$(exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand")  || die "Error retriving last date"
     OUT_MESSAGE="Temporary PDB rolled forward to : $dat"
     echo "
         $OUT_MESSAGE
          "
  fi
  endStep
}

DO_UNPLUG_PLUG()
{

  infoAction "UNPLUG & PLug in the Normal CDB" "$I1"
  
      mfRepo_updateProgress CHECK_CDB
        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
srvctl status database -d \$ORACLE_UNQNAME
exit  \$?
%%
)
  infoAction "Check target CDB status" "$I2"
  dbStatus=$(exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand")
  echo "$dbStatus"
  [ $(echo "$dbStatus" | grep "is running" | wc -l) -ne 2 ] && die "Target CDB is not healthy, fix the problem and retry with : \n\n$SCRIPT -m $MF_MIGRATION_ID -S \"DO_UNPLUG_PLUG DO_SETUP DO_USERS DO_OGG DO_SWITCH DO_ADD_STEPS\"\n"

     
      mfRepo_updateProgress PLUG_IN
        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
sqlplus -s / as sysdba <<_SQL_
shutdown immediate ;
whenever sqlerror exit failure

STARTUP OPEN READ ONLY pfile='?/dbs/init_$ROLLING_DB.ora';

BEGIN
  DBMS_PDB.DESCRIBE(
  pdb_descr_file => '/acfs01/app_acfs/$ROLLING_DB.xml');
END;
/
shutdown immediate ;
_SQL_
exit \$?
%%
)
        exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" \
                       "Prepare DB for plug into the CDB" "$I2" || die "ERROR describing the retryable with \n$SCRIPT -m $MF_MIGRATION_ID -S \"DO_UNPLUG_PLUG DO_SETUP DO_USERS DO_OGG DO_SWITCH DO_ADD_STEPS\""


        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
sqlplus -s / as sysdba <<_SQL_
whenever sqlerror exit failure
set timing on
create pluggable database $TMP_PDB USING '/acfs01/app_acfs/$ROLLING_DB.xml' MOVE STANDBYS=NONE;
_SQL_
%%
exit \$?
)
        exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Plug DB Copy into the CDB" "$I2"  || die "ERROR Creating the 'Z' PDB  the retryable with \n$SCRIPT -m $MF_MIGRATION_ID -S \"DO_UNPLUG_PLUG DO_SETUP DO_USERS DO_OGG DO_SWITCH DO_ADD_STEPS\""
        postCopyActions 
}

#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_END_COPY
#
#  Description         : Performs the DO END COPY step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_END_COPY()
{
  [ "$MF_PDB_COPY_RUN_STATE" != "COPY" -a "$FORCE" = "N" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with END_COPY operations"
  startStep "DO_END_COPY : Finish rolling copy and create the temporary PDB"


  if [ "$ROLLING_PDB_COPY" = "Y" ]
  then
    remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    [ -f \$ORACLE_HOME/network/admin/tnsnames.ora.orig ] || { cp -p \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora.orig || exit 1 ; }
    sed -i "/^MF_${MF_SRC_DBNAME}=/ d" \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora || exit 1
    echo "MF_${MF_SRC_DBNAME}=$MF_SRC_PDB_TNS" >> \$ORACLE_HOME/network/admin/$CDB_NAME/tnsnames.ora || exit 1
    sqlplus -s / as sysdba <<_SQL_
   set pages 0 head off feed off
   select open_mode from v\\\\\$database;
_SQL_
%%
)
    libAction "Temporary database open mode" "$I2"
    MODE=$(exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand")  || die "get open mode \n$MODE"
    echo $MODE
  
    if [ "$MODE" = "MOUNTED" ]
    then

      echo

      infoAction "Last recover" "$I1"
      infoAction "============" "$B1"
      echo

      mfRepo_updateProgress LAST_ROLL_FWD
      remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo "Stop managed recovery"
    echo -e "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;" | sqlplus -s / as sysdba
%%
)
      echo
      exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Stop managed recovery (if any)" "$I2"  || die "Error recovering copy"


      rollingRecover

      exec_sql "$MF_SRC_PDB_CONNECT" "alter system archive log current;" "Archive current log" "$I2"
    

      createRollingDBControlFileAfterCopy

      remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    sqlplus -s / as sysdba <<_SQL_
   set pages 0 head off feed off
   col scn format 999999999999999999
   select  min(FHSCN) scn from X\\\\\$KCVFH ;
_SQL_
%%
)
      libAction "Gets SCN of the oldest datafile" "$I2"
      SCN=$(exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand")  || die "get oldest SCN in copy \n$SCN"
      echo $SCN
      
      mfRepo_updateProgress COPY_AL
      echo
      infoAction "Copy archivelogs and catalog them" "$I1"
      infoAction "=================================" "$B1"
      echo
      exec_on_target "${MF_SUDOER:-opc}@$targetNode1" "oracle" "rm -rf /acfs01/app_acfs/$ROLLING_DB && mkdir -p /acfs01/app_acfs/$ROLLING_DB" "Create /acfs01/app_acfs/$ROLLING_DB" "$I2"
      min_seq=999999999999
      for tmp in $(exec_sql "$MF_SRC_PDB_CONNECT" "
  select 
    name || ';' || sequence#
  from v\$archived_log 
  where 
        deleted='NO' 
    and IS_RECOVERY_DEST_FILE='YES'                                      
    and ($SCN) between first_change# and next_change#
  order by sequence# desc
  /
    ")
      do
        f=$(echo "$tmp" | cut -f 1 -d";")
        seq=$(echo "$tmp" | cut -f 2 -d";")
        [  $seq -lt $min_seq ] && min_seq=$seq
        infoAction "$f" "$I2"
        getAL $f /acfs01/app_acfs/$ROLLING_DB
      done
      remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo -e "catalog start with '/acfs01/app_acfs/$ROLLING_DB' NOPROMPT ;" | rman target /
%%
)
      exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Catalog AL from /acfs01/app_acfs/$ROLLING_DB" "$I2"  || die "Error cataloging archive logs"

      mfRepo_updateProgress MANAGED_RECO
      remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo -e "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;" | sqlplus -s / as sysdba
%%
)
      echo
      exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Start managed recovery" "$I2"  || die "Error recovering copy"

      remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
sqlplus -s / as sysdba <<_SQL_
set head off 
select min(checkpoint_change#)||';'||count(distinct checkpoint_change#) from v\\\\\$datafile_header;
_SQL_
%%
)
      infoAction "Wait for consitency (max 30 minutes)" "$I2"
      i=1
      nb=2
      copied=0
      while [ $nb -gt 1 -a $i -le 60 ]
      do
        libAction "$(date) - Distinct SCN ..." "$I3"
        sleep 30
        tmp=$(exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" | tr '\n' ' ')
        min=$(echo "$tmp" | cut -f1 -d";")
        nb=$(echo "$tmp" | cut -f2 -d";")
        echo "$nb (oldest SCN: $min)"
        cmd=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
        sqlplus -s / as sysdba <<_SQL_
        select process, status, thread#, sequence# from v\\\\\$managed_standby order by 1;
_SQL_
%%
)       
        exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$cmd" "MRP Status" "$I3"
        cmd=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
        sqlplus -s / as sysdba <<_SQL_
        set pages 0 feed off
        select min(sequence#) from v\\\\\$managed_standby where status='WAIT_FOR_GAP' ;
_SQL_
%%
)       
        missing=$(exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$cmd")
        
        cmd=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
        sqlplus -s / as sysdba <<_SQL_
        set pages 0 feed off
        select min(sequence#) from v\\\\\$managed_standby where status='WAIT_FOR_LOG' ;
_SQL_
%%
)       
        waiting_for_log=$(exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$cmd")

        [ "$waiting_for_log" = "" ] && waiting_for_log=99999999999
        [ $waiting_for_log -ne $min_seq ] && missing=$waiting_for_log
        
        infoAction "REDO needed" "$I3" ; echo $missing
        if [ "$missing" != "" -a $copied -lt 5 ]
        then
          infoAction "Copy missing REDO LOGS (From : $missing)" "$I3"
          for f in $(exec_sql "$MF_SRC_PDB_CONNECT" "
  select 
    name
  from v\$archived_log 
  where 
        deleted='NO' 
    and IS_RECOVERY_DEST_FILE='YES'                                      
    and sequence# >= $missing
  order by sequence# asc
  /
    ")
          do
            infoAction "$f" "$I4"
            getAL $f /acfs01/app_acfs/$ROLLING_DB #> /dev/null
          done
          cmd=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo -e "catalog start with '/acfs01/app_acfs/$ROLLING_DB' NOPROMPT ;" | rman target /
%%
)
          exec_on_target "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$cmd" "Catalog AL from /acfs01/app_acfs/$ROLLING_DB" "$I2"  || die "Error cataloging archive logs"
          copied=$(($copied + 1))
        fi
        
        i=$(($i + 1))
      done


      
      remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo -e "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;" | sqlplus -s / as sysdba
%%
)
      echo
      exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Stop managed recovery" "$I2"  || die "Error recovering copy"


      remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    sqlplus / as sysdba <<_SQL_
set pages 2000 lines 250 tab off
col checkpoint_change# format 999999999999999999
select open_mode from v\\\\\$database ;
select file#,fuzzy, status, recover, checkpoint_change#, to_char(checkpoint_time,'dd/mm/yyyy hh24:mi:ss') 
from v\\\\\$datafile_header order by  checkpoint_time desc ;
_SQL_
%%
)
      exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Database status SCN of datafiles" "$I2"  || die "Error recovering copy"

      exec_on_target "${MF_SUDOER:-opc}@$targetNode1" "oracle" "rm -rf /acfs01/app_acfs/$ROLLING_DB" "Removing remote AL folder" "$I2"

      if [ $nb -eq 1 ]
      then      
        echo 
        echo "
        +==================================================================================================+
        | Temporary database is consistent and can be opened                                               |
        +==================================================================================================+
        "
        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
sqlplus -s / as sysdba <<_SQL_
set head off 
col checkpoint_change# format 999999999999999999
select distinct checkpoint_change# from v\\\\\$datafile_header;
_SQL_
%%
)
        COPY_SCN=$(exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" | tr '\n' ' ')
        libAction "For ONLINE migration, start the REPLICAT at SCN" "$I2"
        echo $COPY_SCN
    
        exec_sql "$MF_REPO_CONNECT" "update migration_attempts 
                                 set switch_op_scn=$COPY_SCN
                                 ,   last_switch_op='INIT_LOAD'
                                 where mig_id=$MFAUTO_MIG_ID ;" "Store INITIAL LOAD SCN ($COPY_SCN) in migration attempt #$MFAUTO_MIG_ID" "$I3"

       #
       #    And NOW ...... Open the database
       #

      mfRepo_updateProgress OPEN_DB
        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
sqlplus -s / as sysdba <<_SQL_
set serveroutput on
begin
  for rec in (select distinct group# grp from v\\\\\$logfile)
  loop
    dbms_output.put_line ('Dropping log group ' || rec.grp) ;
    execute immediate 'alter database drop logfile group ' || rec.grp ;
  end loop ;
end ;
/
_SQL_
%%
)
        exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Drop old REDOLOG GROUPS" "$I3"

        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
sqlplus -s / as sysdba <<_SQL_
alter database add logfile group 1 ;
alter database add logfile group 2 ;
alter database add logfile group 3 ;
_SQL_
%%
)
        exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Create new REDOLOG GROUPS" "$I3"


        tag=MF_$$_$(date +%Y%m%d_%H%M%S)
        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
sqlplus -s / as sysdba <<_SQL_
whenever sqlerror exit failure
Alter session set tracefile_identifier='$tag' ;
alter database backup controlfile to trace resetlogs ;
_SQL_
exit $?
%%
)
        exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "backup controlfile to trace" "$I3"

        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    bf=\$(ls \$ORACLE_BASE/diag/rdbms/\${ORACLE_SID,,}/\$ORACLE_SID/trace/*${tag}.trc)
    test -f \$bf || { echo "backup of controlfile not found" ; exit 1 ; }
    echo "shutdown immediate"  | sqlplus -s / as sysdba
    echo "startup nomount pfile='?/dbs/init_$ROLLING_DB.ora';"  | sqlplus -s / as sysdba
    echo "Control file backup is : \$bf"
   sed -e "1,/STARTUP/ d" -e "/-- STANDBY LOGFILE/ d" -e "/--/,$ d"  \$bf | sqlplus -s / as sysdba
exit $?
%%
)
        exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Create the control file"
        
        libAction "New controlFile" "$I2"
        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
   echo "
   set head off pages 0
   select name from v\\\\\$controlfile;" | sqlplus -s / as sysdba
exit $?
%%
)
        cf=$(exec_on_target -tty "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand")
        echo $cf


        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    sed -i "/control_files/ d" \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
    echo "control_files=($cf)" >> \$ORACLE_HOME/dbs/init_$ROLLING_DB.ora
%%
)
        exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Update init.ora"
        

        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    echo "alter database open resetlogs;" | sqlplus -s / as sysdba
%%
)
        exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Open RESTELOGS"

        MODE="READ WRITE"   
      fi
   fi
   

   if [ "$MODE" = "READ WRITE" ]
   then
      mfRepo_updateProgress DATAPATCH
     echo
     infoAction "Copy to PDB" "$I1"
     infoAction "===========" "$B1"
     echo
        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
sqlplus -s / as sysdba <<_SQL_
create bigfile temporary tablespace MF_TEMP ;
alter database default temporary tablespace MF_TEMP ;
set serveroutput on
begin
  for rec in (select tablespace_name from dba_tablespaces where contents = 'TEMPORARY' and tablespace_name != 'MF_TEMP')
  loop
    dbms_output.put_line ('Dropping tablespace ' || rec.tablespace_name) ;
    execute immediate 'drop tablespace ' || rec.tablespace_name ;
  end loop ;
end ;
/
alter tablespace MF_TEMP rename to temp ;
_SQL_
%%
)
        exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Create a new TEMP TABLESPACE" "$I2"

        remoteCommand=$(cat <<%%
      . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
    datapatch -verbose
%%
)
        exec_on_target -verbose "${MF_SUDOER:-opc}@$targetNode1" "oracle" "$remoteCommand" "Run DATAPATCH (takes 20-30 minutes)" "$I2"

   #
   #  This can be a resume point
   #
   DO_UNPLUG_PLUG

   fi

  fi
  endStep
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_ROLLING_INFO
#
#  Description         : Performs the DO ROLLING INFO step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Not applicable.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Prepare local variables and perform the operation described above.
# -----------------------------------------------------------------------------
#

DO_ROLLING_INFO()
{
remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
    export ORACLE_SID=$ROLLING_DB || exit 1
_SQL_
%%
)
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : postCopyActions
#
#  Description         : Performs the post Copy Actions step used by
#                        mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

postCopyActions()
{
    if [ "$MIGRATION_METHOD" = "ONLINE_LOGICAL" ] 
    then
      infoAction "Start Forward Replication" "$I1"
      infoAction "-------------------------" "$B1"
      echo    
      if [ "$MF_SRC_EXTRACT" != "" ]
      then
        [ "$(mfOGG_StatusExtract $MF_SRC_EXTRACT)" != "running" ] \
             && mfOGG_StartExtract $MF_SRC_EXTRACT "$I2"
        i=0
        while [ $i -lt 20 -a "$(mfOGG_StatusExtract $MF_SRC_EXTRACT)" != "running" ]
        do
          infoAction "Waiting (10 minutes max) for $MF_SRC_EXTRACT to start" "$I3"
          sleep 30
          i=$(($i + 1))
        done
        [ $i -ge 20 ] && echo "   WARNING : $MF_SRC_EXTRACT not retarted"
      fi
    else
      infoAction "Remove temporary extract if needed" "$I1"
      infoAction "----------------------------------" "$B1"
      echo    
      if [ "$MF_SRC_EXTRACT" != "" ]
      then
        [ "$(mfOGG_StatusExtract $MF_SRC_EXTRACT)" != "stopped" ] \
             && mfOGG_StopExtract $MF_SRC_EXTRACT "$I2"
        i=0
        while [ $i -lt 20 -a "$(mfOGG_StatusExtract $MF_SRC_EXTRACT)" != "stopped" ]
        do
          infoAction "Waiting (10 minutes max) for $MF_SRC_EXTRACT to stop" "$I3"
          sleep 30
          i=$(($i + 1))
        done
        [ $i -ge 20 ] && echo "   WARNING : $MF_SRC_EXTRACT not retarted"
        mfOGG_DeleteExtract $MF_SRC_EXTRACT "$I2"
      fi
    fi
    echo    
  if [ "$ROLLING_PDB_COPY" != "Y" ]
  then
    infoAction "Copy results" "$I1"
    infoAction "------------" "$B1"
    echo    
      
    remoteCommand=$(cat <<%%
  if [ ! -f /home/oracle/$CDB_NAME.env ]
  then
    echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
  else
    . $CDB_NAME.env
    sqlplus -s / as sysdba << SQL_AT_TARGET
      show pdbs
      alter session set container = $TMP_PDB ;
      
      set lines 200 pages 200 tab off 
      col name               format a50
      col creation_change    format 999999999999
      col checkpoint_change  format 999999999999
      col offline_change     format 999999999999
      col online_change      format 999999999999
      col last_change        format 999999999999

      Prompt
      Prompt Datafile list (at creation)
      Prompt ===========================
      Prompt
      select 
         regexp_replace(name,'^([^/]*)/(.*)/([^/]*)$','\1/ ... /\3') name
        ,creation_change#                                            creation_change
        ,checkpoint_change#                                          checkpoint_change      
        ,offline_change#                                             offline_change
        ,online_change#                                              online_change
        ,last_change#                                                last_change
      from 
        v\\\\\$datafile ;

      Prompt
      Prompt Changes (at creation)
      Prompt ==============================
      Prompt
      
      select distinct 
         creation_change#                                            creation_change
        ,checkpoint_change#                                          checkpoint_change      
        ,offline_change#                                             offline_change
        ,online_change#                                              online_change
        ,last_change#                                                last_change
      from 
        v\\\\\$datafile ;
SQL_AT_TARGET
fi
%%
)
    exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" "Datafiles and Changes after creation" "$I2" || die "Error reading changes"
    
    
    remoteCommand=$(cat <<%%
  if [ ! -f /home/oracle/$CDB_NAME.env ]
  then
    echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
  else
    . $CDB_NAME.env
    sqlplus -s / as sysdba << SQL_AT_TARGET
      set feed off
      set pages 0
      set head off
      whenever sqlerror exit failure
      alter session set container = $TMP_PDB ;
      select distinct 'START_REPLICAT;' || offline_change# from v\\\\\$datafile;
SQL_AT_TARGET
  fi
%%
)
    echo
    
    infoAction "Get information to start the replicat if needed" "$I2"
    info=$(exec_on_target -tty "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand") || dir "ERROR: \n $info"
    [ $(echo "$info" | grep START_REPLICAT |wc -l) -ne 1 ] && die "There is a problem, cannot determine replication start SCN" 
    start_replicat=$(echo "$info" | grep START_REPLICAT | cut -f2 -d ";")
    libAction "For ONLINE migration, start the REPLICAT at SCN" "$I2"
    echo $start_replicat
    
    exec_sql "$MF_REPO_CONNECT" "update migration_attempts 
                                 set switch_op_scn=$start_replicat
                                 ,   last_switch_op='INIT_LOAD'
                                 where mig_id=$MFAUTO_MIG_ID ;" "Store INITIAL LOAD SCN ($start_replicat) in migration attempt #$MFAUTO_MIG_ID" "$I3"
    

 fi
    echo    
    infoAction "Convert, datapatch and OPEN (allow 20-30 minutes" "$I1"
    infoAction "------------------------------------------------" "$B1"
    echo    
    mfRepo_updateProgress CONVERT

    infoAction "Convert Start date : $(date)" "$I2"
    
    if [ "$LOG_FILE" != "/dev/null" ]
    then
      TMP_LOG=$(basename $LOG_FILE .log)_nocdbtocdb.log
      infoAction "Conversion log : $TMP_LOG" "$I3" 
    else
      TMP_LOG=/dev/null
    fi

      remoteCommand=$(cat <<%%
  if [ ! -f /home/oracle/$CDB_NAME.env ]
  then
    echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
  else
    . $CDB_NAME.env
    sqlplus / as sysdba << SQL_AT_TARGET
  whenever sqlerror exit failure 
  alter session set container = $TMP_PDB ;
  start ?/rdbms/admin/noncdb_to_pdb.sql
SQL_AT_TARGET
  [ \$? -ne 0 ] && exit 1
  fi
%%
)

    exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" "Convert to PDB (please allow 15-20 minutes) " "$I2" \
      || die "noncdb_to_pdb.sql failed for $TMP_PDB; do not continue to datapatch or RAC open"
    infoAction "Convert End date : $(date)" "$I2" 


  if [ "$ROLLING_PDB_COPY" != "Y" ]
  then

    remoteCommand=$(cat <<%%
  if [ ! -f /home/oracle/$CDB_NAME.env ]
  then
    echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
  else
    . $CDB_NAME.env
    sqlplus / as sysdba << SQL_AT_TARGET
  alter session set container = $TMP_PDB ;
  set lines 200 trimout on pages 2000 tab off
  column name format a150
  column change# format 999999999999
  Prompt
  Prompt Datafile list (at creation)
  Prompt ===========================
  Prompt
  select name,creation_change# from v\\\\\$datafile ;
  Prompt
  Prompt Creation Change (at creation)
  Prompt ==============================
  Prompt
  select distinct(creation_change#) creation_change# from v\\\\\$datafile ;

SQL_AT_TARGET
  fi
%%
  )
    exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" "Initial state of datafiles" "$I2"
  fi
    infoAction "PDB PLUG-IN Violations (Original state)"
    exec_sql "$MF_TGT_CDB_CONNECT" "
  set lines 250 trimout on pages 2000 tab off head on
  col name format a50
  col message format a120
  col status format a10
  col action format a70

  select MESSAGE,STATUS,ACTION 
  from pdb_plug_in_violations 
  where name ='$TMP_PDB'
  and   status != 'RESOLVED';"

    closePDB "$TMP_PDB" "Close the temporary PDB ($TMP_PDB)" "$I2" 

    openPDB "$TMP_PDB" "restricted" "Open temporary PDB (RESTRICTED)" "$I2"

      remoteCommand=$(cat <<%%
  if [ ! -f /home/oracle/$CDB_NAME.env ]
  then
    echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
  else
    . $CDB_NAME.env
    datapatch -pdbs $TMP_PDB
  fi
%%
)
    mfRepo_updateProgress DATAPATCH
    infoAction "Datapatch Start date : $(date)" "$I2"
    if [ "$LOG_FILE" != "/dev/null" ]
    then
      TMP_LOG=$(basename $LOG_FILE .log)_datapatch.log
      infoAction "Conversion log : $TMP_LOG" "$I3" 
    else
      TMP_LOG=/dev/null
    fi
    if ! exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" "Run DATAPATCH on the PDB" "$I2" >$TMP_LOG 2>&1
    then
      [ -f "$TMP_LOG" ] && cat "$TMP_LOG"
      die "DATAPATCH failed for $TMP_PDB; the temporary PDB must not be reopened or switched"
    fi
    if grep -Eq "ORA-00600:|ORA-04045:" "$TMP_LOG"
    then
      cat "$TMP_LOG"
      die "DATAPATCH reported an internal recompilation failure for $TMP_PDB; preserve the Oracle incident and trace"
    fi
    infoAction "Datapatch End date : $(date)" "$I2"

    assertNoPendingPdbErrors "$TMP_PDB" "ALLOW_OPTION_MISMATCH"

    closePDB "$TMP_PDB" "Close After DATAPATCH" "$I2"
      
    infoAction "PDB PLUG-IN Violations (After DATAPATCH)"
    exec_sql "$MF_TGT_CDB_CONNECT" "
  set lines 250 trimout on pages 2000 tab off head on
  col name format a50
  col message format a120
  col status format a10
  col action format a70

  select MESSAGE,STATUS,ACTION 
  from pdb_plug_in_violations 
  where name ='$TMP_PDB'
  and   status != 'RESOLVED';"
    verifyTargetRacEnabled
    openPDBReadWriteOnAllInstances "$TMP_PDB" "$I2"
    
    exec_sql "$MF_TGT_CDB_CONNECT" "alter pluggable database $TMP_PDB save state instances=all;" \
      "Saving PDB State (to OPEN) on all instances" "$I2" \
      || die "Unable to save the open state of $TMP_PDB on all RAC instances"

    exec_sql -verbose "$MF_TGT_CDB_CONNECT" "
    set lines 100 tab off pages 200 heading on
    col name format a10
    col instance_number format 999 heading num
    col host_name format a30
    
                   select 
                      p.name
                     ,i.instance_number
                     ,i.instance_name
                     ,i.host_name
                     ,p.open_mode
                     ,p.restricted
                   from gv\$pdbs p
                   join gv\$instance i on i.inst_id=p.inst_id
                   where p.name='$TMP_PDB'
                   order by i.instance_number ; " "List PDB state on running instances" "$I2"
 
    testConnectionsToTarget  -fix MF_TCP_TMP
                   
    MF_PDB_COPY_RUN_STATE=COPY  
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_UNIT_TEST
#
#  Description         : Performs the DO UNIT TEST step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Not applicable.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Prepare local variables and perform the operation described above.
# -----------------------------------------------------------------------------
#

DO_UNIT_TEST()
{
  addRollingEndSteps
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_COPY
#
#  Description         : Performs the DO COPY step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Iterate over the selected objects or command output.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_COPY() 
{
  [ "$MF_PDB_COPY_RUN_STATE" != "INITIAL" -a "$FORCE" = "N" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with COPY operations"
  startStep "DO_COPY : Copy the database and convert it to PDB"


  echo    
  infoAction "Stop Forward Extract" "$I1"
  infoAction "------------------------" "$B1"
  echo    
  mfRepo_updateProgress STOP_EXTRACT
  mfTestOGG
  libAction "Source extract is" "$I1" ; echo $MF_SRC_EXTRACT
  
  
  #waiting for  Extract initialization to finish (>7min)
  if [ "$MFAUTO_MIG_ID" = "22085" ]
	then 
	infoAction "Waiting 10 minutes for initialization of Extract $MF_SRC_EXTRACT" "$I3"
	sleep 600
  fi
  
  
  if [ "$MF_SRC_EXTRACT" != "" ] 
  then
    [ "$(mfOGG_StatusExtract $MF_SRC_EXTRACT)" != "stopped" ] \
         && mfOGG_StopExtract $MF_SRC_EXTRACT "$I2"
    i=0
    while [ $i -lt 20 -a "$(mfOGG_StatusExtract $MF_SRC_EXTRACT)" != "stopped" ]
    do
      infoAction "Waiting (10 minutes max) for $MF_SRC_EXTRACT to stop" "$I3"
      sleep 30
      mfOGG_StopExtract $MF_SRC_EXTRACT "$I2"
      i=$(($i + 1))
    done
    [ $i -ge 20 ] && die "Extract not stopped, cannot cotinue since REDO LOGS may be deleted at source"
  fi

  mfRepo_updateProgress COPY
  if [ "$ROLLING_PDB_COPY" = "Y" ]
  then
     export PDB_COPY_PHASE=ROLLING_RESTORE
    infoAction "launch backgroup monitoring" "$I2"
    {
      while :
      do
        sleep 60
        . $MF_BIN/mfRunMonitor.sh
        sleep 5
      done
    } &
    PDB_COPY_MONITOR=$!
    rollingRestore
    rollingRecover
    kill -15 $PDB_COPY_MONITOR
    


   #
   #   Add new steps here for ROLLING PDB COPY
   #

   addRollingEndSteps


    endRun "Rolling mode engaged use DO_SYNCH_COPY to advance or -f to execute remaining steps" 
    
  else
    infoAction "Copy Database" "$I1"
    infoAction "------------" "$B1"
    echo    
    libAction "Database size" "$I2"
    dbSz=$(exec_sql "$MF_SRC_PDB_CONNECT" "select to_char(trunc(sum(bytes)/1024/1024/1024)) from dba_data_files ;")
    echo "$dbSz GB"
    libAction "Copy parallelism" "$I2"
    if [ $dbSz -lt 5 ]
    then
      copy_parallel=2
    elif [ $dbSz -lt 50 ]
    then
      copy_parallel=3
    elif [ $dbSz -lt 256 ]
    then
      copy_parallel=4
    elif [ $dbSz -lt 1024 ]
    then
      copy_parallel=6
    elif [ $dbSz -lt 4096 ]
    then
      copy_parallel=8
    else
      copy_parallel=10
    fi
    echo $copy_parallel

    export cnx=$MF_TGT_CDB_CONNECT
    export PDB_COPY_PHASE=COPY
    infoAction "launch backgroup monitoring" "$I2"
    {
      while :
      do
        . $MF_BIN/mfRunMonitor.sh
        sleep 5
      done
    } &
    PDB_COPY_MONITOR=$!

    exec_sql -verbose "$MF_TGT_CDB_CONNECT" "
      set feed on head on timing on
      set pages 200
      select current_scn \"SCN at source Before Copy\" from v\$database@$COPY_DB_LINK ;
      prompt
      prompt Copy the databse to new PDB
      prompt ===========================
      prompt
      create pluggable database $TMP_PDB from $MF_SRC_DBNAME@$COPY_DB_LINK PARALLEL $copy_parallel STANDBYS=NONE;
      select current_scn \"SCN at source After Copy\" from v\$database@$COPY_DB_LINK ;
      " "Copy $MF_SRC_DBNAME to temporary PDB : $TMP_PDB" "$I2" || { kill -15 $PDB_COPY_MONITOR ; die "Error copying the database" ; }

    kill -15 $PDB_COPY_MONITOR
    echo    


    postCopyActions 
  fi
} 


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_SETUP
#
#  Description         : Performs the DO SETUP step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_SETUP() 
{
  [ "$MF_PDB_COPY_RUN_STATE" != "COPY" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with SETUP operations"
  startStep "DO_SETUP : Setup database for usage"
  mfRepo_updateProgress SETUP

  echo    
  infoAction "Verifications" "$I1"
  infoAction "-------------" "$B1"
  echo    

  exec_sql -verbose "$MF_TGT_CDB_CONNECT" "
    set lines 200 pages 200 tab off head on
    col name format a10
    select con_id,name,open_mode,restricted from v\$pdbs order by con_id;" "List available PDBs" "$I2"    
  echo
  libAction "Check if PDB is opened READ WRITE" "$I2"
  testIfPDBIsOpened "$TMP_PDB" "READ WRITE" && echo "Ok" || { echo "Error" ; die "$TMP_PDB is not opened READ WRITE" ; }


  echo    
  infoAction "Setup" "$I1"
  infoAction "-----" "$B1"
  echo    

  #
  #   Variables to connect to Temporary PDB : MF_TGT_TMPPDB_USER / MF_TGT_TMPPDB_PASSWORD / MF_TGT_TMPPDB_TNS and MF_TGT_TMPPDB_CONNECT
  #
  showKeyInfo "CDB TDE configuration (Before)"
  
  echo
  libAction "Master Key Status in $TMP_PDB PDB" "$I3"
  mek_status=$(exec_sql "$MF_TGT_CDB_CONNECT" "
    select status
    from (
          select 
             ew.status
          from 
            v\$encryption_wallet ew
            left join v\$pdbs p on ( p.con_id=ew.con_id) 
          where p.name='$TMP_PDB'
          order by decode (ew.WALLET_TYPE,'HSM','01','10')
         )
    where rownum = 1
    /
    ")
  echo "$mek_status"

  libAction "Master Key Activated in $TMP_PDB PDB" "$I3"
  mek_activated=$(exec_sql "$MF_TGT_CDB_CONNECT" "
    select masterkey_activated 
    from (
          select 
            ki.masterkey_activated
          from
            v\$database_key_info ki
            left join v\$pdbs p on ( p.con_id=ki.con_id) 
            join v\$encryption_wallet ew on (ew.con_id = ki.con_id)
          where p.name='$TMP_PDB' 
          order by decode (ew.WALLET_TYPE,'HSM','01','10')
         )
    where rownum = 1
    /
    ")
  echo "$mek_activated"
  
  libAction "Master Key store for $TMP_PDB PDB" "$I3"
  mek_type=$(exec_sql "$MF_TGT_CDB_CONNECT" "
    select WALLET_TYPE
    from (
          select 
             ew.WALLET_TYPE
          from 
            v\$encryption_wallet ew
            left join v\$pdbs p on ( p.con_id=ew.con_id) 
          where p.name='$TMP_PDB'
          order by decode (ew.WALLET_TYPE,'HSM','01','10')
         )
    where rownum=1
    /
    ")
  echo "$mek_type"

  if [ "$mek_status" = "OPEN_NO_MASTER_KEY" -a "$mek_activated" = "NO" ]
  then
    echo
    if [ "$USE_SAME_KEY" = "N" ]
    then
      remoteCommand=$(cat <<%%
if [ ! -f /home/oracle/$CDB_NAME.env ]
then
  echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
else
  . $CDB_NAME.env
  pass=\$(mkstore -wrl /acfs01/dbaas_acfs/$CDB_NAME/db_wallet -viewEntry tde_ks_passwd  | grep tde_ks_passwd | sed -e "s;^.*= ;;")
  [ "\$pass" = "" ] && { echo "ERROR : No password retrieved" ; exit 1 ; }
  if [ "$mek_type" = "HSM" ]
  then
    pass_key=\$(echo "\$pass" | mkstore -wrl /acfs01/dbaas_acfs/$CDB_NAME/wallet_root/tde -viewEntry ORACLE.SECURITY.CL.ENCRYPTION.HSM_PASSWORD | grep ORACLE.SECURITY.CL.ENCRYPTION.HSM_PASSWORD  | sed -e "s;^.*= ;;")
  else
    pass_key="\$pass"
  fi
  sqlplus -s / as sysdba <<SQL_AT_TARGET
      whenever sqlerror exit failure
      alter session set container=$TMP_PDB;
      administer key management set key using tag 'TDE_ACTIVATION' 
      force keystore identified by "\$pass_key"
      with backup using 'TDE_BACKUP' ;
SQL_AT_TARGET
fi
%%
)
      exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                    "Activating TDE for $TMP_PDB PDB" "$I2" || die "Unable to Activate TDE"
    else

      libAction "Reuse old KEY" "$I3"
      oldKey="$(exec_sql "$MF_TGT_CDB_CONNECT" "select
                                          ki.masterkeyid
                                        from
                                          v\$database_key_info ki
                                          left join v\$pdbs p on ( p.con_id=ki.con_id)      
                                        where
                                          p.name = '$MF_TGT_DBNAME' ; ")"
      echo $oldKey
      echo
      remoteCommand=$(cat <<%%
if [ ! -f /home/oracle/$CDB_NAME.env ]
then
  echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
else
  . $CDB_NAME.env
  pass=\$(mkstore -wrl /acfs01/dbaas_acfs/$CDB_NAME/db_wallet -viewEntry tde_ks_passwd  | grep tde_ks_passwd | sed -e "s;^.*= ;;")
  [ "\$pass" = "" ] && { echo "ERROR : No password retrieved" ; exit 1 ; }
  if [ "$mek_type" = "HSM" ]
  then
    pass_key=\$(echo "\$pass" | mkstore -wrl /acfs01/dbaas_acfs/$CDB_NAME/wallet_root/tde -viewEntry ORACLE.SECURITY.CL.ENCRYPTION.HSM_PASSWORD | grep ORACLE.SECURITY.CL.ENCRYPTION.HSM_PASSWORD  | sed -e "s;^.*= ;;")
  else
    pass_key="\$pass"
  fi
  sqlplus -s / as sysdba <<SQL_AT_TARGET
      whenever sqlerror exit failure
      alter session set container=$TMP_PDB;
      administer key management use key '06$oldKey' using tag 'TDE_ACTIVATION' 
      force keystore identified by "\$pass_key"
      with backup using 'TDE_BACKUP' ;
SQL_AT_TARGET
fi
%%
)
      exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                    "Activating TDE for $TMP_PDB PDB" "$I2" || die "Unable to Activate TDE"
    fi
      
    echo
    sleep 10

    # closePDB "$TMP_PDB" "Close the PDB after key activation" "$I3"
    # echo
    # openPDB "$TMP_PDB" "" "Open the PDB after key activation" "$I3"
    
    showKeyInfo "CDB TDE configuration (After)"
  fi
    
  libAction "Create PDB Level($TARGETDATABASE_ADMINUSERNAME) (on TMP PDB)" "$I2"
  if exec_sql "$MF_TGT_TMPPDB_CONNECT" "select 1 from dual ;" >/dev/null 2>&1
  then
    echo "Ok"

    remoteCommand=$(cat <<%%
if [ ! -f /home/oracle/$CDB_NAME.env ]
then
  echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
else
  . $CDB_NAME.env
  sqlplus -s / as sysdba <<SQL_AT_TARGET
alter session set container=${TMP_PDB} ;
show pdbs ;
drop profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE cascade ;
drop profile PROFILE_${TARGETDATABASE_ADMINUSERNAME} cascade ;
create profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE limit password_life_time unlimited ;
alter profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE limit PASSWORD_REUSE_MAX unlimited ;
alter profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE limit PASSWORD_REUSE_TIME unlimited ;
alter user ${TARGETDATABASE_ADMINUSERNAME} profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE ;
create bigfile tablespace users ;
alter user ${TARGETDATABASE_ADMINUSERNAME} identified by "$MF_TGT_TMPPDB_PASSWORD" account unlock ; 
whenever sqlerror continue
grant dba to $TARGETDATABASE_ADMINUSERNAME ;
grant connect, resource to ${TARGETDATABASE_ADMINUSERNAME};
alter user ${TARGETDATABASE_ADMINUSERNAME} quota 100m on users;
grant unlimited tablespace to ${TARGETDATABASE_ADMINUSERNAME};
grant select any dictionary to ${TARGETDATABASE_ADMINUSERNAME};
grant select any table to ${TARGETDATABASE_ADMINUSERNAME};
grant create view to ${TARGETDATABASE_ADMINUSERNAME};
grant execute on dbms_lock to ${TARGETDATABASE_ADMINUSERNAME};
exec dbms_goldengate_auth.grant_admin_privilege('${TARGETDATABASE_ADMINUSERNAME}');
grant insert any table to ${TARGETDATABASE_ADMINUSERNAME};
grant update any table to ${TARGETDATABASE_ADMINUSERNAME};
grant delete any table to ${TARGETDATABASE_ADMINUSERNAME};
grant create any table to ${TARGETDATABASE_ADMINUSERNAME};
grant alter any table to ${TARGETDATABASE_ADMINUSERNAME};
grant drop any table to ${TARGETDATABASE_ADMINUSERNAME};
grant comment any table to ${TARGETDATABASE_ADMINUSERNAME};
grant create any index to ${TARGETDATABASE_ADMINUSERNAME};
grant alter any index to ${TARGETDATABASE_ADMINUSERNAME};
grant drop any index to ${TARGETDATABASE_ADMINUSERNAME};
grant create any view to ${TARGETDATABASE_ADMINUSERNAME};
grant drop any view to ${TARGETDATABASE_ADMINUSERNAME};
grant create any materialized view to ${TARGETDATABASE_ADMINUSERNAME};
grant alter any materialized view to ${TARGETDATABASE_ADMINUSERNAME};
grant drop any materialized view to ${TARGETDATABASE_ADMINUSERNAME};
grant create any procedure to ${TARGETDATABASE_ADMINUSERNAME};
grant alter any procedure to ${TARGETDATABASE_ADMINUSERNAME};
grant drop any procedure to ${TARGETDATABASE_ADMINUSERNAME};
grant select on user$ to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on v_\\\\\$database to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on v_\\\\\$instance to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_objects to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_role_privs to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_tab_privs to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_profiles to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_users to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_roles to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_tablespaces to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_ts_quotas to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant execute on utl_file to ${TARGETDATABASE_ADMINUSERNAME} ;
grant execute on dbms_scheduler to mig_exacc ;
grant execute on dbms_lob to mig_exacc with grant option;
SQL_AT_TARGET
fi
%%
)

  exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                 "Updating privileges to the ${TARGETDATABASE_ADMINUSERNAME} (dba) user on ${pdb_name}" "$I3" || die "Unable to update privileges from migration user on target PDB"

  else
    echo "Non Existent"
    remoteCommand=$(cat <<%%
if [ ! -f /home/oracle/$CDB_NAME.env ]
then
  echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
else
  . $CDB_NAME.env
  sqlplus -s / as sysdba <<SQL_AT_TARGET
whenever sqlerror exit failure ;
alter session set container=${TMP_PDB} ;

whenever sqlerror continue
show pdbs
drop profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE cascade ;
drop profile PROFILE_${TARGETDATABASE_ADMINUSERNAME} cascade ;
create profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE limit password_life_time unlimited ;
alter profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE limit PASSWORD_REUSE_MAX unlimited ;
alter profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE limit PASSWORD_REUSE_TIME unlimited ;
drop user $TARGETDATABASE_ADMINUSERNAME cascade ;
create bigfile tablespace users ;

create user $TARGETDATABASE_ADMINUSERNAME profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE identified by "${MF_TGT_TMPPDB_PASSWORD}" ;
whenever sqlerror exit failure ;

alter user $TARGETDATABASE_ADMINUSERNAME profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE ;
grant dba to $TARGETDATABASE_ADMINUSERNAME ;
grant connect, resource to ${TARGETDATABASE_ADMINUSERNAME};
alter user ${TARGETDATABASE_ADMINUSERNAME} quota 100m on users;
grant unlimited tablespace to ${TARGETDATABASE_ADMINUSERNAME};
grant select any dictionary to ${TARGETDATABASE_ADMINUSERNAME};
grant select any table to ${TARGETDATABASE_ADMINUSERNAME};
grant create view to ${TARGETDATABASE_ADMINUSERNAME};
grant execute on dbms_lock to ${TARGETDATABASE_ADMINUSERNAME};
exec dbms_goldengate_auth.grant_admin_privilege('${TARGETDATABASE_ADMINUSERNAME}');
grant insert any table to ${TARGETDATABASE_ADMINUSERNAME};
grant update any table to ${TARGETDATABASE_ADMINUSERNAME};
grant delete any table to ${TARGETDATABASE_ADMINUSERNAME};
grant create any table to ${TARGETDATABASE_ADMINUSERNAME};
grant alter any table to ${TARGETDATABASE_ADMINUSERNAME};
grant drop any table to ${TARGETDATABASE_ADMINUSERNAME};
grant comment any table to ${TARGETDATABASE_ADMINUSERNAME};
grant create any index to ${TARGETDATABASE_ADMINUSERNAME};
grant alter any index to ${TARGETDATABASE_ADMINUSERNAME};
grant drop any index to ${TARGETDATABASE_ADMINUSERNAME};
grant create any view to ${TARGETDATABASE_ADMINUSERNAME};
grant drop any view to ${TARGETDATABASE_ADMINUSERNAME};
grant create any materialized view to ${TARGETDATABASE_ADMINUSERNAME};
grant alter any materialized view to ${TARGETDATABASE_ADMINUSERNAME};
grant drop any materialized view to ${TARGETDATABASE_ADMINUSERNAME};
grant create any procedure to ${TARGETDATABASE_ADMINUSERNAME};
grant alter any procedure to ${TARGETDATABASE_ADMINUSERNAME};
grant drop any procedure to ${TARGETDATABASE_ADMINUSERNAME};
grant select on user$ to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on v_\\\\\$database to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on v_\\\\\$instance to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_objects to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_role_privs to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_tab_privs to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_profiles to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_users to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_roles to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_tablespaces to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant select on dba_ts_quotas to ${TARGETDATABASE_ADMINUSERNAME} with grant option ;
grant execute on utl_file to ${TARGETDATABASE_ADMINUSERNAME} ;
grant execute on dbms_scheduler to mig_exacc ;
grant execute on dbms_lob to mig_exacc with grant option;
SQL_AT_TARGET
fi
%%
)
    exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                   "Creating the ${TARGETDATABASE_ADMINUSERNAME} (dba) user on ${pdb_name}" "$I3" || die "Unable to create migration user on target PDB"

  fi
  # echo
  # closePDB "$TMP_PDB"    "Closing $TMP_PDB" "$I2"
  # echo
  # openPDB  "$TMP_PDB" "" "Opening $TMP_PDB" "$I2"
  #
  #    Error management is not reliable on the previous step, so, we check here
  #
  echo
  echo "  - Wait 30 seconds"
  sleep 30
  echo
  exec_sql -verbose "$MF_TGT_TMPPDB_CONNECT" "select '    Connected to PDB : ' || name  from v\$pdbs ;" "Testing PDB Connection" "$I2" || die "Target PDB connection unsuccessful, check manually"


  endStep
} 
  # ------------------------------------------------------------------------------------------------------


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_USERS
#
#  Description         : Performs the DO USERS step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Parse command-line options and dispatch the requested action.
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - Some file paths are redirected without quotes and may fail with
#                          spaces.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_USERS() 
{
  [ "$MF_PDB_COPY_RUN_STATE" != "COPY" -a "$MF_PDB_COPY_RUN_STATE" != "SWITCHED" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with Users synchronization operations"
  if [ "$MF_PDB_COPY_RUN_STATE" = "COPY" ]
  then
    ref="$MF_TGT_PDB_CONNECT"
    ref_pdb=$MF_TGT_DBNAME
    tgt="$MF_TGT_TMPPDB_CONNECT"
    tgt_pdb=$TMP_PDB
  else
    ref="$MF_TGT_OLDPDB_CONNECT"
    ref_pdb=$OLD_PDB
    tgt="$MF_TGT_PDB_CONNECT"
    tgt_pdb=$MF_TGT_DBNAME
  fi
  startStep "DO_USERS : Synchronize users"
  mfRepo_updateProgress USERS
  exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" ". \$HOME/$CDB_NAME.env && srvctl start service -d \$ORACLE_UNQNAME ; srvctl status service -d \$ORACLE_UNQNAME" \
                                          "Start services on target, just in case" "$I2" || die "Error starting services"
  # revokeReadOnUser "$CDB_NAME" "$MF_TGT_DBNAME" "$MF_TGT_PDB_USER" "$MF_TGT_PDB_CONNECT"


  echo
  infoAction "Test for password verification function" "$I1" 
  for func in $(exec_sql "$ref" "select object_name from dba_objects 
                                                where owner = 'SYS' and object_type = 'FUNCTION' 
                                                and (object_name like '%VERIFY_FUNCTION%' or object_name like '%PWD_VERIFY%' or object_name in ('MGMT_INTERNAL_PASS_VERIFY','MGMT_PASS_VERIFY')) ;")
  do
    libAction "Testing $func on target" "$I2"
    
    # Test if the function exists on the target
    tst=$(exec_sql "$tgt" "
      select '1' 
      from dba_objects 
      where owner = 'SYS' 
        and object_type = 'FUNCTION' 
        and object_name = '$func' 
        and rownum = 1;
    ") || die "Error testing function $func on target ($tst)"
    
    if [ "$tst" = "1" ]
    then
      echo "Exists"
    else
      echo "Does not exists. Creating..."
    
      # Retrieve the DDL for the function from the source
      libAction "Get function DDL for $func" "$I3"
      function_ddl=$(exec_sql "$ref" "
  set long 20000 longchunksize 20000 pagesize 0 linesize 1000 feedback off verify off trimspool on
  column ddl format a1000
  set lines 1000
  begin
    dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
    dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);
  end;
  /
  select dbms_metadata.get_ddl('FUNCTION', '$func', 'SYS') as ddl
  from   dba_objects
  where  owner = 'SYS' and object_name = '$func';
  ") && echo Ok || { echo Error ; die "Unable to get function definition ($func $function_ddl)" ; }

      #
      #   Escape the '$' sign, many '\' due to ssh + sudo
      #
      function_ddl="$(echo "$function_ddl" | sed -e 's;\$;\\\\\\\$;')"
    # echo "$function_ddl"  
      # Execute the DDL on the target to create the function
      libAction "Executing function DDL on target via SSH & SYSDBA" "$I3"
     
       {
          ssh -o StrictHostKeyChecking=no ${MF_SUDOER:-opc}@$databaseHost  <<EOF
  sudo su - oracle -c "
  . $CDB_NAME.env && \
  sqlplus -s / as sysdba <<SQL
  whenever sqlerror exit failure
  alter session set container=$tgt_pdb ;
  $function_ddl
  SQL
  "
EOF
      } > $TMPFILE1 2>&1 > $TMPFILE1 2>&1 \
          && { echo "Ok" ; rm -f $TMPFILE1 ; } \
          || { echo "Error" ; cat $TMPFILE1 ; rm -f $TMPFILE1 ;  die "Unable to create function $func on target" ; }
      
    fi
  done


  setReadOnUser "$CDB_NAME" "$ref_pdb" "$MF_TGT_PDB_USER" "$tgt"
  common_user_prefix=$(exec_sql "$MF_TGT_CDB_CONNECT" "select value from v\$parameter where name ='common_user_prefix';")
  users=$(exec_sql "$ref" "select username 
                                               from dba_users 
                                               where regexp_like (username,'^GRP_') 
                                               or    regexp_like (username,'^OWN_AP[0-9]*$') 
                                               or    username in ('DYNATRACE', 'GUARDIUM_DISCOVERY', 'DISCOVERY', 'SAAMORACLE', 'BNPSASR')
                           order by username;") || die "ERROR: \n $users"
  libAction "Testing for DATA0001 existence" "$I2"
  nb=$(exec_sql "$tgt" "select to_char(count(*)) from dba_tablespaces where tablespace_name='DATA0001';") || die "$nb"
  if [ "$nb" = "0" ]
  then 
    echo "Not exists"
    exec_sql "$tgt" "create bigfile tablespace DATA0001;" "Create DATA0001" "$I3"
  else
    echo "Exists"
  fi
  for u in $users
  do
    copyUserDefinition "$u" "$common_user_prefix"
  done
  
  
  
  endStep
} 


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : parallelEncryption
#
#  Description         : Performs the parallel Encryption step used by
#                        mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Not applicable.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Iterate over the selected objects or command output.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

parallelEncryption()
{
  local tbs_list="$1"
  local MAX_JOBS=2 ; # 0 = Unlimited
  local JOB_PREFIX='MF_ENC_'
  local nb_running=0
  for t in $tbs_list
  do
    running=0
    exec_sql -verbose "$cnx" "
declare
  stmt varchar2 (4000) ;
  l_job_name varchar2(100) ;
begin
  stmt := q'[
  dbms_application_info.set_module('ENCRYPT (PID: $$)','Start') ;
  dbms_application_info.set_action('$t') ;
  dbms_application_info.set_client_info('Encrypt tablespace JOB') ;
  execute immediate 'alter tablespace $t encryption online encrypt' ;
  --dbms_lock.sleep(20) ;
  ]' ;
  l_job_name := DBMS_SCHEDULER.generate_job_name('$JOB_PREFIX') ;
  DBMS_SCHEDULER.create_job(
    job_name        => l_job_name,
    job_type        => 'PLSQL_BLOCK',
    job_action      => stmt ,
    enabled         => TRUE,
    comments        => 'Tablespace $t encryption') ;
end ;
/
    " "Launch background encryption for $t" "$I2"
    if [ $MAX_JOBS -ne 0 ]
    then
      nb_running=$(exec_sql "$cnx" "select to_char(count(*)) from dba_scheduler_jobs where job_name like '$JOB_PREFIX' || '%' and state in ('SCHEDULED','RUNNING','RETRY SCHEDULED') ;") || die "$nb_running"
      while [ $nb_running -ge $MAX_JOBS ]
      do
        nb_running=$(exec_sql "$cnx" "select to_char(count(*)) from dba_scheduler_jobs where job_name like '$JOB_PREFIX' || '%' and state in ('SCHEDULED','RUNNING','RETRY SCHEDULED') ;")  || die "$nb_running"
        . $MF_BIN/mfRunMonitor.sh
        sleep 10 ;
      done
    fi      
  done
  
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : failIfRestricted
#
#  Description         : Performs the fail If Restricted step used by
#                        mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Not applicable.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

failIfRestricted()
{
  local tmp=-1 ;
  tmp=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(count(*)) from gv\$pdbs where restricted='YES';")
  [ "$tmp" != "0" ] && die "ATTENTION : $tmp PDB instances are RESTRICTED, fix before continuing"
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_ENCRYPT_BIGFILE
#
#  Description         : Performs the DO ENCRYPT BIGFILE step used by
#                        mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_ENCRYPT_BIGFILE()
{
    [ "$MF_PDB_COPY_RUN_STATE" != "COPY" -a "$MF_PDB_COPY_RUN_STATE" != "SWITCHED" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with Encryption operations"
    startStep "DO_ENCRYPT_BIGFILE : Encrypt unencrypted BIGFILE tablespaces"

    failIfRestricted

    # if [ "$MIGRATION_METHOD" != "ONLINE_LOGICAL" ]
    # then
      # mfRepo_updateProgress STOP_OGG
      # libAction "Stop Golden-gate replication" "$I2"
      # $MF_BIN/mfReplMgmt.sh -A STOP -D FWD -n >$TMPFILE2 2>&1 && \
        # { echo "Ok" ; rm -f $TMPFILE2 ; } || \
        # { echo "Error" ; cat $TMPFILE2 ; rm -f $TMPFILE2 ; } 
    # fi 
 

    if [ "$MF_PDB_COPY_RUN_STATE" = "COPY" ]
    then
      cnx="$MF_TGT_TMPPDB_CONNECT"
      pdb=$TMP_PDB
    else
      cnx="$MF_TGT_PDB_CONNECT"
      pdb=$MF_TGT_DBNAME
    fi

    infoAction "Encrypting BIGFILE tablespaces" "$I1"
    infoAction "==============================--" "$B1"
    mfRepo_updateProgress ENCRYPT_BIG
    
 
    parallelEncryption "$(exec_sql "$cnx" "select tablespace_name from dba_tablespaces where contents='PERMANENT' and bigfile='YES' and ENCRYPTED='NO';")"


      # exec_sql "$cnx" "
      # set timing on
      # alter tablespace $ts encryption online encrypt ;
      # " "Encrypting $ts (Started : $(date +"%Y/%m/%d %H:%M:%S"))" "$I3"

    # if [ "$MIGRATION_METHOD" != "ONLINE_LOGICAL" ]
    # then
      # libAction "Start Golden-gate replication" "$I2"
      # mfRepo_updateProgress START_OGG
      # $MF_BIN/mfReplMgmt.sh -A START -D FWD -n >$TMPFILE2 2>&1 && \
        # { echo "Ok" ; rm -f $TMPFILE2 ; } || \
        # { echo "Error" ; cat $TMPFILE2 ; rm -f $TMPFILE2 ; } 
    # fi 
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_ENCRYPT_ALL
#
#  Description         : Performs the DO ENCRYPT ALL step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_ENCRYPT_ALL()
{
  local JOB_PREFIX='MF_ENC_'
  export PDB_COPY_PHASE=ENCRYPT_FINAL
  [ "$MF_PDB_COPY_RUN_STATE" != "COPY" -a "$MF_PDB_COPY_RUN_STATE" != "SWITCHED" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with Encryption operations"

    failIfRestricted


  startStep "DO_ENCRYPT_ALL : Encrypt ALL unencrypted tablespaces"
  mfRepo_updateProgress ENCRYPT

  if [ "$MF_PDB_COPY_RUN_STATE" = "COPY" ]
  then
    cnx="$MF_TGT_TMPPDB_CONNECT"
    pdb=$TMP_PDB
  else
    cnx="$MF_TGT_PDB_CONNECT"
    pdb=$MF_TGT_DBNAME
  fi

  infoAction "Encrypting remaining tablespaces" "$I1"
  infoAction "==============================--" "$B1"
  list="$(exec_sql "$cnx" "select tablespace_name from dba_tablespaces where contents='PERMANENT' and bigfile='NO' and ENCRYPTED='NO' and tablespace_name not in('SYSTEM','SYSAUX');")" || die "$list"
  parallelEncryption "$list"

  #
  #  Wait for ALL tablespace encryption jobs to Finish
  #
  infoAction "Wait for tablespace encryption jobs to terminate" "$I2"
  nb_running=$(exec_sql "$cnx" "select to_char(count(*)) from dba_scheduler_jobs where job_name like '$JOB_PREFIX' || '%' and state in ('SCHEDULED','RUNNING','RETRY SCHEDULED') ;")  || die "$nb_running"
  echo 
  infoAction "SYSTEM & SYSAUX tablespaces" "$I1"
  infoAction "===========================" "$B1"
  echo
  while [ $nb_running -gt 0 ]
  do
    nb_running=$(exec_sql "$cnx" "select to_char(count(*)) from dba_scheduler_jobs where job_name like '$JOB_PREFIX' || '%' and state in ('SCHEDULED','RUNNING','RETRY SCHEDULED') ;") || die "$nb_running"
    . $MF_BIN/mfRunMonitor.sh
    sleep 10 ;
  done
  for sys_tbs in SYSAUX SYSTEM
  do
    encrypted=$(exec_sql "$cnx" "select to_char(count(*)) from dba_tablespaces where tablespace_name = '$sys_tbs' and encrypted='NO' ;") || die "$encrypted"
    if [ $encrypted -ne 0 ]
    then
      remoteCommand=$(cat <<%%
    . $CDB_NAME.env || exit 1
sqlplus / as sysdba << _SQL_
whenever sqlerror exit failure
alter session set container=$pdb ;
set feed on timing on
alter tablespace $sys_tbs encryption online encrypt;
_SQL_
exit $?
%%
)
      exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" "Encrypting $sys_tbs (ONLINE)" "$I2" || die "Error encrypting $sys_tbs"
    fi
  done
  echo 
  # infoAction "Undo tablespace" "$I1"
  # infoAction "===========================" "$B1"
  # echo
  # for line in $(exec_sql "$cnx" "select i.instance_name || ';' || p.value
                                 # from gv\$parameter p
                                 # join gv\$instance i on (i.inst_id = p.inst_id)
                                 # join dba_tablespaces ts on (ts.tablespace_name = p.value)
                                 # where 
                                      # p.name='undo_tablespace' 
                                  # and (ts.bigfile='NO' or ts.encrypted='NO');")
  # do
    # inst=$(echo "$line" | cut -f1 -d";")
    # tbs=$(echo "$line" | cut -f2 -d";")
    # exec_sql "$cnx" "alter tablespace $tbs rename to ${tbs}_OLD ;" "Renaming $tbs (UNDO for instance $inst)" "$I2"
    # exec_sql "$cnx" "create bigfile undo tablespace ${tbs}_NEW ;" "Creating ENCRYPTED/BIGFILE ${tbs}_NEW (for instance $inst)" "$I2"
    # exec_sql "$cnx" "alter system set undo_tablespace=${tbs}_NEW scope=both sid='$inst' ;" "Change undo_tablespace parameter ${tbs}_NEW (for instance $inst)" "$I2"
  # done
  

  echo 
  infoAction "Temporary tablespace" "$I1"
  infoAction "===========================" "$B1"
  echo
  for tbs in $(exec_sql "$cnx" "select tablespace_name
                                from dba_tablespaces
                                where 
                                      contents='TEMPORARY' 
                                  and (bigfile='NO' or encrypted='NO');")
  do
    exec_sql "$cnx" "alter tablespace $tbs rename to ${tbs}_OLD;" "Renaming $tbs (UNDO for instance $inst)" "$I2"
    exec_sql "$cnx" "create bigfile temporary tablespace $tbs ; " "Creating ENCRYPTED/BIGFILE $tbs (for instance $inst)" "$I2" || die "Unable to create $tbs"
    for usr in $(exec_sql "$cnx" "select username from dba_users where temporary_tablespace='${tbs}_OLD' and common='NO';")
    do
      exec_sql "$cnx" "alter user \"$usr\" temporary tablespace $tbs ; " "Change temp tablespace for $usr" "$I3"
    done
  done


  nb_to_remove=$(exec_sql "$cnx" "select to_char(count(*))
                                  from (
                                         select tablespace_name 
                                         from   dba_tablespaces 
                                         where  contents = 'UNDO' 
                                         and    tablespace_name not in (select value 
                                                                        from gv\$parameter 
                                                                        where name='undo_tablespace')
                                         UNION
                                         select tablespace_name 
                                         from   dba_tablespaces t
                                         where  contents = 'TEMPORARY' 
                                         and    (bigfile='NO' or encrypted='NO')
                                         and    not exists (select 1 from dba_users where temporary_tablespace=t.tablespace_name) 
                                        ) ;") || die "$nb_to_remove"
  if [ $nb_to_remove != 0 ]
  then
    # if [ "$MF_PDB_COPY_RUN_STATE" = "COPY" ]
    # then
      # closePDB "$pdb" "Close the PDB $pdb to free UNDO" "$I2"
      # openPDB "$pdb" " ""Open the PDB $pdb" "$I2"
    # fi
    for t in $(exec_sql "$cnx" "select tablespace_name from dba_tablespaces where contents = 'UNDO' and tablespace_name not in (select value from gv\$parameter where name='undo_tablespace');")
    do
      exec_sql "$cnx" "drop tablespace $t;" "Dropping tablespace $t (can be retried if it fails)" "$I2"
    done

    for t in $(exec_sql "$cnx" "select tablespace_name 
                                from   dba_tablespaces t
                                where  contents = 'TEMPORARY' 
                                and    (bigfile='NO' or encrypted='NO')
                                and    not exists (select 1 from dba_users where temporary_tablespace=t.tablespace_name);")
    do
      exec_sql "$cnx" "drop tablespace $t;" "Dropping tablespace $t" "$I2"
    done
    
  fi  
 mfDefragTbsContents
}

  # ------------------------------------------------------------------------------------------------------


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_SWITCH
#
#  Description         : Performs the DO SWITCH step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Not applicable.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Prepare local variables and perform the operation described above.
#
#  Possible issues     : 
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_SWITCH() 
{
  if [ "$DO_SWITCH" = "Y" ]
  then
    [ "$MF_PDB_COPY_RUN_STATE" != "COPY" -a "$MF_PDB_COPY_RUN_STATE" != "SWITCHED" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with EXCHANGE operations"
    startStep "DO_SWITCH : Exchange pluggable databases"
    pdbCopyStatus 
    mfRepo_updateProgress SWITCH
      
    if [ "$tgtPdbPresent" = "Y" -a "$tmpPdbPresent" = "Y" ]
    then
      exchangePDB FORWARD
    else
      exchangePDB BACKWARD
    fi
    endStep
  fi
} 


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : moveObjects
#
#  Description         : Performs the move Objects step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Not applicable.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Iterate over the selected objects or command output.
# -----------------------------------------------------------------------------
#

moveObjects()
{
  local cnx="$1"
  local para=$2
  local stop_date="$3"
  #
  #      These variables controls how the mfDefragMoveObjects (see mfUtils_07_defragmentation.sh) function (containing a big PL/SQL block works
  #   if needed, we could add parameters to moveObjects, nut it is not the case now.
  #    
  pTBS=".*"                                                                        # Tablespace Selection (regexp)
  pTABLE=".*"                                                                      # Included Table (regular expression)
  pTABLE_Excluded="NONE"                                                           # Excluded Table (regular expression)
  pSTOPDATE="$stop_date"                                                           # The run will stop after this date, even if not terminated
  pPARA=0                                                                          # Degree of parallelism (0 ==> Variable 1..32)
  pMODE=ONLINE                                                                     # ONLINE/OFFLINE Processing
  pNEWTS="Y"                                                                       # Move to a new tablespace
  pEXTENTS=0                                                                       # Number of lines (for tests), 0 means ALL segments
  RT_DIR="/acfs01/app_acfs"                                                        # ORACLE DIR for the LOG (Created if non existent) (NULL to deactivate)
  RT_LOG="moveTbs_$(date +"%Y%m%d_%H%M%S").log"                                    # Name of the temporary log (Removed at the end)
  run_it="TRUE"                                                                    # If false, no move operation performed (TRUE/FALSE)
  pGENONLY="N"                                                                     # Only print the statements
  pRebuild="AFTER"                                                                 # When to rebuild indexes (EACH, NEVER, AFTER)
  pResize="N"                                                                      # Resize the source datafile during run (takes time)
  pExternalParallelism=$para                                                       # Run move via N Jobs in parallel
  pReverseMove=N                                                                   # Move from XXX_NEW to XXX
  pSmallFileSource=Y                                                               # Move only from SMALLFILE tablespaces
  pPrereqOnly="N"                                                                  # Check prerequisites only

  mfDefragMoveObjects "$cnx"
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_MOVE
#
#  Description         : Performs the DO MOVE step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Parse command-line options and dispatch the requested action.
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_MOVE() 
{
  [ "$MF_PDB_COPY_RUN_STATE" != "COPY" -a "$MF_PDB_COPY_RUN_STATE" != "SWITCHED" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with MOVE operations"
  mfRepo_updateProgress MOVE
  if [ "$MF_PDB_COPY_RUN_STATE" = "COPY" ]
  then
    cnx="$MF_TGT_TMPPDB_CONNECT"
    pdb=$TMP_PDB
  else
    cnx="$MF_TGT_PDB_CONNECT"
    pdb=$MF_TGT_DBNAME
  fi

  export PDB_COPY_PHASE=MOVE
  export cnx pdb    

  infoAction "launch backgroup monitoring" "$I2"
  {
    while :
    do
      . $MF_BIN/mfRunMonitor.sh
      sleep 10
    done
  } &
  PDB_COPY_MONITOR=$!
  startStep "DO_MOVE : Move objects to BIGFILE, ecrypted tablespaces, encrypt other tablespaces"

  infoAction "Tablespaces status at START" "$I1"
  infoAction "===========================" "$B1"
  echo
  mfDefragTbsContents "$cnx"
  
  infoAction "Moving segments (ONLINE/Parallel) 12 hours max" "$I1"
  infoAction "==============================================" "$B1"
  echo "
    
                 Nothing appears here during the processing, the log is only shown at the end.
                 
                 You can tracks the process in the file : $RT_DIR/$RT_LOG
                 on the $databaseHost machine.  
                 
                 Tablespace selection  : $pTBS
                 Table selection       : $pTABLE
                 Automatic stop        : $pSTOPDATE
                 MODE                  : $pMODE
                 Scheduler parallelism : $pExternalParallelism
         
    You can monitor the progress using this command ;

echo \" set lines 230 pages 2000 tab off
col job_name format a25
col start_date format a20
col duration format a30
col state format a15
col comments format a120
col segments_count format 999G999G999G999
col tablespace_name format a30
col bigfile format a10
col encrypted format a10
prompt
prompt ====================================================
prompt Running jobs 
prompt ====================================================
select    job_name,to_char(last_start_date,'dd/mm/yyyy hh24:mi:ss') start_date,current_timestamp - last_start_date duration,state,comments
from      user_scheduler_jobs
where     job_name like 'MF_$$_%'
order by  last_start_date ;
prompt ====================================================
prompt Segments move progress 
prompt ====================================================
select    case
            when ts.tablespace_name like '%NEW' then lpad('----> ' || ts.tablespace_name,30)
            else ts.tablespace_name
          end tablespace_name,ts.encrypted,ts.bigfile
         ,case when se.tablespace_name is null then 0 else count(*) end segments_count
from     dba_tablespaces ts
         left join dba_segments se on (ts.tablespace_name = se.tablespace_name)
group by ts.tablespace_name,se.tablespace_name,ts.encrypted ,ts.bigfile 
order by ts.tablespace_name,ts.encrypted ,ts.bigfile ; \" | tgtPdb -m $MF_MIGRATION_ID -s
    
         "
    
  # Parameters (simplified : connect_string external_parallelism stop_date
  moveObjects "$cnx" 8 "$(date -d "now + 12 hour" +"%d/%m/%Y %H:%m:%S")"

  if [ "$RT_DIR" != "" ]
  then
    exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" "test -f $RT_DIR/$RT_LOG && rm -f $RT_DIR/$RT_LOG || exit 0" "Removing real-time LOG file" "$I2"
  fi

  echo
  infoAction "Percentage of segments remaining in smallfiles" "$I1" 
  infoAction "==============================================" "$B1"
  
  total_segments=$(exec_sql "$cnx" "select to_char(count(*)) 
                                    from   dba_segments se
                                    join   dba_tablespaces ta on (se.tablespace_name = ta.tablespace_name) 
                                    where  se.tablespace_name not in ('SYSTEM','SYSAUX')
                                    and    ta.contents='PERMANENT';") || die "$total_segments"
  smallfile_segments=$(exec_sql "$cnx" "select to_char(count(*)) 
                                        from   dba_segments se
                                        join   dba_tablespaces ta on (se.tablespace_name = ta.tablespace_name) 
                                        where  se.tablespace_name not in ('SYSTEM','SYSAUX')
                                        and    ta.bigfile='NO'
                                        and    ta.contents='PERMANENT';") || die "$smallfile_segments"

  libAction "Total number of segments" "$I2" ; echo $total_segments
  libAction "Segments in smallfile tablespaces" "$I2" ; echo $smallfile_segments
  pct=$((($smallfile_segments / $total_segments) * 100))
  libAction "Percentage" "$I2" ; echo "$pct %"

  if [ $pct -le 5 -a $smallfile_segments -le 1000 ]
  then
    echo
    infoAction "Moving segments (ONLINE/Sequential) 4 hours max" "$I1"
    infoAction "===============================================" "$B1"
    pExternalParallelism=0
    pSTOPDATE=$(date -d "now + 4 hour" +"%d/%m/%Y %H:%m:%S")                         # The run will stop after this date, even if not terminated
    echo "
    
                 Nothing appears here during the processing, the log is only shown at the end.
                 
                 You can tracks the process in the file : $RT_DIR/$RT_LOG
                 on the $databaseHost machine.  
                 
                 Tablespace selection  : $pTBS
                 Table selection       : $pTABLE
                 Automatic stop        : $pSTOPDATE
                 MODE                  : $pMODE
                 Scheduler parallelism : $pExternalParallelism
          "
    # Parameters (simplified : connect_string external_parallelism stop_date
    moveObjects "$cnx" $pExternalParallelism "$pSTOPDATE"

    if [ "$RT_DIR" != "" ]
    then
      exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" "test -f $RT_DIR/$RT_LOG && rm -f $RT_DIR/$RT_LOG || exit 0" "Removing real-time LOG file" "$I2"
    fi
    smallfile_segments=$(exec_sql "$cnx" "select to_char(count(*)) 
                                          from   dba_segments se
                                          join   dba_tablespaces ta on (se.tablespace_name = ta.tablespace_name) 
                                          where  se.tablespace_name not in ('SYSTEM','SYSAUX')
                                          and    ta.bigfile='NO'
                                          and    ta.contents='PERMANENT';") || die "$smallfile_segments"
    libAction "Segments in smallfile tablespaces" "$I2" ; echo $smallfile_segments
    pct=$((($smallfile_segments / $total_segments) * 100))
    libAction "Percentage" "$I2" ; echo "$pct %"
  fi
  if [ $pct -le 5 -a $smallfile_segments -le 1000 ]
  then
    echo
    infoAction "Moving segments (OFFLINE/Sequential) 1 hour max" "$I1"
    infoAction "===============================================" "$B1"
    pExternalParallelism=0
    pMODE=OFFLINE                                                                    # ONLINE/OFFLINE Processing
    pSTOPDATE=$(date -d "now + 1 hour" +"%d/%m/%Y %H:%m:%S")                         # The run will stop after this date, even if not terminated
    echo "
    
                 Nothing appears here during the processing, the log is only shown at the end.
                 
                 You can tracks the process in the file : $RT_DIR/$RT_LOG
                 on the $databaseHost machine.  
                 
                 Tablespace selection  : $pTBS
                 Table selection       : $pTABLE
                 Automatic stop        : $pSTOPDATE
                 MODE                  : $pMODE
                 Scheduler parallelism : $pExternalParallelism
          "
    moveObjects "$cnx" $pExternalParallelism "$pSTOPDATE"

    if [ "$RT_DIR" != "" ]
    then
      exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" "test -f $RT_DIR/$RT_LOG && rm -f $RT_DIR/$RT_LOG || exit 0" "Removing real-time LOG file" "$I2"
    fi
    smallfile_segments=$(exec_sql "$cnx" "select to_char(count(*)) 
                                          from   dba_segments se
                                          join   dba_tablespaces ta on (se.tablespace_name = ta.tablespace_name) 
                                          where  se.tablespace_name not in ('SYSTEM','SYSAUX')
                                          and    ta.bigfile='NO'
                                          and    ta.contents='PERMANENT';") || die "$smallfile_segments"
    libAction "Segments in smallfile tablespaces" "$I2" ; echo $smallfile_segments
    pct=$((($smallfile_segments / $total_segments) * 100))
    libAction "Percentage" "$I2" ; echo "$pct %"
  fi

  moveTablesWithLONG % N
  
  echo
  infoAction "Clean empty tablespaces" "$I1" 
  infoAction "=======================" "$B1"
  echo
  mfDefragCleanEmptyTablespaces "$cnx"
  
  smallfile_segments=$(exec_sql "$cnx" "select to_char(count(*)) 
                                        from   dba_segments se
                                        join   dba_tablespaces ta on (se.tablespace_name = ta.tablespace_name) 
                                        where  se.tablespace_name not in ('SYSTEM','SYSAUX')
                                        and    ta.bigfile='NO'
                                        and    ta.contents='PERMANENT';") || die "$smallfile_segments"
  libAction "Segments in smallfile tablespaces" "$I2" ; echo $smallfile_segments
  pct=$((($smallfile_segments / $total_segments) * 100))
  libAction "Percentage" "$I2" ; echo "$pct %"

  kill -15 $PDB_COPY_MONITOR 
  
  echo
  infoAction "Tablespaces status at END" "$I1" 
  infoAction "=========================" "$B1"
  echo
  mfDefragTbsContents "$cnx"

  mfTablespaceMoveSummary "$cnx"
  
  endStep
} 

  # ------------------------------------------------------------------------------------------------------


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_OGG
#
#  Description         : Performs the DO OGG step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Returns a status code derived from the operation
#                        result.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Iterate over the selected objects or command output.
#                        - Parse command output to derive status or generated values.
#                        - Return a status code derived from the operation result.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_OGG() 
{
  if [ "$MIGRATION_METHOD" != "ONLINE_LOGICAL" ]
  then
    return ;
  fi ;
  
  if [ "$DO_OGG" = "Y" ]
  then
    [ "$MF_PDB_COPY_RUN_STATE" != "COPY" -a "$MF_PDB_COPY_RUN_STATE" != "SWITCHED" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with GOLDEN-GATE setup"
    startStep "DO_OGG : Setup Golden-Gate Replicate"
    mfRepo_updateProgress OGG
    mfTestOGG
    
    if [ "$MF_TGT_REPLICA" = "" ]
    then
      if [ "$MF_PDB_COPY_RUN_STATE" = "COPY" ]
      then
        tns=${MF_TGT_TMPPDB_TNS}
        tgtConnect=${MF_TGT_TMPPDB_CONNECT}
      else
        tns=${MF_TGT_PDB_TNS}
        tgtConnect=${MF_TGT_PDB_CONNECT}
      fi
      infoAction "Create tgtpdb connection" "$I3"
      
      #echo "MF_SRC_EXTRACT='${MF_SRC_EXTRACT}'"
      EXTRACT_NAME="${MF_SRC_EXTRACT}"
      
      CONNECTION_EXTRACT=$(mfOGG_GetConnectionFromExtract "${EXTRACT_NAME}")
      CONNECTION_ID=$(echo "${CONNECTION_EXTRACT}" | cut -d '.' -f1 | sed 's/[A-Za-z]//g')
      
      # curl -k -n -X GET https://s02vl9944640.fr.net.intra/services/OGG4_DEPL1/adminsrvr/v2/extracts/EXTGZTZJ -H 'Content-Type: application/json' -H 'Accept: application/json' -u 'oggadmin:Qea90Av%2g4O~_xpPda5qEcqL' | jq | egrep -i '"alias":|"domain":'
      
      #echo "CONNECTION_EXTRACT='${CONNECTION_EXTRACT}'"
      #echo "CONNECTION_ID='${CONNECTION_ID}'"
      
      if [ ! -z "${CONNECTION_ID}" ]; then
        mfOGG_DeleteAlias "domain${CONNECTION_ID}" "tgtalias${CONNECTION_ID}" | sed 's/delete /Delete /gi' | egrep -v "^[[:space:]]*$"
      fi
      mfOGG_CreateAlias "${CONNECTION_ID}" "tgtalias" "${MF_TGT_TMPPDB_USER}" "${MF_TGT_TMPPDB_PASSWORD}" "${tns}" | egrep -v "^[[:space:]]*$"


      infoAction "Create Heartbeat table" "$I3"
      
      output=$(mfOGG_GetHeartbeatTable "domain${CONNECTION_ID}.tgtalias${CONNECTION_ID}" | grep -i exist)
      
      # while IFS= read -r result; do
        # infoAction "$(echo $result | cut -d ':' -f2- | cut -d '"' -f2- | rev | cut -d '"' -f2- | rev)" "$B4"
      # done <<< "$output"
      
      if [ $(echo "$output" | grep -i "gg_heartbeat exists" | wc -l | tr -d ' ') -gt 0 ]; then
        mfOGG_DeleteHeartbeatTable "domain${CONNECTION_ID}.tgtalias${CONNECTION_ID}"
      fi
      
      mfOGG_CreateHeartbeatTable "domain${CONNECTION_ID}.tgtalias${CONNECTION_ID}" | egrep -v "^[[:space:]]*$"
      
      output=$(mfOGG_GetHeartbeatTable "domain${CONNECTION_ID}.tgtalias${CONNECTION_ID}" | grep -i exist)
      # while IFS= read -r result; do
        # infoAction "$(echo $result | cut -d ':' -f2- | cut -d '"' -f2- | rev | cut -d '"' -f2- | rev)" "$B4"
      # done <<< "$output"
      
      ## Creation Checkpoint table
      
      infoAction "Create Checkpoint table" "$I3"
      
      output=$(mfOGG_GetCheckpointTable "domain${CONNECTION_ID}.tgtalias${CONNECTION_ID}" "${MF_TGT_TMPPDB_USER}.gg_checkpoint" | grep -i created)
      # while IFS= read -r result; do
        # infoAction "$(echo $result | cut -d ':' -f2- | cut -d '"' -f2- | rev | cut -d '"' -f2- | rev)" "$B4"
      # done <<< "$output"
      
      if [ $(echo "$output" | grep -i "gg_checkpoint has been created" | wc -l | tr -d ' ') -gt 0 ]; then
        mfOGG_DeleteCheckpointTable "domain${CONNECTION_ID}.tgtalias${CONNECTION_ID}" "${MF_TGT_TMPPDB_USER}.gg_checkpoint"
      fi
      
      mfOGG_CreateCheckpointTable "domain${CONNECTION_ID}.tgtalias${CONNECTION_ID}" "${MF_TGT_TMPPDB_USER}.gg_checkpoint"
      
      output=$(mfOGG_GetCheckpointTable "domain${CONNECTION_ID}.tgtalias${CONNECTION_ID}" "${MF_TGT_TMPPDB_USER}.gg_checkpoint" | grep -i created)
      # while IFS= read -r result; do
        # infoAction "$(echo $result | cut -d ':' -f2- | cut -d '"' -f2- | rev | cut -d '"' -f2- | rev)" "$B4"
      # done <<< "$output"
      
      ## Retrieve extract parameters
      
      forward_extract=$(mfOGG_GetConfig "${EXTRACT_NAME}.prm")
      echo "${forward_extract}"
      
      ## Creation Replicat
      
      infoAction "Create forward replicat" "$I3"
      
      REPLICAT_NAME=$(mfOGG_GenerateReplicaName)
      while (( $(mfOGG_ListReplicas | grep -i ${REPLICAT_NAME} | wc -l | tr -d ' ') != 0 )); do
        REPLICAT_NAME=$(mfOGG_GenerateReplicaName)
      done
      
      # echo "REPLICAT_NAME='${REPLICAT_NAME}'"
      

      libAction "Source PDB" "$I4"
      if [ "$MF_SOURCE_IS_NON_CDB" = "Y" ]
      then
        src_pdb=$(exec_sql "$MF_SRC_PDB_CONNECT" "select name from v\$database;") || die "Unable to get Source DB Name ($src_pdb)"
      else
        src_pdb=$(exec_sql "$MF_SRC_PDB_CONNECT" "select pdb_name from dba_pdbs;") || die "Unable to get Source PDB Name ($src_pdb)"
      fi
      echo "$src_pdb"
      libAction "Target PDB" "$I4"
      if [ "$MF_TARGET_IS_PDB" != "Y" ]
      then
        tgt_pdb=$(exec_sql "$tgtConnect" "select name from v\$database;") || die "Unable to get Target PDB Name ($tgt_pdb)"
      else
        tgt_pdb=$(exec_sql "$tgtConnect" "select pdb_name from dba_pdbs;") || die "Unable to get Target PDB Name ($tgt_pdb)"
      fi
      echo "$tgt_pdb"
      libAction "Target CDB" "$I4"
      tgt_cdb=$(exec_sql "$tgtConnect" "select name from v\$database;") || die "Unable to get Target CDB Name ($tgt_cdb)"
      echo "$tgt_cdb"
      
      mfOGG_GetTrailName "extract" "${EXTRACT_NAME}" "$I4" 2>/dev/null
      EXTRACT_TRAIL_NAME="${RESULT}"
      [ "$EXTRACT_TRAIL_NAME" = "" ] && die "Unable to retrieve extract trail name"
      
      forward_replica=$(echo "$forward_extract" | \
                       sed -e "s;^ *EXTRACT.*$;REPLICAT ${REPLICAT_NAME};" \
                           -e "s;^ *USERIDALIAS.*$;USERIDALIAS tgtalias${CONNECTION_ID} DOMAIN domain${CONNECTION_ID};" \
                           -e "s/^TABLE \([A-Z0-9_]\+\.[A-Z0-9_*]\+\);$/MAP \1, TARGET \1;/" \
                           -e "s;TABLEEXCLUDE ;MAPEXCLUDE ;g") || die "Error modifying replicat config"
      forward_replica=$(echo "$forward_replica" | grep -vi "EXTTRAIL ")
      forward_replica=$(echo "$forward_replica" | grep -vi "TRANLOGOPTIONS ")
      forward_replica=$(echo "$forward_replica" | grep -vi "REPORTFETCH")
      forward_replica=$(echo "$forward_replica" | grep -vi "FETCHOPTIONS")
      forward_replica=$(echo "$forward_replica" | grep -vi "^include ")
      forward_replica=$(echo "$forward_replica" | sed 's;, #exclude();;')
      forward_replica=$(echo "$forward_replica" | grep -vi "DDL INCLUDE ")
      forward_replica=$(echo "$forward_replica" | sed '/REPORTCOUNT/a \
  MAP_PARALLELISM 8 \
  APPLY_PARALLELISM 8 \
  BATCHSQL \
  DBOPTIONS ENABLE_INSTANTIATION_FILTERING \
  DBOPTIONS DEFERREFCONST \
  -- \
  --  If you need to accelerate, uncomment below and deactivate foreign keys on target database \
  -- \
  -- SPLIT_TRANS_RECS 50')
      forward_replica=$(echo "$forward_replica" | sed -e 's;";\\\\\\\\";g')
      echo "${forward_replica}"
      # exit
      
      if [ "$MF_TARGET_IS_PDB" = "Y"  -a "$MF_SOURCE_IS_NON_CDB" = "Y" ]
      then
        # infoAction "NO PDB --> PDB : Add PDB in TARGET" "$I4"
        forward_replica=$(echo "$forward_replica" | sed -e "s;TARGET ;TARGET $tgt_pdb\.;" -e "s;\\$;\\\\$;g")
        # forward_replica=$(echo "$forward_replica" | sed "/^USERIDALIAS /a SOURCECATALOG $tgt_pdb" )
      fi
      
      # echo "$forward_replica" | sed -e "s;^;        ;"
      # echo "${forward_replica}"
      
      # mfRepo_updateProgress CRE_REPL_$forward_replica
      mfOGG_CreateReplica "${REPLICAT_NAME}" "$forward_replica" "tgtalias${CONNECTION_ID}" "domain${CONNECTION_ID}" "${EXTRACT_TRAIL_NAME}" "" "$I4" | egrep -v "^[[:space:]]*$"
      
      MF_SRC_EXTRACT="${EXTRACT_NAME}"
      MF_TGT_REPLICA="${REPLICAT_NAME}"
      MF_REPLICATION_STATE="SRC-TGT"
      
      if [ "${MF_REPO_CONNECT}" != "" ]
      then
        updateReplicationInformation "$MF_SRC_EXTRACT" "$MF_TGT_REPLICA" "$MF_TGT_EXTRACT" "$MF_SRC_REPLICA" "$MF_REPLICATION_STATE" | sed 's/Ok/OK/g'
        # exec_sql "${MF_REPO_CONNECT}" "UPDATE migration_attempts SET TARGET_REPLICA='${REPLICAT_NAME}' WHERE mig_id = ${MFAUTO_MIG_ID};
  # COMMIT;"
        REPO_TARGET_REPLICA=$(exec_sql "${MF_REPO_CONNECT}" "SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
  SELECT TO_CHAR(TARGET_REPLICA) FROM migration_attempts WHERE mig_id = ${MFAUTO_MIG_ID};" | grep -v "^$" | tr -d ' ')
        if [ "${REPO_TARGET_REPLICA}" = "${REPLICAT_NAME}" ]; then
          infoAction "Updated REPLICAT_NAME and REPO TARGET_REPLICAT match (${REPO_TARGET_REPLICA})" "$B2"
        else
          infoAction "Updated REPLICAT_NAME and REPO TARGET_REPLICAT mismatch (${REPLICAT_NAME} <> ${REPO_TARGET_REPLICA})" "$B2"
        fi
      fi


      #  
      #    Grosse bidouille pour que mfInfoOGG fonctionne comme d'habitude
      #
      exec_sql "$tgtConnect" "create table CHECKPOINT123456_${REPLICAT_NAME}_TMP (n number);" "Create fake table for replicat" "$I3"
    else
      echo "
      
           Replicat $MF_TGT_REPLICA already exists (ignoring creation)
           
           "
      REPLICAT_NAME=$MF_TGT_REPLICA 
    fi

    if [ "${REPLICAT_NAME}" != "" ]
    then
      if [ "${MF_REPO_CONNECT}" != "" ]
      then
        infoAction "Start replicat ${REPLICAT_NAME}" "$I3"
        START_OPTION=""
        infoAction "Retrieve SCN from REPO database" "$I4"
        scn=0
        scn=$(exec_sql "${MF_REPO_CONNECT}" "SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT TO_CHAR(switch_op_scn) FROM migration_attempts WHERE mig_id = ${MFAUTO_MIG_ID};" | grep -v "^$" | tr -d ' ')
        infoAction "Identified SCN is ${scn}" "$B4"

        echo
        if [[ "${scn}" =~ ^[0-9]+$ ]] && [ "${scn}" -ne 0 ]
        then
          START_OPTION="AFTERCSN"
          infoAction "Starting replicat ${REPLICAT_NAME} with ${START_OPTION} option" "$B3"
          mfRepo_updateProgress START_${START_OPTION}_${REPLICAT_NAME}
          [ "$(mfOGG_StatusReplica $REPLICAT_NAME)" != "running" ] \
                 && mfOGG_StartReplicaAfterCSN $REPLICAT_NAME $scn "$I4" | egrep -v "^[[:space:]]*$"
          i=0
          while [ $i -le 15 -a "$(mfOGG_StatusReplica $REPLICAT_NAME)" != "running" ]
          do
            sleep 2
            i=$(($i + 1))
          done
          if [ $i -lt 15 ]
          then 
            infoAction "Replicat is running" "$B4"
            # infoAction "Update SCN in REPO" "$B4"
            # NEW_SCN="-${scn}"
            # exec_sql "${MF_REPO_CONNECT}" "UPDATE migration_attempts SET switch_op_scn=${NEW_SCN} WHERE mig_id = ${MFAUTO_MIG_ID};
# COMMIT;"
            # REPO_SCN=0
            # REPO_SCN=$(exec_sql "${MF_REPO_CONNECT}" "SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
# SELECT TO_CHAR(switch_op_scn) FROM migration_attempts WHERE mig_id = ${MFAUTO_MIG_ID};" | grep -v "^$" | tr -d ' ')
            # if [ "${REPO_SCN}" = "${NEW_SCN}" ]; then
              # infoAction "Updated SCN and REPO SCN match (${REPO_SCN})" "$B4"
            # else
              # infoAction "Updated SCN and REPO SCN mismatch (${NEW_SCN} <> ${REPO_SCN})" "$B4"
            # fi
          else
            infoAction "Replicat is not running" "$B4"
            infoAction "SCN cannot be updated in REPO" "$B4"
          fi
        else
           mfRepo_updateProgress START_$REPLICAT_NAME
               [ "$(mfOGG_StatusReplica $REPLICAT_NAME)" != "running" ] \
                  && mfOGG_StartReplica $REPLICAT_NAME "$I4"
        fi
      # else
        # mfRepo_updateProgress START_$REPLICAT_NAME
          # [ "$(mfOGG_StatusReplica $REPLICAT_NAME)" != "running" ] \
             # && mfOGG_StartReplica $REPLICAT_NAME "$I3" 
      fi
    fi
    endStep
  fi
} 


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : addRollingEndSteps
#
#  Description         : Performs the add Rolling End Steps step used by
#                        mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Iterate over the selected objects or command output.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

addRollingEndSteps()
{
  infoAction "Add steps to FINISH ROLLING)" "$I1"
  infoAction "----------------------------" "$B1"
  echo

  libAction "Check for Roll-Forward" "$I2"
  cnt="$(exec_sql "$MF_REPO_CONNECT" "select to_char(count(*)) 
                                      from migration_steps ms
                                      join mf_scripts sc on (ms.mfs_id = sc.mfs_id)
                                      where sc.script_name = 'mfPDBCopy.sh'
                                      and   ms.mig_id = $MFAUTO_MIG_ID
                                      and   regexp_like(ms.parameters,'DO_SYNCH_COPY');")"  || die "$cnt"
  if [ "$cnt" != "0" ]
  then
    echo Present
  else
    echo "Not Present"
    seq=$(exec_sql "$MF_REPO_CONNECT" "select to_char(seq_num+1) from migration_steps where mig_id=$MFAUTO_MIG_ID and GLOBAL_STEP_CODE='210-MIG_RUN' ;")
    exec_sql "$MF_REPO_CONNECT" "
                  insert into migration_steps (
                      prj_name
                     ,mig_id
                     ,mfs_id
                     ,seq_num
                     ,parameters
                     ,run_if_previous_failed
                     ,comments)  SELECT
                                    ma.prj_name
                                    ,ma.mig_id
                                    ,sc.mfs_id
                                    ,$seq + 1
                                    ,'-S \"DO_SYNCH_COPY\"'
                                    ,'Y'
                                    ,'Roll forward (Auto-Addition)'
                                  FROM
                                      migration_attempts ma
                                  join mf_scripts sc on (sc.prj_name = ma.prj_name and sc.script_name = 'mfPDBCopy.sh')
                                  WHERE
                                  ma.mig_id=$MFAUTO_MIG_ID ;
                                " "Add roll forward" "$I3" || die "Error adding step"
  fi

  libAction "Check for Finish copy" "$I2"
  cnt="$(exec_sql "$MF_REPO_CONNECT" "select to_char(count(*)) 
                                      from migration_steps ms
                                      join mf_scripts sc on (ms.mfs_id = sc.mfs_id)
                                      where sc.script_name = 'mfPDBCopy.sh'
                                      and   ms.mig_id = $MFAUTO_MIG_ID
                                      and   regexp_like(ms.parameters,'-f');")"  || die "$cnt"
  if [ "$cnt" != "0" ]
  then
    echo Present
  else
    echo "Not Present"
    seq=$(exec_sql "$MF_REPO_CONNECT" "select to_char(seq_num+2) from migration_steps where mig_id=$MFAUTO_MIG_ID and GLOBAL_STEP_CODE='210-MIG_RUN' ;")
    exec_sql "$MF_REPO_CONNECT" "
                  insert into migration_steps (
                      prj_name
                     ,mig_id
                     ,mfs_id
                     ,seq_num
                     ,parameters
                     ,run_if_previous_failed
                     ,comments)  SELECT
                                    ma.prj_name
                                    ,ma.mig_id
                                    ,sc.mfs_id
                                    ,$seq + 1
                                    ,'-f'
                                    ,'Y'
                                    ,'Finish copy (Auto-Addition)'
                                  FROM
                                      migration_attempts ma
                                  join mf_scripts sc on (sc.prj_name = ma.prj_name and sc.script_name = 'mfPDBCopy.sh')
                                  WHERE
                                  ma.mig_id=$MFAUTO_MIG_ID ;
                                " "Add finish" "$I3" || die "Error adding step"
  fi

}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_ADD_STEPS
#
#  Description         : Performs the DO ADD STEPS step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Iterate over the selected objects or command output.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Some file paths are redirected without quotes and may fail with
#                          spaces.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_ADD_STEPS()
{
  startStep "DO_ADD_STEPS : Add migration steps in the attempt definition"
  mfRepo_updateProgress ADD_STEPS

  infoAction "Add steps" "$I1"
  infoAction "---------" "$B1"
  echo

  libAction "Check for Encrypt" "$I2"
  cnt="$(exec_sql "$MF_REPO_CONNECT" "select to_char(count(*)) 
                                      from migration_steps ms
                                      join mf_scripts sc on (ms.mfs_id = sc.mfs_id)
                                      where sc.script_name = 'mfPDBCopy.sh'
                                      and   ms.mig_id = $MFAUTO_MIG_ID
                                      and   regexp_like(ms.parameters,'DO_ENCRYPT');")"  || die "$cnt"
  if [ "$cnt" != "0" ]
  then
    echo Present
  else
    echo "Not Present"
    seq=$(exec_sql "$MF_REPO_CONNECT" "select to_char(seq_num+6) from migration_steps where mig_id=$MFAUTO_MIG_ID and GLOBAL_STEP_CODE='210-MIG_RUN' ;")
    exec_sql "$MF_REPO_CONNECT" "
    set feed on
                  insert into migration_steps (
                      prj_name
                     ,mig_id
                     ,mfs_id
                     ,seq_num
                     ,parameters
                     ,run_if_previous_failed
                     ,comments)  SELECT
                                    ma.prj_name
                                    ,ma.mig_id
                                    ,sc.mfs_id
                                    ,$seq + 1
                                    ,'-S \"DO_ENCRYPT_BIGFILE DO_ENCRYPT_ALL\"'
                                    ,'Y'
                                    ,'Encrypt tablespaces: (Auto-Addition)'
                                  FROM
                                      migration_attempts ma
                                  join mf_scripts sc on (sc.prj_name = ma.prj_name and sc.script_name = 'mfPDBCopy.sh')
                                  WHERE
                                  ma.mig_id=$MFAUTO_MIG_ID ;
                                " "Add Encrypt" "$I3" || die "Error adding step"
  fi

  libAction "Check for Move" "$I2"
  cnt="$(exec_sql "$MF_REPO_CONNECT" "select to_char(count(*)) 
                                      from migration_steps ms
                                      join mf_scripts sc on (ms.mfs_id = sc.mfs_id)
                                      where sc.script_name = 'mfPDBCopy.sh'
                                      and   ms.mig_id = $MFAUTO_MIG_ID
                                      and   regexp_like(ms.parameters,'DO_MOVE');")"  || die "$cnt"
  if [ "$cnt" != "0" ]
  then
    echo Present
  else
    echo "Not Present"
    seq=$(exec_sql "$MF_REPO_CONNECT" "select to_char(seq_num+7) from migration_steps where mig_id=$MFAUTO_MIG_ID and GLOBAL_STEP_CODE='210-MIG_RUN' ;")
    exec_sql "$MF_REPO_CONNECT" "
                  insert into migration_steps (
                      prj_name
                     ,mig_id
                     ,mfs_id
                     ,seq_num
                     ,parameters
                     ,step_type
                     ,comments)  SELECT
                                    ma.prj_name
                                    ,ma.mig_id
                                    ,sc.mfs_id
                                    ,$seq + 2
                                    ,'-S \"DO_MOVE\"'
                                    ,'I'
                                    ,'OPTIONAL : Move to BIGFILE tablespaces : (Auto-Addition)'
                                  FROM
                                      migration_attempts ma
                                  join mf_scripts sc on (sc.prj_name = ma.prj_name and sc.script_name = 'mfPDBCopy.sh')
                                  WHERE
                                  ma.mig_id=$MFAUTO_MIG_ID ;
                                " "Add Move" "$I3" || die "Error adding step"
  fi

  libAction "Check for Dataguard" "$I2"
  cnt="$(exec_sql "$MF_REPO_CONNECT" "select to_char(count(*)) 
                                      from migration_steps ms
                                      join mf_scripts sc on (ms.mfs_id = sc.mfs_id)
                                      where sc.script_name = 'mfPDBCopy.sh'
                                      and   ms.mig_id = $MFAUTO_MIG_ID
                                      and   regexp_like(ms.parameters,'DO_DG');")"  || die "$cnt"
  if [ "$cnt" != "0" ]
  then
    echo Present
  else
    echo "Not Present"
    seq=$(exec_sql "$MF_REPO_CONNECT" "select to_char(seq_num+5) from migration_steps where mig_id=$MFAUTO_MIG_ID and GLOBAL_STEP_CODE='300-POST_TT' ;")
    exec_sql "$MF_REPO_CONNECT" "
                  insert into migration_steps (
                      prj_name
                     ,mig_id
                     ,mfs_id
                     ,seq_num
                     ,parameters
                     ,comments)  SELECT
                                    ma.prj_name
                                    ,ma.mig_id
                                    ,sc.mfs_id
                                    ,$seq
                                    ,'-S \"DO_DG_ALL\"'
                                    ,'Resynch DATAGUARD: (Auto-Addition)'
                                  FROM
                                      migration_attempts ma
                                  join mf_scripts sc on (sc.prj_name = ma.prj_name and sc.script_name = 'mfPDBCopy.sh')
                                  WHERE
                                  ma.mig_id=$MFAUTO_MIG_ID ;
                                " "Add Encrypt" "$I3" || die "Error adding step"
  fi


  libAction "Check for Cleanup" "$I2"
  cnt="$(exec_sql "$MF_REPO_CONNECT" "select to_char(count(*)) 
                                      from migration_steps ms
                                      join mf_scripts sc on (ms.mfs_id = sc.mfs_id)
                                      where sc.script_name = 'mfPDBCopy.sh'
                                      and   ms.mig_id = $MFAUTO_MIG_ID
                                      and   regexp_like(ms.parameters,'DO_CLEANUP');")"  || die "$cnt"
  if [ "$cnt" != "0" ]
  then
    echo Present
  else
    echo "Not Present"
    seq=$(exec_sql "$MF_REPO_CONNECT" "select to_char(seq_num-1) from migration_steps where mig_id=$MFAUTO_MIG_ID and GLOBAL_STEP_CODE='310-POST-CLOSE' ;")
    exec_sql "$MF_REPO_CONNECT" "
                  insert into migration_steps (
                      prj_name
                     ,mig_id
                     ,mfs_id
                     ,seq_num
                     ,parameters
                     ,comments)  SELECT
                                    ma.prj_name
                                    ,ma.mig_id
                                    ,sc.mfs_id
                                    ,$seq
                                    ,'-S \"DO_CLEANUP\"'
                                    ,'Cleaunp PDB Copy (remove unused PDB) : (Auto-Addition)'
                                  FROM
                                      migration_attempts ma
                                  join mf_scripts sc on (sc.prj_name = ma.prj_name and sc.script_name = 'mfPDBCopy.sh')
                                  WHERE
                                  ma.mig_id=$MFAUTO_MIG_ID ;
                                " "Add cleanup" "$I3" || die "Error adding step"
  fi
  echo
  infoAction "Schedule steps" "$I1"
  infoAction "--------------" "$B1"
  echo
  infoAction "Schedule Encrypt in 30 minutes" "$I2"
  libAction "Check if Encrypt is scheduled" "  $I2"
  tmp=$(exec_sql "$MF_REPO_CONNECT" "select 
                                             uj.job_name|| ';' || ms.mstep_id
                                          --  ,ms.MIG_ID
                                          --  ,sc.SCRIPT_NAME
                                          FROM
                                            migration_steps ms
                                            join mf_scripts sc on (ms.mfs_id = sc.mfs_id)
                                            left join user_scheduler_jobs uj on (uj.job_name = ms.job_name)
                                          where 
                                            mig_id = $MFAUTO_MIG_ID
                                            and sc.script_name = 'mfPDBCopy.sh'
                                            and ms.parameters like '%DO_ENCRYPT%';")
  job_name=$(echo "$tmp" | cut -f1 -d ";")
  step=$(echo "$tmp" | cut -f2 -d ";")
  if [ "$job_name" = "" ]
  then
    echo "Not scheduled"
    exec_sql "$MF_REPO_CONNECT" "begin
      MF_MIG_ACTIONS.SCHEDULEMIGRATIONSTEP(
                 P_MSTEP_ID => $step
                ,P_STARTDATE => sysdate + (1/24/60)*30);
    end ;
  /" "Encrypt step scheduled to run in 30 minutes" "$I3"|| die "Unable to schedule the Job"
  else
    echo "Already scheduled ($job_name)"
  fi
  
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_CLEANUP
#
#  Description         : Performs the DO CLEANUP step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_CLEANUP() 
{
  [ "$MF_PDB_COPY_RUN_STATE" != "SWITCHED" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with CLEANUP"
  startStep "DO_CLEANUP : Cleanup Target"
  mfRepo_updateProgress CLEANUP

  exec_sql -verbose "$MF_TGT_CDB_CONNECT" "
  set head on pages 200 lines 200 tab off
  col name format a30
  select con_id,name,open_mode,restricted,to_char(creation_time,'dd/mm/yyyy hh24:mi:ss') creation_time from v\$pdbs;" "Pluggable databases present at start" "$I1"

  libAction "Is $MF_TGT_DBNAME opened normal" "$I1"
  tmp=$(exec_sql "$MF_TGT_CDB_CONNECT" "select 'YES' from v\$pdbs where name='$MF_TGT_DBNAME' and open_mode='READ WRITE' and RESTRICTED='NO';") || die "$tmp"
  if [ "$tmp" = "YES" ]
  then
    echo "Yes"
  else
    echo "No"
    die "$MF_TGT_DBNAME PDB is not opened in normal (read-write) mode"
  fi
  CustomerSpecific_provisioningUpdates

  exec_sql -verbose "$MF_TGT_CDB_CONNECT" "
set term off 
whenever sqlerror continue
  drop database link $COPY_DB_LINK ;
    " "Drop the copy database Link in TARGET CDB" "$I1"
  exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$(cat <<%%
. $CDB_NAME.env || exit 1
sqlplus -s / as sysdba <<_SQL_
alter pluggable database $OLD_PDB close immediate instances=all ;
whenever sqlerror exit failure
drop pluggable database $OLD_PDB including datafiles ;
SHOW PDBS
_SQL_
echo \$?
%%
)
" "Drop the original PDB ($OLD_PDB)" "$I1"
  endStep 
} 


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : isDb
#
#  Description         : Performs the is Db step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

isDb()
{
  local mode="$1"
  exec_on_target -verbose "${MF_SUDOER:-opc}@$standByNode1" "oracle" "$(cat <<%%
. $CDB_NAME.env || exit 1 ; 
v=\$(sqlplus -s / as sysdba << _SQL_
set head off pages 0 tab off
select open_mode from v\\\\\$database ;
_SQL_
)
echo "[\$v]"
[ "\$v" != "$mode" ] && exit 1 || exit 0
%%
)" "Is database $mode" "$I2" || die "Database is not $mode"
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : DO_DG_ALL
#
#  Description         : Performs the DO DG ALL step used by mfPDBCopy.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Execute SQL statements through the configured database connection.
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - SQL text is assembled in shell variables and depends on valid
#                          environment values.
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

DO_DG_ALL()
{
  [ "$MF_PDB_COPY_RUN_STATE" != "SWITCHED" -a "$MF_PDB_COPY_RUN_STATE" != "INITIAL" ] && die "Current run state ($MF_PDB_COPY_RUN_STATE) is not compatible with DG setup"

    failIfRestricted

  startStep "DO_DG : Reconcile DATAGUARD"  
  libAction "Get first node of cluster 1" "$I1"
  mfRepo_updateProgress "DG"
  export PDB_COPY_PHASE=ROLLING_RECOVER
  node1Cluster1=$(exec_sql "$MF_REPO_CONNECT" "select fqdn from target_nodes where tclu_id = (select tclu_id
                                                                                             from   migration_attempts
                                                                                             where  mig_id=$MFAUTO_MIG_ID)
                                              and ord_num=1;")
  echo "$node1Cluster1"  
  nodesCluster1=$(exec_sql "$MF_REPO_CONNECT" "select fqdn from target_nodes where tclu_id = (select tclu_id
                                                                                             from   migration_attempts
                                                                                             where  mig_id=$MFAUTO_MIG_ID);")
  libAction "Get first node of Cluster 2" "$I1"
  node1Cluster2=$(exec_sql "$MF_REPO_CONNECT" "select fqdn from target_nodes where tclu_id = (select peer_tclu_id
                                                                                                 from   target_clusters
                                                                                                 where  tclu_id = (select tclu_id
                                                                                                                   from   migration_attempts
                                                                                                                   where  mig_id=$MFAUTO_MIG_ID
                                                                                                                   )
                                                                                                )
                                                  and ord_num=1;")
  echo "$node1Cluster2"
  nodesCluster2=$(exec_sql "$MF_REPO_CONNECT" "select fqdn from target_nodes where tclu_id = (select peer_tclu_id
                                                                                                 from   target_clusters
                                                                                                 where  tclu_id = (select tclu_id
                                                                                                                   from   migration_attempts
                                                                                                                   where  mig_id=$MFAUTO_MIG_ID
                                                                                                                   )
                                                                                                );")
  echo
  libAction "Primary running on" "$I1"
  hostsPrim=$(exec_sql "$MF_TGT_PDB_CONNECT" "select host_name from gv\$instance;" | tr '\n' ' ')
  echo "$hostsPrim"
  
  if [ "$(echo "$hostsPrim" | grep "$(echo "$node1Cluster1" | cut -f1 -d".")")" != "" ]
  then 
    primaryNode1=$node1Cluster1
    standByNode1=$node1Cluster2
    standByNodes=$nodesCluster2
  else
    primaryNode1=$node1Cluster2
    standByNode1=$node1Cluster1
    standByNodes=$nodesCluster1
  fi
  libAction "Primary node 1 is" "$I2" ; echo "$primaryNode1"
  echo  

  [ "$standByNode1" = "" ] && endRun "No stand-by is configured for this database"
  
  out=$(exec_on_target -verbose "${MF_SUDOER:-opc}@$primaryNode1" "oracle" ". $CDB_NAME.env || exit 1 ; dgmgrl / \"show configuration lag\"" "Dataguard Configuration" "$I1")
  echo "$out"
  libAction "Primary database : " "$I2"
  primaryDB=$(echo "$out" | grep "Primary database" | cut -f2 -d "|" | cut -f1 -d "-" | sed -e "s; ;;g")
  echo $primaryDB
  libAction "Stand-By database : " "$I2"
  standByDB=$(echo "$out" | grep "Physical standby database" | cut -f2 -d "|" | cut -f1 -d "-" | sed -e "s; ;;g") 
  echo $standByDB
  echo
 
  mfRepo_updateProgress "STOP_STBY"
  exec_on_target "${MF_SUDOER:-opc}@$primaryNode1" "oracle" ". $CDB_NAME.env || exit 1 ; dgmgrl / \"edit database $standByDB set state=apply-off\"" "Stop APPLY on $standByDB" "$I1"


  # exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "oracle" ". $CDB_NAME.env || exit 1 ; 
  # if [ \"\$(srvctl status database -d \$ORACLE_UNQNAME | tr -d ' ' | grep isrunning)\" != \"\" ]
  # then
    # srvctl stop database -d \$ORACLE_UNQNAME -o abort
    # if [ \"\$(srvctl status database -d \$ORACLE_UNQNAME | tr -d ' ' | grep isrunning)\" != \"\" ]
    # then
      # echo Unable to stop \$ORACLE_UNQNAME
      # exit 1
    # fi
    # exit $?
  # else
    # echo Database already stopped
    # exit 0
  # fi" "stop stand-by database ($standByDB)" "$I1" 
  
  # if [ $? -ne 0 ]
  # then
    infoAction "Problem stopping the stand-by ... Aborting it" "$I2"
    for n in $standByNodes
    do  
    exec_on_target "${MF_SUDOER:-opc}@$n" "oracle" ". $CDB_NAME.env || exit 1 ; 
    echo \"shutdown abort\" | sqlplus -s / as sysdba
      exit 0
    " "Abort stand-by on node $n ($standByDB)" "$I3" || die "Unable to stop stand-by database (DATAGUARD recreation process aborted)"
    done
  # fi


  mfRepo_updateProgress "REST_CTR"
  libAction "Primary password file" "$I1"
  primPwd=$(exec_on_target -tty "${MF_SUDOER:-opc}@$primaryNode1" "oracle" ". $CDB_NAME.env || exit 1 ; srvctl config database -d \$ORACLE_UNQNAME | grep -i Password | cut -f2 -d\":\"")
  echo $primPwd
  primPwd=$(echo "$primPwd" | sed -e "s;^\+;;g") 
  exec_on_target "${MF_SUDOER:-opc}@$primaryNode1" "grid" "rm -f /tmp/$CDB_NAME.pwd ;asmcmd pwcopy $primPwd /tmp/$CDB_NAME.pwd && chmod 775 /tmp/$CDB_NAME.pwd || exit 1" "Extract & copy" "$I2" || die "unable to get the password file from ASM"
  scp -q ${MF_SUDOER:-opc}@$primaryNode1:/tmp/$CDB_NAME.pwd $TMPFILE2 || die "unable to get the password file from Primary"
  exec_on_target "${MF_SUDOER:-opc}@$primaryNode1" "grid" "rm -f /tmp/$CDB_NAME.pwd" "Remove" "$I2" || die "unable to remove the password file from primary"
  
  libAction "Original stand by password file" "$I1"
  stbyPwd=$(exec_on_target -tty "${MF_SUDOER:-opc}@$standByNode1" "oracle" ". $CDB_NAME.env || exit 1 ; srvctl config database -d \$ORACLE_UNQNAME | grep -i Password | cut -f2 -d\":\"")
  echo $stbyPwd
  stbyPwd=$(echo "$stbyPwd" | sed -e "s;^\+;;g") 
  stbyNew=$(dirname $stbyPwd)/pwd$standByDB
  scp -q $TMPFILE2 ${MF_SUDOER:-opc}@$standByNode1:/tmp/$CDB_NAME.pwd  || die "unable to copy the password file to stand by"
  exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "opc" "chmod 775 /tmp/$CDB_NAME.pwd" "Change ownership of /tmp/$CDB_NAME.pwd" "$I2" 
  exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "grid" "asmcmd rm $stbyPwd " "Remove old password file" "$I2" 
  exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "grid" "asmcmd mkdir $(dirname $stbyPwd) ; exit 0 " "Create ASM FOLDER" "$I2" 
  exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "grid" "asmcmd pwcopy /tmp/$CDB_NAME.pwd $stbyNew || exit 1" "Copy to standby ($stbyNew)" "$I2" || die "unable to put the password file from ASM"
  exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "opc" "rm -f /tmp/$CDB_NAME.pwd || exit 1" "Remove temp" "$I2" || die "unable to remove in /tmp"
  echo "srvctl modify database -d \$ORACLE_UNQNAME -pwfile $stbyNew"
  exec_on_target -tty "${MF_SUDOER:-opc}@$standByNode1" "oracle" ". $CDB_NAME.env || exit 1 ; srvctl modify database -d \$ORACLE_UNQNAME -pwfile $stbyNew" "Set passwword in clusterware"
  libAction "New stand by password file" "$I1"
  stbyPwd=$(exec_on_target -tty "${MF_SUDOER:-opc}@$standByNode1" "oracle" ". $CDB_NAME.env || exit 1 ; srvctl config database -d \$ORACLE_UNQNAME | grep -i Password | cut -f2 -d\":\"")
  echo $stbyPwd

  exec_on_target -verbose "${MF_SUDOER:-opc}@$standByNode1" "oracle" "$(cat << %%
. $CDB_NAME.env || exit 1 ;
dg=\$(asmcmd --privilege sysdba ls | grep DATA | cut -f1 -d"/")
asmcmd --privilege sysdba ls \$dg/\$ORACLE_UNQNAME | egrep "^[0-9A-F]*/|DATAFILE|CONTROLFILE|LOGFILE|TEMPFILE" | while read d
do
  echo "-remove \$d"
  asmcmd --privilege sysdba rm -rf \$dg/\$ORACLE_UNQNAME/\$d
done
%%
)
" "Remove data files of DATACX/$ORACLE_UNQNAME" "$I1"
 
  exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "oracle" ". $CDB_NAME.env || exit 1 ; srvctl start instance -d \$ORACLE_UNQNAME -i \$ORACLE_SID -o nomount" "start (nomount) stand-by ($standByDB)" "$I1"

  exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "oracle" "$(cat <<%%
. $CDB_NAME.env || exit 1 ; 
[ "\$(ps -ef | grep \$ORACLE_SID | grep smon)" = "" ] && exit 1 || exit 0
%%
)" "Is database started" "$I2" || die "Database is not started"

  echo
  exec_on_target -verbose "${MF_SUDOER:-opc}@$standByNode1" "oracle" "$(cat <<%%
. $CDB_NAME.env || exit 1 
echo "
RUN {
allocate channel disk1 device type disk ; 
restore standby controlfile from service $primaryDB ;
}" | rman target /
echo "alter database mount;" | sqlplus -s / as sysdba
%%
)" "Restore controlfile and on stand-by ($standByDB)" "$I1"
  echo

  isDb MOUNTED
  
  mfRepo_updateProgress "REST_$CDB_NAME"
  echo
  export PDB_COPY_PHASE=DATAGUARD
  infoAction "launch backgroud monitoring" "$I2"
  {
    while :
    do
      sleep 60
      . $MF_BIN/mfRunMonitor.sh
      sleep 5
    done
  } &
  PDB_COPY_MONITOR=$!
    exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "oracle" "$(cat <<%%
  . $CDB_NAME.env || exit 1
asmDir=\$(echo "show parameter db_create_file_dest" | sqlplus -s / as sysdba | grep db_create_file_dest | awk '{print \$3}')
  rman target / <<_RMAN_
run{
allocate channel disk1 device type disk;
allocate channel disk2 device type disk;
allocate channel disk3 device type disk;
allocate channel disk4 device type disk;
allocate channel disk5 device type disk;
allocate channel disk6 device type disk;
allocate channel disk7 device type disk;
allocate channel disk8 device type disk;

restore database from service $primaryDB ;
recover database from service $primaryDB ;

}
catalog start with '\$asmDir/$standByDB' noprompt ;
_RMAN_
%%
)" "Restore and recover $MF_TGT_DBNAME on stand-by ($standByDB)" "$I1" || { kill -15 $PDB_COPY_MONITOR ; die "Error restoring the database" ; }
  echo
  kill -15 $PDB_COPY_MONITOR


  mfRepo_updateProgress "START_STBY"
  exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "oracle" ". $CDB_NAME.env || exi1t 1 ; srvctl stop database -d \$ORACLE_UNQNAME" "stop stand-by ($standByDB)" "$I1"
  exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "oracle" ". $CDB_NAME.env || exi1t 1 ; srvctl start database -d \$ORACLE_UNQNAME -o mount" "start (mount) stand-by ($standByDB)" "$I1"

  isDb MOUNTED

  exec_on_target -verbose "${MF_SUDOER:-opc}@$standByNode1" "oracle" "$(cat <<%%
. $CDB_NAME.env || exit 1 ; 
  sqlplus -s / as sysdba << _SQL_
set head off pages 0 tab off
set serveroutput on
begin
  for log_cur in ( select group# group_no from v\\\\\$log )
  loop
    dbms_output.put_line('Clearing log group #' || log_cur.group_no ) ;
    execute immediate 'alter database clear logfile group '||log_cur.group_no;
  end loop;
end;
/
_SQL_
%%
)" "Clear REDO LOGS" "$I2" || die "Unable to clear redo-logs"
  

  exec_on_target -verbose "${MF_SUDOER:-opc}@$standByNode1" "oracle" "$(cat <<%%
. $CDB_NAME.env || exit 1 ; 
  sqlplus -s / as sysdba << _SQL_
set head off pages 0 tab off
set serveroutput on
begin
  for log_cur in ( select group# group_no from v\\\\\$standby_log )
  loop
    dbms_output.put_line('Clearing log group #' || log_cur.group_no ) ;
    execute immediate 'alter database clear logfile group '||log_cur.group_no;
  end loop;
end;
/
_SQL_
%%
)" "Clear STAND-BY REDO LOGS" "$I2" || die "Unable to clear STAND-BY redo-logs"

  mfRepo_updateProgress "DG_STATUS"
  exec_on_target -verbose "${MF_SUDOER:-opc}@$primaryNode1" "oracle" ". $CDB_NAME.env || exi1t 1 ; dgmgrl / \"edit database $standByDB set state=apply-on\"" "Start APPLY on $standByDB" "$I1"
  sleep 30
  exec_on_target -verbose "${MF_SUDOER:-opc}@$primaryNode1" "oracle" ". $CDB_NAME.env || exit 1 ; dgmgrl / \"show configuration lag\"" "Dataguard Configuration" "$I1"
  exec_on_target -verbose "${MF_SUDOER:-opc}@$primaryNode1" "oracle" ". $CDB_NAME.env || exi1t 1 ; dgmgrl / \"show database $standByDB\"" "Stand-by database ($standByDB) state" "$I1"

  exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "oracle" ". $CDB_NAME.env || exi1t 1 ; srvctl stop database -d \$ORACLE_UNQNAME" "stop stand-by ($standByDB)" "$I1"
  exec_on_target "${MF_SUDOER:-opc}@$standByNode1" "oracle" ". $CDB_NAME.env || exi1t 1 ; srvctl start database -d \$ORACLE_UNQNAME -o open" "start (open) stand-by ($standByDB)" "$I1"

  sleep 30
  exec_on_target -verbose "${MF_SUDOER:-opc}@$primaryNode1" "oracle" ". $CDB_NAME.env || exit 1 ; dgmgrl / \"show configuration lag\"" "Dataguard Configuration" "$I1"
  exec_on_target -verbose "${MF_SUDOER:-opc}@$primaryNode1" "oracle" ". $CDB_NAME.env || exi1t 1 ; dgmgrl / \"show database $standByDB\"" "Stand-by database ($standByDB) state" "$I1"
}
  
  # ------------------------------------------------------------------------------------------------------

# ******************************************************************************
# ******************************************************************************
# ******************************************************************************
# ******************************************************************************


_____________________________main() { : ; }
[ "$(echo "$*" | grep -- "--help")" != "" ] && { MF_DETAILED_USAGE=Y ; usage ; exit 1 ; }
[ "$(echo "$*" | grep -- "-Q")" != "" ] && LOG_QUIET=Y
[ "$(echo "$*" | grep -- "-V")" != "" ] && LOG_QUIET=N
#
#    This is important to propagate error codes across pipes
#
set -o pipefail


TMPFILE=$(mktemp --suffix .mf.temp)
rm -f $TMPFILE
touch $TMPFILE
{
  #
  #    Set variables which are common to all scripts and run all scripts containing 
  # utilities functions
  #
  SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
  for s in $MF_BIN/mfUtils_[0-9][0-9]_*.sh
  do
    . $s || { echo "Error sourcing the utilities ($s) script" ; exit 1 ; }
  done
  startStep "Initialization"
  #
  #     In this section, position variables to be used in the script,
  #  use the setVar function if you want to have them printed on the screen (they will be added to the log when  
  #  file name will be defined. To avoid creating a new process which will lead to loose
  #  the variables, we need to redirect each echo statement in this part
  # 
  #     The setVar redirects to $TMPFILE
  #
  mf_setCommonVariables                                                    
  [ "$(id -un)" != "$runUser" ] && die "This script must be launched by the  \"$runUser\""
  #
  #       Parameter analysis
  #
  infoAction "Analyze parameters" "$I1"                                    | tee -a $TMPFILE
  #
  #       Anlyze script's parameters (don't forget to updatethe usage fonction
  #
  MF_MIGRATION_ID=""                         # Mandatory to pass as argument
  toShift=0
  #
  # List of steps, with description
  #
  STEP_LIST="\
DO_INIT:Initialize for PDB Copy
DO_COPY:Physical Copy of the database
DO_SYNCH_COPY:Roll forward Copy of the database (ROLLING_PDB_COPY only)
DO_END_COPY:Finish the copy and put the DB in consistent state
DO_SETUP:Prepare PDB for encryption
DO_USERS:Synchronize standard users
DO_OGG:Setup and start Golden Gate replicat
DO_ADD_STEPS:Add steps to the migration attempt
DO_ENCRYPT_BIGFILE:Encrypt BIGFILE tablespaces
DO_MOVE:Move segments to BIGFILE Tablespaces (optional)
DO_ENCRYPT_ALL:Encrypt all remaining tablespaces
DO_SWITCH:Exchange PDBs
DO_CLEANUP:Remove original PDB
DO_DROP:Drop temporary PDB
DO_ROLLING_INFO:Get status and changes for rolling copy
DO_DG_ALL:Reconcile dataguard with new PDB
DO_STATUS:Show status
DO_UNIT_TEST:For development ONLY
DO_UNPLUG_PLUG:Rolling PDB COPY Repair only (use carefully)"
  ALL_STEPS="$(echo "$STEP_LIST" | cut -f1 -d":" | tr '\n' ' ')"
  
  STEPS_TO_RUN="DO_INIT DO_COPY DO_SETUP DO_USERS DO_OGG DO_SWITCH DO_ADD_STEPS"

  COPY_DB_LINK="MF_PDBCOPY"
  FORCE=N
  USE_SAME_KEY=Y  # If 'Y' we use the key of the marketplace provisioned PDB

  
  while getopts :m:S:FfQVnh opt
  do
    case $opt in
     # --------- Script parameters ---------------------------------------------
     S) STEPS_TO_RUN=${OPTARG^^}                      ; toShift=$(($toShift + 2)) ;;
     F) FORCE=Y                                       ; toShift=$(($toShift + 1)) ;;
     f) FINISH_COPY=Y                                 ; toShift=$(($toShift + 1)) ;;
     # --------- Common parameters ---------------------------------------------
     Q) setVar LOG_QUIET                  Y           ; toShift=$(($toShift + 1)) ;;
     V) setVar LOG_QUIET                  N           ; toShift=$(($toShift + 1)) ;;
     m) setVar MF_MIGRATION_ID            ${OPTARG^^} ; toShift=$(($toShift + 2)) ;;
     # --------- Usage ---------------------------------------------------------
     n)   logOutput=NO   ; toShift=$(($toShift + 1)) ;;
     ?|h) usage "Help requested";;
    esac
  done
  shift $toShift 
  #
  #   Control parameters
  #
  [ "$MF_MIGRATION_ID" = "" ] && die "MIGRATION_ID (-m) is mandatory"
  mfSetEnvFile
  [ "$FINISH_COPY" = "Y" -a "$ROLLING_PDB_COPY" = "Y" ] && die "-f (finish copy) is only usable in ROLLING COPY mode"
  setVar MF_RSP_FILE $RSP_FILES/${MF_MIGRATION_ID}.rsp
  infoAction "Set general dependent variables" "$I1"                      | tee -a $TMPFILE
  mfSetLogs
  infoAction "Set script specific variables" "$I1"                        | tee -a $TMPFILE

  for s in ${STEPS_TO_RUN^^}
  do
    [ "$(echo "$s" | grep "^DO_")" = "" ] && die "Step name mus start with DO_ (DO_INIT, ....)"
    [ "$(echo "$ALL_STEPS " | grep "$s ")" = "" ] && die "Unknown step ($s)"
    case $s in
      DO_PRE_INSERT|DO_POST_INSERT) eval $s=Y
                                    v="$(echo "$s" | sed -e "s;DO_;;")_STEPS"
                                    tmp=$(eval echo \$$v)
                                    for v in $tmp
                                    do
                                      eval $v=Y
                                    done
                                    ;;
      *) eval $s=Y ;;
    esac
  done
  endStep                                                                 | tee -a $TMPFILE
} 

# ###################################################################################################
#
#       Real script start, after this point, all output are automatically redirected to $LOG_FILE
#
# ###################################################################################################
  # -------------------------------------------------------------------------------------------------
  #
  #   LOG everything in the LOG_FILE (if defined) without piping to tee, avoid unnecessary child 
  # processes
  #
  # -------------------------------------------------------------------------------------------------
  if [ "$LOG_FILE" != "" -a "$LOG_FILE" != "/dev/null" ]
  then
    MF_LOGGING_FIFO=$(mktemp --suffix .mf.logfifo) # Obtain unique file name
    rm -f $MF_LOGGING_FIFO
    mkfifo $MF_LOGGING_FIFO
    (cat $MF_LOGGING_FIFO | tee $LOG_FILE) &
    exec > $MF_LOGGING_FIFO 2>&1
  fi
  # -------------------------------------------------------------------------------------------------


  startRun "$SCRIPT_LIB"
  #
  #   Insert script init LOG here
  #
  if [ "${LOG_QUIET:-N}" != "Y" ]
  then
    test -f $TMPFILE && cat $TMPFILE
  fi
  rm -f $TMPFILE 

  startStep "Premiminary verifications"
  mfSetGlobalEnv
  mfSetConnectStrings                                        # Build connection strings
  mfTestDatabaseConnections                                  # Tests all the database connections (must be OK to continue)

  endStep 

  if [ "$DATA_TRANSFER_MEDIUM" = "ROLLING_PDB_COPY" -o "$ROLLING_PDB_COPY" = "Y" ]
  then
    
    DATA_TRANSFER_MEDIUM=PDB_COPY
    ROLLING_PDB_COPY="Y"
  fi

  # ------------------------------------------------------------------------------------------------------
  forcedOutput ON

  echo
  infoAction "Steps that will be executed" "$I1"
  libAction "Rolling PDB COPY" "$I2" ; echo $ROLLING_PDB_COPY
  echo
  for g in ALL_STEPS
  do
    v="DO_$(echo "$g" | sed -e "s;_STEPS;;")"
    libAction "$g ($v)" "$I2"
    eval echo \$$v
    tmp=$(eval echo \$$g)
    for s in $tmp
    do
      lib=$(echo "$STEP_LIST" | grep "^$s:" | cut -f2 -d":")
      libAction "$lib ($s)" "$I3"
      eval echo \$$s
    done
  done

  # ------------------------------------------------------------------------------------------------------

  if [ "$databaseHost" = "" ]
  then
    databaseHost=$( mfGetDbSshHost "$MF_TGT_CLUSTER_HOSTS") || die "Unable to find a host accepting ssh"
  fi
  
  if [ "$(echo $TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME | grep "_")" != "" ]
  then
    echo 
    echo "            - ORACLE Naming convention"
    CDB_NAME=$(echo $TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME | sed -e "s;_.*$;;")
    CDB_UNIQUE_NAME=$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME
  elif [[ $TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME =~ ^C.*M[0-9]*$ ]]
  then
    echo 
    echo "            - BNP Naming convention"
    CDB_NAME=$(echo $TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME | sed -e "s;M[0-9]*$;;")
    CDB_UNIQUE_NAME=$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME
  else
    echo 
    echo "            - Direct naming"
    CDB_NAME=$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME
    CDB_UNIQUE_NAME=$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME
  fi
  
  echo
  echo "      CDB_NAME           : $CDB_NAME"
  echo "      CDB_UNIQUE_NAME    : $CDB_UNIQUE_NAME"
  echo

  
  pdbCopyStatus 

  if [ "$FINISH_COPY" = "Y" ]
  then
    if [ "$MF_PDB_COPY_RUN_STATE" = "SWITCHED" ]
    then
      infoAction "Finalization from SWITCHED State" "$I1"
      STEPS_TO_RUN="DO_USERS DO_ADD_STEPS"
    elif [ "$MF_PDB_COPY_RUN_STATE" = "COPY" ]
    then
      infoAction "Finalization from COPY STate" "$I1"
      if [ "$ROLLING_PDB_COPY" = "Y" ]
      then
        infoAction "PDB Copy finalization , PDB creation from standalone (ROLLING_PDB_COPY=$ROLLING_PDB_COPY)" "$I2"
        STEPS_TO_RUN="DO_END_COPY DO_SETUP DO_USERS DO_OGG DO_SWITCH DO_ADD_STEPS"
      else
        infoAction "PDB Copy finalization , normal PDB Copy (ROLLING_PDB_COPY=$ROLLING_PDB_COPY)" "$I2"
        STEPS_TO_RUN="DO_SETUP DO_USERS DO_OGG DO_SWITCH DO_ADD_STEPS"
      fi
    else
      die "Invalid state ($MF_PDB_COPY_RUN_STATE) for FINISH COPY opreration"
    fi
  fi
  
  for s in ${STEPS_TO_RUN^^} 
  do
    #
    #    Run the steps in the order they appear in the list
    #
    eval $s
  done

  pdbCopyStatus

  endRun 0 "$OUT_MESSAGE"
