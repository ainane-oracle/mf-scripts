#
# -----------------------------------------------------------------------------
#
#  Generation marker  : MF_DOC_GENERATED
#  File               : mfDbActions.sh
#
#  Purpose            : Database status and actions.
#
#  Description        : Initializes the Migration Factory environment, validates the selected
#                       context, and executes the operational workflow for this entry point.
#
#  Functions           : 
#                        - detailed_usage
#                        - usage
#
# *****************************************************************************

VERSION=1.8
# ************************************************************************** 
# Modifications :
# =============
# 
# 13/09/2024 MBO - Delivery MF 1.2 @ BNP, change logging mechanism to avoid
#                  sub processes, temporary files cleanup (mktemp with suffixes)
#
# 15/11/2024 MBO - Version 1.2.5, before LOT-0 start,
#
# ************************************************************************** 
SCRIPT_LIB="Migration Factory 2.0 : Database status and actions"
CATEGORY="90-Utilities"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#  Usage
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : detailed_usage
#
#  Description         : Prints the detailed usage information for
#                        mfDbActions.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Prepare local variables and perform the operation described above.
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
#         This script executes several frequent actions on the target database and/or in its standby. 
#       it allows viewing the global status an perming stop/start of instances or database, as well as 
#       switchovers.
#       
#         The action is determined by the -A argument value, wich in some cases requires a sub-action 
#       whih is determined by the -a argument value.
#       
#         The database is determined by the -m argument value which is mandatory.
#         
#         When no action is specified, the default is [-A STATUS].
#     
#     The main functions are :
#     
#     - STATUS ==> -A STATUS
#       --------------------
#       
#         Displays the status of the database and its stand-by (run state, running services ...). STATUS 
#       also tests connections vi TCP and TCPS, with the connect-string used by the migration factory
#       and via the application standard connect string.
#             
#         For production and pre-production, the connectiion to the stand-by is also tested.
#
#     - Dataguard configuration ==> -A DGCONF
#       -------------------------------------
#         
#         Connects to the primary and displays DATAGUARD configuration
#         
#     - Database/instances bounce ==> -A [PRIM_DB|STBY_DB] -a [STATUS_DB|STOP_I1|STOP_I2|START_I1|START_I2|STOP_DB|START_DB]
#       -------------------------------------
#         
#         Displays the detailed status of the database or stop/start an instance or the whole
#       database
#         
#     - Dataguard SWITCHOVER ==> -A [SW] -a [TO_M1|TO_M2]
#       -------------------------------------------------
#       
#         Check dataguard status and, if no error launched a switchover to M1 or M2 If the database
#       is already primary on the required site, nothin is done.
#       
#         If a golden-gate replication is running, then the replication is stopped befor the switchover
#       and a restart try is done after.
#       
#         This does not work every time. A command to check the satus is displayed on the screen.
#          
#   - Specific cases/variants
#     =======================
#     
#         Not applicable
#     
#   - Knonwn Issues/Evolutions needed
#     ===============================
#
#         - Database/Instance stop/start may display incorrect statuses
#         - Restating replication may not work        
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

    Database status and actions.

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

      - Initialization
      - Analyze parameters
      - Set general dependent variables
      - Set script specific variables
      - Premiminary verifications
      - Test (and fix) password issues on target CDB and PDB
      - Switched, testing connection to TEMPORARY PDB
      - Not yet switched, testing connection to TEMPORARY PDB
      - DATAGAUARD Configuration
      - Test if TEMPORARY tablespaces are aligned between PRIMARY and STAND-BY
      - Testing if database is under blackout
      - DATAGAUARD Switchover
      - PRIMARY member runs on
      - Show dataguard configuration and status

  Integration points
  ==================

    The script interacts with or delegates work to:

      - mfRemediation.sh
      - mfEmBlackout.sh
      - mfReplMgmt.sh
      - mfOGGStatus.sh
      - GoldenGate

  Operational notes
  =================

    - Review the selected migration context before running the script, because
      most actions are driven by repository and environment values.
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
# #  Description         : Prints the short usage information for mfDbActions.sh.
# #
# #  Input Parameters    : - None.
# #
# #  Output              : Prints information to stdout or the configured log.
# #
# #  Return Code         : Not explicitly defined.
# #
# #  Algorithm           : 
# #                        - Iterate over the selected objects or command output.
# # -----------------------------------------------------------------------------
# #
#
# usage() 
# {
#  echo "Usage :
#  $(basename $0) -m MIGRATION_ID -A action [-a argument] [-Q|-V] [-n] [-h|-?]
#
#       $SCRIPT_LIB
#       
#       Performs various actions on the target databases involved in a migration ID (currently 
#    only M1 and M2) such as STATUS/STOP/START/DATAGUARD ACTIONS). 
#    
#          -m MIGRATION_ID  : ID of the migration (base name for files)  MANDATORY
#          -A Action        : Type of activity
#               - STATUS              : Show status of the databases (primary and stand-by)
#               - DGCONF              : Show DATAGUARD status if configured
#               - PRIM_DB/STBY_DB     : Acts on PRIMARY or STAND-BY (requires following arguments)
#                      - STOP_DB      : Stop the corresponding database
#                      - START_DB     : Start the corresponding database
#                      - STOP_I[12]   : Stop instance 1 or 2 on the corresponding database
#                      - START_I[12]  : Start instance 1 or 2 on the corresponding database
#                      - START_SERV   : Start instance 1 or 2 on the corresponding database
#                      - STOP_SERV    : Start instance 1 or 2 on the corresponding database
#                      - FIX_TCPS     : Fix TCPS folder after PDBCOPY
#                      - FIX_PASS     : Fix password issues on target
#               - SW                  : DATAGUARD Switchover (requires following arguments)
#                      - TO_M[12]     : Make M1 or M2 database primary (no actin if already PRIMARY
#          -Q               : Quiet mode (remove progress output)
#          -V               : Print all loging information
#          -?|-h            : Help
#
#   Version : $VERSION
#   "
#   [ "$MF_DETAILED_USAGE" = "Y" ] && detailed_usage
#   exit
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
  Database status and actions.

Required:
  -m MIGRATION_ID        : ID of the migration (base name for files).

Options:
  -A Action              : Type of activity - STATUS : Show status of the databases.
                             (primary and stand-by) - DGCONF : Show DATAGUARD status if.
                             configured - PRIM_DB/STBY_DB : Acts on PRIMARY or STAND-BY.
                             (requires following arguments) - STOP_DB : Stop the.
                             corresponding database - START_DB : Start the corresponding.
                             database - STOP_I[12] : Stop instance 1 or 2 on the.
                             corresponding database - START_I[12] : Start instance 1 or 2.
                             on the corresponding database - START_SERV : Start instance 1.
                             or 2 on the corresponding database - STOP_SERV : Start.
                             instance 1 or 2 on the corresponding database - FIX_TCPS : Fix.
                             TCPS folder after PDBCOPY - FIX_PASS : Fix password issues on.
                             target - SW : DATAGUARD Switchover (requires following.
                             arguments) - TO_M[12] : Make M1 or M2 database primary (no.
                             actin if already PRIMARY.
  -a ACTION              : Action or attempt value.
  -Q                     : Quiet mode (remove progress output).
  -V                     : Print all logging information.
  -n                     : Disable log output.
  -h, -?                 : Show this help and exit.
  --help                 : Show this help plus the detailed usage section and exit.

Examples:
  $(basename "$0") -m MIGRATION_ID
$(basename "$0") -m MIGRATION_ID -A Action

Notes:
  Use --help to display the detailed usage section when available.

Version:
  $VERSION
EOF
  [ "$MF_DETAILED_USAGE" = "Y" ] && detailed_usage
  exit
}



_____________________________scriptSpecificFunctions() { : ; }

# ******************************************************************************
# ******************************************************************************
# ******************************************************************************
# ******************************************************************************

# _____________________________mainx { : ; }
[ "$(echo "$*" | grep -- "-Q")" != "" ] && LOG_QUIET=Y
[ "$(echo "$*" | grep -- "-V")" != "" ] && LOG_QUIET=N
[ "$(echo "$*" | grep -- "--help")" != "" ] && { MF_DETAILED_USAGE=Y ; usage ; exit 1 ; }
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
  ACTION="STATUS"
  ACTION_ARG=""
  while getopts :m:A:a:QVnh opt
  do
    case $opt in
     # --------- Script parameters ---------------------------------------------
     A) ACTION=${OPTARG^^}                            ; toShift=$(($toShift + 2)) ;;
     a) ACTION_ARG=${OPTARG^^}                        ; toShift=$(($toShift + 2)) ;;
     # --------- Common parameters ---------------------------------------------
     Q) setVar LOG_QUIET                  Y           ; toShift=$(($toShift + 1)) ;;
     V) setVar LOG_QUIET                  N           ; toShift=$(($toShift + 1)) ;;
     m) setVar MF_MIGRATION_ID            ${OPTARG^^} ; toShift=$(($toShift + 2)) ;;
     # --------- Usage ---------------------------------------------------------
     n)   logOutput=NO   ; toShift=$(($toShift + 1)) ;;
     ?|h) usage "Help requested";;
    esac
  done
  logOutput=NO
  shift $toShift 
  #
  #   Control parameters
  #
  [ "$MF_MIGRATION_ID" = "" ] && die "MIGRATION_ID (-m) is mandatory"
mfSetEnvFile
  
  case $ACTION in
  STATUS)
     :
     ;;
  DGCONF)
     :
     ;;
  PRIM_DB|STBY_DB)
    case $ACTION_ARG in
      STATUS|STOP_DB|START_DB|STOP_I1|STOP_I2|START_I1|START_I2|START_SERV|STOP_SERV|FIX_TCPS|FIX_PASS) ;;
       *) die "For $ACTION, please specify argument STATUS, STOP_DB, START_DB, STOP_I1, STOP_I2,FIX_TCPS,FIX_PASS instead of ($ACTION_ARG)"
          ;;
    esac
    ;;
  SW)
    case $ACTION_ARG in
      TO_M1|TO_M2) ;;
       *) die "For $ACTION, please specify argument TO_M1 or TO_M2"
          ;;
    esac
    ;;
  *) die "unknown action $ACTION (Possible choices : STATUS, DGCONF, PRIM_DB, STBY_DB, SW)" 
     ;;
  esac
  infoAction "Set general dependent variables" "$I1"                      | tee -a $TMPFILE
  mfSetLogs
  infoAction "Set script specific variables" "$I1"                        | tee -a $TMPFILE
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


  startRun "$SCRIPT_LIB" >/dev/null
  #
  #   Insert script init LOG here
  #
  if [ "${LOG_QUIET:-N}" != "Y" ]
  then
    test -f $TMPFILE && cat $TMPFILE
  fi
  rm -f $TMPFILE

  startStep "Premiminary verifications"
  mfSetGlobalEnv >/dev/null
  mfSetConnectStrings                                        # Build connection strings
  mfTestDatabaseConnections TGT                              # Tests all the database connections (must be OK to continue)
  endStep 
  # ------------------------------------------------------------------------------------------------------
  forcedOutput ON
  # fixPasswordIssues
  startStep "Peforming $ACTION ($ACTION_ARG) on $TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME"

  case $ACTION in
  STATUS)
     mfDebugLog "Database status"
     mfDatabasesInfos CONNECT
     if [ "$standByClusterInfo" != "" ]
     then
       exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" ". $CDB_NAME.env || exit 1 ; dgmgrl / \"show configuration lag\"" "Dataguard status" "$I3"
     fi
     ;;
  PRIM_DB|STBY_DB)
     mfDebugLog "Database action : $ACTION_ARG"
    if [ "$ACTION_ARG" != "START_DB" ]
    then      
      [ "$ACTION_ARG" != "FIX_PASS" ] && mfDatabasesInfos || mfDatabasesInfos -no_die 
    fi
    if [ "$ACTION" = "PRIM_DB" ]
    then
      [ "$ACTION_ARG" != "START_DB" ] &&  databaseHost=$primSSH || { $(mfGetDbSshHost "$MF_TGT_CLUSTER_HOSTS") ; CDB_NAME=$(echo "$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME" | sed -e "s;M[0-9]$;;") ; }
      scan=$primaryScanAddress
      port=$primaryPort
      service=$primaryDbUniqueName
      role="PRIMARY"
    else
      databaseHost=$stbySSH
      scan=$standByScanAddress
      port=$standByPort
      service=$standByDbUniqueName
      role="PHYSICAL STANDBY"
    fi
    if [ "$ACTION_ARG" != "FIX_PASS" ]
    then
      tns="//$scan:$port/$service"
      infoAction "Primary database on $primSSH" "$I2"
      infoAction "$tns" "$B2"
      infoAction "=======================================================================" "$B2"
      echo
      libAction "Verify that the role is $role" "$I2"
      effectiveRole="$(exec_sql "$MF_TGT_CDB_USER/\"$MF_TGT_CDB_PASSWORD\"@\"$tns\"" "select database_role from v\$database ;")"
      if [ $? -ne 0 ]
      then
        [ "$ACTION_ARG" != "START_DB" ] && die "Unable to get role \n $effectiveRole"
      fi
      if [ "$effectiveRole" = "$role" ]
      then
        echo "OK"
      else
        [ "$ACTION_ARG" != "START_DB" ] && echo "Incorrect role" || echo "Start Request"
        [ "$ACTION_ARG" != "START_DB" ] && die "The role ($effectiveRole) of the database is not the expected one ($role)"
      fi        
      echo
    fi
    case $ACTION_ARG in
      STOP_DB)
        mfStopDatabase "$databaseHost" "$CDB_NAME" || die "The database is not properly stopped"
        mfStatusDatabase "$databaseHost" "$CDB_NAME" "$I2"
        ;;
      STOP_I1|STOP_I2)
        mfStopInstance "$databaseHost" "$CDB_NAME" "$(echo "$ACTION_ARG" | sed -e "s;STOP_I;;")" || die "The instance is not properly stopped"
        mfStatusDatabase "$databaseHost" "$CDB_NAME" "$I2"
        ;;
      START_I1|START_I2)
        mfStartInstance "$databaseHost" "$CDB_NAME" "$(echo "$ACTION_ARG" | sed -e "s;START_I;;")" || die "The instance is not properly started"
        mfStatusDatabase "$databaseHost" "$CDB_NAME" "$I2"
        ;;
      START_SERV)
        exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" ". $CDB_NAME.env || exit 1 ; srvctl start service -d \$ORACLE_UNQNAME" "Starting services" "$I1"
        mfStatusDatabase "$databaseHost" "$CDB_NAME" "$I2"
        ;;
      STOP_SERV)
        exec_on_target "${MF_SUDOER:-opc}@$databaseHost" "oracle" ". $CDB_NAME.env || exit 1 ; srvctl stop service -d \$ORACLE_UNQNAME" "Starting services" "$I1"
        mfStatusDatabase "$databaseHost" "$CDB_NAME" "$I2"
        ;;
      START_DB)
        mfStartDatabase "$databaseHost" "$CDB_NAME" || die "The database is not properly started"
        mfStatusDatabase "$databaseHost" "$CDB_NAME" "$I2"
        ;;
      STATUS_DB)
        mfStatusDatabase "$databaseHost" "$CDB_NAME" "$I2"
        ;;
      FIX_TCPS)
        [ "$DATA_TRANSFER_MEDIUM" != "PDB_COPY" -a "$DATA_TRANSFER_MEDIUM" != "ROLLING_PDB_COPY" ] && die "Cannot fix TCPS if DATA_TRANSFER_MEDIUM=$DATA_TRANSFER_MEDIUM, contact orchestrator team." 
        pdbCopyStatus
        exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$(cat <<%%
        . $CDB_NAME.env || exit 1
        [ "$MF_PDB_COPY_RUN_STATE" = "COPY" ]  && mkp_pdb="$MF_TGT_DBNAME" || mkp_pdb=\$(echo "$MF_TGT_DBNAME" | sed -e "s;^.;O;")
        [ "$MF_PDB_COPY_RUN_STATE" != "COPY" ] && new_pdb="$MF_TGT_DBNAME" || new_pdb=\$(echo "$MF_TGT_DBNAME" | sed -e "s;^.;Z;")
        mkp_guid=\$(sqlplus -s / as sysdba << _SQL_ | tr -d '\n'
           set head off feed off
           select guid from v\\\\\$pdbs where name='\$mkp_pdb' ;
_SQL_
                  )
        echo                  
        echo "Original PDB=\$mkp_pdb/\$mkp_guid"
        new_guid=\$(sqlplus -s / as sysdba << _SQL_ | tr -d '\n'
           set head off feed off
           select guid from v\\\\\$pdbs where name='\$new_pdb' ;
_SQL_
                  )        
        echo "    PDB=\$new_pdb/\$new_guid"
        [ "\$new_guid" = "" ] && exit 1
        [ "\$new_guid" = "" ] && exit 1
        mkp_folder=/acfs01/dbaas_acfs/$CDB_NAME/wallet_root/\$mkp_guid/tls
        new_folder=/acfs01/dbaas_acfs/$CDB_NAME/wallet_root/\$new_guid/tls
        [ ! -d "\$mkp_folder" ] && { echo "ERROR : No TCPS Folder for \$mkp_pdb DB (\$mkp_folder)" ; exit 1 ; }
        [   -d "\$new_folder" ] && { echo "ERROR : TCPS Folder for \$new_pdb exists (\$new_folder)" ; exit 1 ; }
        mkdir -p  /acfs01/dbaas_acfs/\$new_guid/wallet_root/
        echo "Copy tls folder from \$mkp_pdb to \$new_pdb"
        cp -rp /acfs01/dbaas_acfs/$CDB_NAME/wallet_root/\$mkp_guid/tls /acfs01/dbaas_acfs/$CDB_NAME/wallet_root/\$new_guid 
        exit 0
%%
)
                       " "Fixing TCPS wallet issues for PDB COPY migrations (MF_PDB_COPY_RUN_STATE=$MF_PDB_COPY_RUN_STATE"        
         ;;
      FIX_PASS)
        repairPasswords
        ;;
      *) die "Unknown argument for DATABASE ($ACTION_ARGS), valid values are : STATUS_DB, STOP_DB, STOP_I1 ,STOP_I1, START_DB, START_I1 ,START_I2"
        ;;
    esac
    ;;
  DGCONF)
     mfDebugLog "Dataguard configuration"
    mfDatabasesInfos CLUSTERS
    databaseHost=$primSSH
    scan=$primaryScanAddress
    port=$primaryPort
    service=$primaryDbUniqueName
    role="PRIMARY"
    tns="//$scan:$port/$service"
    infoAction "Primary database on $primSSH" "$I2"
    infoAction "$tns" "$B2"
    infoAction "=======================================================================" "$B2"
    echo
    libAction "Verify that the role is $role" "$I2"
    effectiveRole="$(exec_sql "$MF_TGT_CDB_USER/\"$MF_TGT_CDB_PASSWORD\"@\"$tns\"" "select database_role from v\$database ;")"|| die "Unable to get role \n $effectiveRole"
    if [ "$effectiveRole" = "$role" ]
    then
      echo "OK"
    else
      echo "Incorrect role" || echo "Start Request"
      die "The role ($effectiveRole) of the database is not the expected one ($role)"
    fi        
    echo
    infoAction "DATAGAUARD Configuration " "$I1"
    mfDGConfiguration "$databaseHost" "$CDB_NAME" "/" || die "DATAGUARD Configuration is in ERROR"
    ;;
  SW)
     mfDebugLog "Switchover"
    ENV_FILE=$ENV_FILES/$MF_MIGRATION_ID.env
    [ ! -f $ENV_FILE ] && die "Unable to find $ENV_FILE.env"
    CDB_NAME=$(echo "$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME" | sed -e "s;M[0-9]$;;")
    # libAction "Test if TEMPORARY tablespaces are aligned between PRIMARY and STAND-BY" "$I1"
    # tmp=$(exec_sql "$MF_REPO_CONNECT" "
                                          # select 
                                             # to_char(last_checked,'dd/mm/yyyy hh24:mi:ss') || ';' ||
                                            # case
                                               # when last_fix_result is null then LAST_CHECK_RESULT
                                               # else LAST_FIX_RESULT
                                             # END
                                          # from 
                                            # REMEDIATION_ACTIONS 
                                          # where 
                                                # name='TBS_TEMP_FILE'
                                            # and mig_id=$MFAUTO_MIG_ID
                                          # order by last_checked desc
                                          # fetch first 1 rows only;
                                         # ") || die "$tmp"
    # if [ "$tmp" = "" ]
    # then
      # temp_date="Never run"
      # temp_ok=FAILURE
    # else
      # temp_date=$(echo "$tmp" | cut -f1 -d";")
      # temp_ok=$(echo "$tmp" | cut -f2 -d";")
    # fi
    # echo "$temp_ok ($temp_date)"

    # if [ "$temp_ok" = "FAILURE" ]
    # then
      # die "Temporary tablespaces are not aligned between PRIMARY and stand-by, please run :
      
      # $MF_BIN/mfRemediation.sh -m $MF_MIGRATION_ID -S TBS_TEMP_FILE -x
      
   # and retry the operation."
    # fi

    libAction "Testing if database is under blackout" "$I1"
    if ! $MF_BIN/mfEmBlackout.sh -m $MF_MIGRATION_ID -A IS_ON -n </dev/null >/dev/null 2>&1
    then
      echo "No Blackout"
      libAction "Start Blackout until planned go-live + 12 hours (12-hour fallback)" "$I2"
      if $MF_BIN/mfEmBlackout.sh -m $MF_MIGRATION_ID -A START -n </dev/null >/dev/null 2>&1
      then
        echo Ok
      else
        echo Error
        die "Unable to create blackout"
      fi
      # $MF_BIN/mfEmBlackout.sh -m $MF_MIGRATION_ID -A IS_ON -n </dev/null >/dev/null 2>&1 || die "Blackout not active (error creating it)"
    else
      echo "Active blackout"
    fi
    mfDatabasesInfos
    databaseHost=$primSSH
    scan=$primaryScanAddress
    port=$primaryPort
    service=$primaryDbUniqueName
    role="PRIMARY"
    tns="//$scan:$port/$service"
    infoAction "Primary database on $primSSH" "$I2"
    infoAction "$tns" "$B2"
    infoAction "=======================================================================" "$B2"
    under_synch=$(exec_sql "$MF_REPO_CONNECT" "select under_synch from migration_attempts where mig_id=$MFAUTO_MIG_ID;")
    if [ "$under_synch" != "NO" ]
    then
      case $under_synch in
        SRC-TGT) synch_lib="SOURCE --> TARGET" ; if tty -s ; then synch_lib="${blue_bg}${synch_lib}${color_end}" ; fi ;; 
        TGT_SRC) synch_lib="SOURCE <-- TARGET" ; if tty -s ; then synch_lib="${red_bg}${synch_lib}${color_end}" ; fi ;; 
      esac
    fi
    if [ "$under_synch" = "SRC-TGT" -o "$under_synch" = "TGT_SRC" ]
    then
      echo "
           ATTENTION : $synch_lib replication is in place, will be restarted at the end
           "
    fi
    echo
    libAction "Verify that the role is $role" "$I2"
    effectiveRole="$(exec_sql "$MF_TGT_CDB_USER/\"$MF_TGT_CDB_PASSWORD\"@\"$tns\"" "select database_role from v\$database ;")"|| die "Unable to get role \n $effectiveRole"
    if [ "$effectiveRole" = "$role" ]
    then
      echo "OK"
    else
      echo "Incorrect role" || echo "Start Request"
      die "The role ($effectiveRole) of the database is not the expected one ($role)"
    fi        
    echo
    infoAction "DATAGAUARD Switchover " "$I1" 
    # mfDbIs_PRIMARY || die "Database role is not primary, please check"
    
    libAction "PRIMARY member runs on" "$I2"
    # current_member=$(exec_sql "$MF_TGT_CDB_CONNECT" "select regexp_replace(db_unique_name,'^.*(M[123]$)','\1') from v\$database;")
    current_member=$(exec_sql "$MF_TGT_CDB_CONNECT" "select regexp_replace(db_unique_name,'^.*(M[123]$)','\1') from v\$dataguard_config where dest_role='PRIMARY DATABASE';")
    echo "$current_member"
    case $ACTION_ARG in
      TO_M1) [ "$current_member" = "M1" ] && die "$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME is already PRIMARY on M1" ;;
      TO_M2) [ "$current_member" = "M2" ] && die "$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME is already PRIMARY on M2" ;;
      TO_M3) [ "$current_member" = "M3" ] && die "$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME is already PRIMARY on M3" ;;
    esac
    infoAction "Get DATABASE password for $CDB_NAME (via $databaseHost)" "$I2"
    SYS_PASS=$(mfGetDBPassword $databaseHost $CDB_NAME) || die "Unable to get the password\n$SYS_PASS"
    DG_CONNECT="sys/\"$SYS_PASS\"@$MF_TGT_CDB_TNS as sysdba"
    exec_sql "$DG_CONNECT" "select 'X' from dual;" "Tesing connection with password" "$I3"
    echo
    infoAction "Show dataguard configuration and status" "$I1"
    mfDGConfiguration "$databaseHost" "$CDB_NAME" "/" || die "Error in DATAGUARD Configuration (before switchover)"
    echo
    mfDGValidateDB "$databaseHost" "$CDB_NAME" "/" "M1" || die "Error validation DG for ${CDB_NAME}M1"
    echo
    mfDGValidateDB "$databaseHost" "$CDB_NAME" "/" "M2" || die "Error validation DG for ${CDB_NAME}M2"
    target="$(echo "$ACTION_ARG" | cut -f2 -d"_")" 
    MF_TGT_CLUSTER_HOSTS_NEW=$(echo "$standByClusterInfo" | cut -f6 -d";")
    TARGETDATABASE_CONNECTIONDETAILS_HOST_NEW=$(echo "$standByClusterInfo" | cut -f4 -d";")
    TARGETCONTAINERDATABASE_CONNECTIONDETAILS_HOST_NEW=$(echo "$standByClusterInfo" | cut -f4 -d";")
    TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME_NEW=${CDB_NAME}$target
    infoAction "Values to replace in the environment file" "$I3"
    infoAction "MF_TGT_CLUSTER_HOSTS                                  = $MF_TGT_CLUSTER_HOSTS_NEW"                                  "$I4"
    infoAction "TARGETDATABASE_CONNECTIONDETAILS_HOST                 = $TARGETDATABASE_CONNECTIONDETAILS_HOST_NEW"                 "$I4"
    infoAction "TARGETCONTAINERDATABASE_CONNECTIONDETAILS_HOST        = $TARGETCONTAINERDATABASE_CONNECTIONDETAILS_HOST_NEW"        "$I4"
    infoAction "TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME = $TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME_NEW" "$I4"
    echo
    echo ===============================================================================================================
    echo
    mfDGSwitchover "$databaseHost" "$CDB_NAME" "$DG_CONNECT" "$target" || die "Error switching DG to ${CDB_NAME}$target"
    if [ $? -eq 0 ]
    then
      infoAction "Updating environment file" "$I2"
      cp $ENV_FILE $ENV_FILE.tmp
      sed -i "s; *export *MF_TGT_CLUSTER_HOSTS *=.*$;export MF_TGT_CLUSTER_HOSTS=\"$MF_TGT_CLUSTER_HOSTS_NEW\";" $ENV_FILE.tmp || die "Unable to update $ENV_FILE (1)"
      sed -i "s; *export *TARGETDATABASE_CONNECTIONDETAILS_HOST *=.*$;export TARGETDATABASE_CONNECTIONDETAILS_HOST=\"$TARGETDATABASE_CONNECTIONDETAILS_HOST_NEW\";"  $ENV_FILE.tmp || die "Unable to update $ENV_FILE (2)"
      sed -i "s; *export *TARGETCONTAINERDATABASE_CONNECTIONDETAILS_HOST *=.*$;export TARGETCONTAINERDATABASE_CONNECTIONDETAILS_HOST=\"$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_HOST_NEW\";"  $ENV_FILE.tmp || die "Unable to update $ENV_FILE (3)"
      sed -i "s; *export *TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME *=.*$;export TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME=\"$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME_NEW\";"  $ENV_FILE.tmp || die "Unable to update $ENV_FILE (4)"
      cp $ENV_FILE.tmp $ENV_FILE
    fi
    echo
    echo ===============================================================================================================
    echo
    mfDGConfiguration "$databaseHost" "$CDB_NAME" "/"
    if [ $? -ne 0 ]
    then
      echo 
      echo "Configuration is not yet stable, waiting (at most 3 minutes)"
      echo
      i=1
      OK=N
      while [ $i -lt 6 ]
      do
        # infoAction "Wait 30 sec" "$I2"
        sleep 30
        libAction "Testing DG configuration try #$i" "$I3"
        mfDGConfiguration "$databaseHost" "$CDB_NAME" "/" >/dev/null
        if [ $? -eq 0 ]
        then
          echo "OK"
          OK=Y
          i=10
        else
          echo "Not Stable"
        fi
        i=$(($i + 1))
      done
      mfDGConfiguration "$databaseHost" "$CDB_NAME" "/"
      
      [ "$OK" = "N" ] && die "Dataguard configuration still not stable, please check\n     OGG status at start was: $synch_lib"

    fi

    #
    #   Restart services on primary (just in case)
    #
    primaryHost=$(mfGetDbSshHost "$MF_TGT_CLUSTER_HOSTS_NEW") || die "Unable to find a host accepting ssh on primary"
    remoteCommand=$(cat <<%%
. ${CDB_NAME}.env || exit 1
timeout 30 srvctl start service -d \$ORACLE_UNQNAME
exit 0
%%
)
    exec_on_target -verbose "${MF_SUDOER:-opc}@$primaryHost" "oracle" "$remoteCommand" "Restarting services on primary in case they are not started" "$I2"


    
    if [ "$under_synch" != "NO" ]
    then
      echo
      sleep 5
      exec_sql "$MF_TGT_CDB_CONNECT" "alter system set enable_goldengate_replication=true scope=both sid='*';" "Enable golden-gate (in case)" "$I2"
      exec_sql "$MF_TGT_CDB_CONNECT" "alter system reset \"_remote_awr_enabled\" scope=both sid='*';" "Reset _remote_awr_enabled" "$I2"
      libAction "Restarting $synch_lib replication" "$I2"
      {
        case $under_synch in
          SRC-TGT) $MF_BIN/mfReplMgmt.sh -m $MF_MIGRATION_ID -A START -D FWD -n ; status=$? ;; 
          TGT_SRC) $MF_BIN/mfReplMgmt.sh -m $MF_MIGRATION_ID -A START -D BACK -n ; status=$? ;; 
        esac
      } > $TMPFILE1 2>&1 && { echo ok ; rm -f $TMPFILE1 ; } || { echo Error ; cat $TMPFILE1 ; rm -f $TMPFILE1 ; } 
      echo
      infoAction "Check in a few minutes with" "$I2"
      infoAction "$MF_BIN/mfOGGStatus.sh -m $MF_MIGRATION_ID -n" "$B2"
      infoAction "If not started, use" "$I3"
        case $under_synch in
          SRC-TGT) infoAction "\$MF_BIN/mfReplMgmt.sh -m $MF_MIGRATION_ID -A START -D FWD" "$B3"  ;;
          TGT_SRC) infoAction "\$MF_BIN/mfReplMgmt.sh -m $MF_MIGRATION_ID -A START -D BACK" "$B3" ;; 
        esac
    fi
    
    ;;
  *) die "unknown action $ACTION (Possible choices : STATUS, DGCONF, PRIM_DB, STBY_DB, SW)" 
     ;;
     
  esac
  endStep

  # ------------------------------------------------------------------------------------------------------

  endRun
