#
# -----------------------------------------------------------------------------
#
#  Generation marker  : MF_DOC_GENERATED
#  File               : mfEmBlackout.sh
#
#  Purpose            : Manage EM blackouts for a target database.
#
#  Description        : Initializes the Migration Factory environment, validates the selected
#                       context, and executes the operational workflow for this entry point.
#
#  Functions           : 
#                        - detailed_usage
#                        - usage
#
# *****************************************************************************

VERSION=1.11
# ************************************************************************** 
# Modifications :
# =============
# 
# 13/09/2024 MBO - Delivery MF 1.2 @ BNP, change logging mechanism to avoid
#                  sub processes, temporary files cleanup (mktemp with suffixes)
#
# 15/11/2024 MBO - Version 1.2.5, before LOT-0 start,
# 06/08/2026     - Version 1.9, create START blackouts centrally through the
#                  OEM REST API and preserve the legacy non-START actions.
# 06/08/2026     - Version 1.10, set REST timeToEnd to the current planned
#                  go-live time plus twelve hours.
# 06/08/2026     - Version 1.11, use a twelve-hour duration when no current
#                  planned go-live exists and default to STATUS.
#
# ************************************************************************** 
SCRIPT_LIB="Migration Factory 2.0 : Manage EM blackouts for a target database"
CATEGORY="40-Migration Helpers"
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
#                        mfEmBlackout.sh.
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
#         This script manages the blackout fo a target database, currently it use the
#       EM Cli interface, but can be adapted to any management tool.
#     
#     The main functions are :
#     
#     - Show blackout
#       --------------
#       
#         Shows the blackout status for this database on all servers hosting the DB and its 
#       stand-bys if a stand-by exists.
#          
#     - Start blackout
#       --------------
#       
#         Starts a blackout this database on all servers hosting the DB and its 
#       stand-bys if a stand-by exists.
#       
#         If -d argument is provided, it contains the blackout duration [D [HH:MI]], otherwise
#       the default duration is twelve hours.
#       
#     - Remove blackout
#       --------------
#       
#         Removes the blackout for this database on all servers hosting the DB and its 
#       stand-bys if a stand-by exists.
#          
#     - Test blackout
#       --------------
#       
#         Test the blackout status for this database on all servers hosting the DB and its 
#       stand-bys if a stand-by exists.
#       
#       Retruns 0 if blackout is set, 1 otherwise
#       
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

    Manage EM blackouts for a target database.

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
# #  Description         : Prints the short usage information for mfEmBlackout.sh.
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
#  $(basename $0) -m MIGRATION_ID [-A action] [-Q|-V] [-n] [-h|-?]
#
#       $SCRIPT_LIB
#          
#          This script creates, deletes or checs a monitoring blackout on a target database for e given
#       migration attempt. It connects on all the target nodes hosting a target database or its stand-by 
#       and performs the blackout action on the targets containing the name of the CDB.
#       
#          -m MIGRATION_ID  : ID of the migration (base name for files)  MANDATORY
#          -A action        : Operation to execute [DEFAULT: STATUS]
#                             - START  : Creates the blackout (by default, the blackout expires after 12 hours)
#                                       (monitoring alerts are not raised)
#                             - STOP   : Removes the blackout (monitoring alerts will resume)
#                             - STATUS : Show the status of the blackout
#                             - IS_ON  : returns 0 if Blackout is ON
#          -d duration      : DUration of the blackou, format [D] HH:MI [DEFAULT 12h]
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
  Manage EM blackouts for a target database.

Required:
  -m MIGRATION_ID        : ID of the migration (base name for files).

Options:
  -A action              : Operation to execute [DEFAULT: STATUS] - START : Creates the.
                             blackout until planned go-live plus 12 hours, or.
                             for 12 hours when no current go-live is planned.
                             (monitoring alerts are not raised) - STOP : Removes the.
                             blackout (monitoring alerts will resume) - STATUS : Show the.
                             status of the blackout - IS_ON : returns 0 if Blackout is ON.
  -d duration            : Deprecated compatibility option; ignored by START.
  -Q                     : Quiet mode (remove progress output).
  -V                     : Print all logging information.
  -n                     : Disable log output.
  -h, -?                 : Show this help and exit.
  --help                 : Show this help plus the detailed usage section and exit.

Examples:
  $(basename "$0") -m MIGRATION_ID
$(basename "$0") -m MIGRATION_ID -A action

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


_____________________________main() { : ; }
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
  . "$SCRIPT_DIR/mfEmBlackout_oemRest.sh" \
    || { echo "Error sourcing the OEM REST utility script" ; exit 1 ; }
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
  ACTION=STATUS
  DURATION="12:00"
  DURATION_EXPLICIT=N
  toShift=0
  while getopts :m:A:d:QVnh opt
  do
    case $opt in
     # --------- Script parameters ---------------------------------------------
     A) ACTION=${OPTARG^^}                            ; toShift=$(($toShift + 2)) ;;
     d) DURATION=${OPTARG^^} ; DURATION_EXPLICIT=Y   ; toShift=$(($toShift + 2)) ;;
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
  logOutput=NO
  #
  #   Control parameters
  #
  case $ACTION in
    START|STOP|STATUS|IS_ON) : ;;
    *) die "Action (-A) must be one of IS_ON,START,STOP or STATUS" ;;
  esac
  [ "$MF_MIGRATION_ID" = "" ] && die "MIGRATION_ID (-m) is mandatory"
  mfSetEnvFile
  [ "$MF_RUN_MIGRATION" = "N" ] && setVar MF_EVAL_FLAG "-eval"
  setVar MF_RSP_FILE $RSP_FILES/${MF_MIGRATION_ID}.rsp
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
  # mfSetConnectStrings                                        # Build connection strings
  # mfTestDatabaseConnections                                  # Tests all the database connections (must be OK to continue)

  endStep 

  # ------------------------------------------------------------------------------------------------------
  forcedOutput ON

  #
  #    Prepare variables to access the target machine
  #
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

  EMCTL=/u02/app/oracle/oem/agent/agent_inst/bin/emctl

  startStep "$ACTION a blackout for a database ($CDB_NAME)"

  ERR=0
  
  if [ "$ACTION" = "START" ]
  then
    # TARGET_CLUSTERS identifies peer clusters, but not the peer database's OEM
    # target name. Count peers in both relationship directions and require exact
    # names through MF_OEM_REQUIRED_CDB_NAMES whenever a peer exists.
    PEER_COUNT=$(exec_sql "$MF_REPO_CONNECT" "
                                      with attempt_cluster as
                                      (
                                        select prj_name, tclu_id
                                        from migration_attempts
                                        where mig_id = $MFAUTO_MIG_ID
                                      ), peers as
                                      (
                                        select tc.peer_tclu_id peer_tclu_id
                                        from target_clusters tc
                                        join attempt_cluster ac
                                          on ac.prj_name = tc.prj_name
                                         and ac.tclu_id = tc.tclu_id
                                        where tc.peer_tclu_id is not null
                                        union
                                        select tc.tclu_id peer_tclu_id
                                        from target_clusters tc
                                        join attempt_cluster ac
                                          on ac.prj_name = tc.prj_name
                                         and tc.peer_tclu_id = ac.tclu_id
                                      )
                                      select to_char(count(distinct peer_tclu_id))
                                      from peers;")
    PEER_COUNT=$(echo "${PEER_COUNT:-0}" | tr -d '[:space:]')
    [[ "$PEER_COUNT" =~ ^[0-9]+$ ]] || die "Unable to determine target peer topology"

    [ "$DURATION_EXPLICIT" = "N" ] \
      || infoAction "Ignoring deprecated -d; blackout end is planned go-live + 12 hours" "$I1"

    if ! TIME_TO_END=$(exec_sql "$MF_REPO_CONNECT" "
                                      select to_char(
                                               sys_extract_utc(
                                                 from_tz(cast(po.target_date as timestamp), sessiontimezone)
                                               ) + interval '12' hour,
                                               'YYYY-MM-DD\"T\"HH24:MI\"Z\"'
                                             )
                                      from migration_planned_operations po
                                      where po.mig_id = $MFAUTO_MIG_ID
                                        and po.mls_id = mf_mig_parameters.get_id('MLS_ID_GOLIVE_START', po.prj_name)
                                        and po.current_plan = 'Y';")
    then
      die "Unable to query the current planned go-live time"
    fi
    TIME_TO_END=$(printf '%s\n' "$TIME_TO_END" \
      | sed -e '/^[[:space:]]*$/d' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    if [ -z "$TIME_TO_END" ]
    then
      infoAction "No current planned go-live; using a 12-hour OEM blackout duration" "$I1"
    else
      mf_oem_validate_time_to_end "$TIME_TO_END" \
        || die "Unable to determine one valid current planned go-live time for timeToEnd"
      infoAction "OEM blackout timeToEnd (planned go-live + 12 hours): $TIME_TO_END" "$I1"
    fi

    trap mf_oem_cleanup EXIT
    PRIMARY_OEM_CDB_NAME=${MF_OEM_PRIMARY_CDB_NAME:-$CDB_NAME}
    mf_oem_start_blackout "$MF_MIGRATION_ID" "$PRIMARY_OEM_CDB_NAME" "$PEER_COUNT" "$TIME_TO_END" \
      || die "Unable to create and verify the centralized OEM REST blackout"
    mf_oem_cleanup
    trap - EXIT
  else
    # Compatibility path: STATUS, IS_ON, and STOP intentionally retain their
    # existing local-agent emctl behavior and blackout naming.
    for node in $(exec_sql "$MF_REPO_CONNECT" "
                                                SELECT
                                                  tn.fqdn  
                                                FROM
                                                  target_clusters tc
                                                  join target_nodes tn on (tn.tclu_id = tc.tclu_id)
                                                WHERE
                                                     (tc.prj_name,tc.tclu_id) = (select prj_name,tclu_id 
                                                                                from migration_attempts 
                                                                                where mig_id = $MFAUTO_MIG_ID)
                                                  or (tc.prj_name,tc.tclu_id) = (select prj_name,peer_tclu_id 
                                                                                from target_clusters 
                                                                                where tclu_id = (select tclu_id 
                                                                                                 from   MIGRATION_ATTEMPTS
                                                                                                 where  mig_id = $MFAUTO_MIG_ID
                                                                                                )
                                                                  ) ;
                                          ")
  do
    infoAction "Node : $node" "$I1"
    infoAction "------------------------------------------------" "$B1"
    echo
    
    case $ACTION in
      STATUS) exec_on_target -verbose "${MF_SUDOER:-opc}@$node" "oracle" "$EMCTL status blackout | awk 'BEGIN {pr=0} /${CDB_NAME}_Migration/ {pr=1 ; printf(\"* * * * * * * * * * * * * * * * * * %s * * * * * * * * * * * * * * * * * *\n\",\$0) ; next} /Expired/ {if (pr==1) {print} ; pr=0 ; next } {if (pr==1) print}'" \
                                     "Status of Migration Factory blackout for $CDB_NAME" "$I2"      
             ;;
      STOP) exec_on_target -verbose "${MF_SUDOER:-opc}@$node" "oracle" "$EMCTL stop blackout MF_2_${CDB_NAME}_Migration" \
                                     "Remove Migration Factory blackout for $CDB_NAME" "$I2"      
             ;;
      IS_ON) libAction "Testing if MF_${CDB_NAME}_Migration id present" "$I2"
             if [ "$(exec_on_target -tty "${MF_SUDOER:-opc}@$node" "oracle" "$EMCTL status blackout" | grep MF_2.*${CDB_NAME}_Migration)" != "" ]
             then
               echo "Blackout is ON"
             else 
               echo "**** NO BLACKOUT *****"
               die "One or more servers are not under blackout"
             fi
             echo       
             ;;
    esac
    done
  fi
  endStep

  # ------------------------------------------------------------------------------------------------------
  endRun
