#
# -----------------------------------------------------------------------------
#
#  File               : mfEmBlackout.sh
#
#  Purpose            : Manage EM blackouts for a target database.
#
#  Description        : Creates, removes, queries, or verifies target monitoring blackouts through
#                       local OEM agents or the optional centralized OEM REST API.
#
#  Functions           : 
#                        - detailed_usage
#                        - usage
#
# *****************************************************************************

VERSION=1.16
# ************************************************************************** 
# Modifications :
# =============
# 
# 13/09/2024 MBO - Delivery MF 1.2 @ BNP, change logging mechanism to avoid
#                  sub processes, temporary files cleanup (mktemp with suffixes)
#
# 15/11/2024 MBO - Version 1.2.5, before LOT-0 start,
# 06/08/2026 AIN - Version 1.9, create START blackouts centrally through the
#                  OEM REST API and preserve the legacy non-START actions.
# 06/08/2026 AIN - Versions 1.10-1.11, iterate on centralized REST scheduling.
# 07/08/2026 AIN - Version 1.12, preserve local emctl behavior by default and
#                  add opt-in OEM REST handling for every action with -r.
# 08/08/2026 AIN - Version 1.13, retain the compatible START default; use
#                  REST-first/local-emctl fallback before REST mutation; and
#                  preserve a common blackout identity across both methods.
# 08/08/2026 AIN - Version 1.14, simplify REST blackouts to one canonical ID,
#                  duration-based START, non-blocking STOP, and START-owned
#                  terminal cleanup before canonical-name reuse.
# 10/08/2026 AIN - Version 1.15, make a REST START without -d end at the
#                  planned GO-LIVE start plus two hours.
# 17/09/2026 AIN - Version 1.16, make REST START an idempotent ensure-on
#                  operation and keep REST failures on the selected backend.
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
#  Function            : detailed_usage
#
#  Description         : Explains blackout actions, backend selection, duration behavior, and fallback safety.
#
#  Input Parameters    : - None.
#
#  Output              : Prints detailed user-facing help to standard output.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : Describes local-agent and REST blackout lifecycle handling.
# -----------------------------------------------------------------------------
#


detailed_usage()
{
  cat <<EOF
  =======================================================================================
  $(basename "$0") : Detailed information
  =======================================================================================

  Purpose
  =======

    Manage monitoring blackouts for the target database and, for local-agent
    handling, related target/peer-cluster nodes. START suppresses alerts; STOP
    resumes monitoring. STATUS displays blackout information and IS_ON succeeds
    only when blackout coverage is verified.

    Without -r, the script runs local emctl on each repository-listed node as
    oracle. It creates/stops the common MF_2_<CDB_NAME>_Migration blackout and
    discovers Oracle database targets containing the CDB name on each node.

  Main workflow
  =============

    With -r, the OEM REST helper manages the canonical blackout name. START is
    an ensure-on operation: it reuses any exact STARTED blackout or creates a
    new one and succeeds only after exact STARTED coverage is verified. REST
    failures never fall back to local emctl. Without -r, the legacy local emctl
    workflow remains unchanged.

    -d supplies an explicit START duration. The local emctl default remains
    12:00. For REST START without -d, a future GO-LIVE ends at GO-LIVE + 2h, a
    GO-LIVE that has already passed creates a fresh 2h blackout, and a missing
    or ambiguous GO-LIVE value falls back to 1h.

  Operational notes
  =================

    START and STOP change external OEM monitoring state. Local mode requires
    repository node discovery, SSH/sudo access, the OEM agent/emctl, and target
    visibility. REST mode additionally requires the REST helper configuration.
    Confirm the intended backend and duration before mutating blackout state.
EOF
}

#
# -----------------------------------------------------------------------------
#
#  Function            : usage
#
#  Description         : Prints every accepted argument and detailed blackout lifecycle help.
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
  $SCRIPT_LIB

Required:
  -m MIGRATION_ID        : ID of the migration (base name for files).

Options:
  -A ACTION              : START (default), STOP, STATUS, or IS_ON.
  -d DURATION            : Explicit START duration in [D] HH:MI format.
  -r                     : Use the centralized OEM REST API for the selected action.
                             Without -r, all actions retain local emctl behavior.
  -Q                     : Quiet mode (remove progress output).
  -V                     : Print all logging information.
  -n                     : Disable log output.
  -h, -?                 : Show this help and exit.
  --help                 : Show this help plus the detailed usage section and exit.

Examples:
  $(basename "$0") -m MIGRATION_ID
  $(basename "$0") -m MIGRATION_ID -A START -d 02:00
  $(basename "$0") -m MIGRATION_ID -r -A START
  $(basename "$0") -m MIGRATION_ID -r -A START -d 02:00
  $(basename "$0") -m MIGRATION_ID -r -A STATUS

Notes:
  START/STOP change OEM monitoring state. Omit -d to use the planned GO-LIVE
  window for REST START; pass -d only to override that duration.

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
  startStep "Initialization"                                      >> "$TMPFILE"
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
  ACTION=START
  DURATION="12:00"
  DURATION_EXPLICIT=N
  USE_REST_API=N
  toShift=0
  while getopts :m:A:d:rQVnh opt
  do
    case $opt in
     # --------- Script parameters ---------------------------------------------
     A) ACTION=${OPTARG^^}                            ; toShift=$(($toShift + 2)) ;;
     d) DURATION=${OPTARG^^} ; DURATION_EXPLICIT=Y    ; toShift=$(($toShift + 2)) ;;
     r) USE_REST_API=Y                                ; toShift=$(($toShift + 1)) ;;
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
  # REST support is optional. Keep legacy local-agent actions independent of
  # the REST helper and its prerequisites unless -r was explicitly selected.
  if [ "$USE_REST_API" = "Y" ]
  then
    . "$SCRIPT_DIR/mfEmBlackout_oemRest.sh" \
      || die "Unable to load OEM REST support"
  fi
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

  startStep "Preliminary verifications"
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
    infoAction "    Company naming convention" "$I1"
    CDB_NAME=$(echo $TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME | sed -e "s;_.*$;;")
    CDB_UNIQUE_NAME=$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME
  elif [[ $TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME =~ ^C.*M[0-9]*$ ]]
  then
    infoAction "    Company naming convention" "$I1"
    CDB_NAME=$(echo $TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME | sed -e "s;M[0-9]*$;;")
    CDB_UNIQUE_NAME=$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME
  else
    CDB_NAME=$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME
    CDB_UNIQUE_NAME=$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME
  fi

  infoAction "    Database              : $CDB_NAME" "$I1"
  infoAction "    Database unique name  : $CDB_UNIQUE_NAME" "$I1"

  # A REST START without an explicit -d follows the planned migration window.
  # Keep -d authoritative for shorter maintenance actions such as a rolling
  # restart, and keep the legacy local-emctl default unchanged.
  if [ "$USE_REST_API" = "Y" ] && [ "$ACTION" = "START" ] && [ "$DURATION_EXPLICIT" != "Y" ]
  then
    DURATION=$(exec_sql "$MF_REPO_CONNECT" "
      select case
        when count(*) != 1 then null
        when min(target_date) <= sysdate then '02:00'
        else
          case
            when (min(target_date) + interval '2' hour - sysdate) < 1 then ''
            else to_char(trunc(min(target_date) + interval '2' hour - sysdate)) || ' '
          end ||
          to_char(trunc(mod((min(target_date) + interval '2' hour - sysdate) * 24, 24)), 'FM00') || ':' ||
          to_char(trunc(mod((min(target_date) + interval '2' hour - sysdate) * 24 * 60, 60)), 'FM00')
      end
      from migration_planned_operations po
      where po.mig_id = '$MFAUTO_MIG_ID'
        and po.mls_id = mf_mig_parameters.get_id('MLS_ID_GOLIVE_START', po.prj_name)
        and po.current_plan = 'Y';")
    [ "$DURATION" = "" ] && DURATION='01:00'
    infoAction "    REST duration         : $DURATION (planned GO-LIVE + 2 hours)" "$I1"
  fi
  EMCTL=/u02/app/oracle/oem/agent/agent_inst/bin/emctl
  startStep "$ACTION a blackout for a database ($CDB_NAME)"

  ERR=0
  
  if [ "$USE_REST_API" = "Y" ]
  then
    trap mf_oem_cleanup EXIT
    case "$ACTION" in
      START)
        mf_oem_start_blackout "$MF_MIGRATION_ID" "$MFAUTO_MIG_ID" "$CDB_NAME" \
          "$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME" "$DURATION"
        REST_RC=$?
        case "$REST_RC" in
          0) : ;;
          3) die "OEM REST START could not prove an exact STARTED blackout" ;;
          *) die "OEM REST START failed or remained unverified; no local fallback was attempted" ;;
        esac
        ;;
      STATUS)
        if ! mf_oem_status_blackout "$MF_MIGRATION_ID" "$MFAUTO_MIG_ID" "$CDB_NAME" \
             "$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME"
        then
          die "OEM REST STATUS failed; no local fallback was attempted"
        fi
        ;;
      IS_ON)
        mf_oem_is_blackout_on "$MF_MIGRATION_ID" "$MFAUTO_MIG_ID" "$CDB_NAME" \
          "$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME"
        REST_RC=$?
        case "$REST_RC" in
          0) : ;;
          3) die "Canonical OEM REST blackout is not STARTED with complete discovered target coverage" ;;
          *) die "OEM REST IS_ON could not be verified; no local fallback was attempted" ;;
        esac
        ;;
      STOP)
        mf_oem_stop_blackout "$MF_MIGRATION_ID" "$MFAUTO_MIG_ID" "$CDB_NAME" \
          "$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME"
        REST_RC=$?
        case "$REST_RC" in
          0) : ;;
          3) die "OEM REST STOP could not identify a safe complete result" ;;
          4) die "The OEM REST blackout changed to a non-stoppable state" ;;
          *) die "OEM REST STOP failed or remained uncertain; no local fallback was attempted" ;;
        esac
        ;;
    esac
    mf_oem_cleanup
    trap - EXIT
  fi

  if [ "$USE_REST_API" != "Y" ]
  then
    # Default compatibility path: retain the original local-agent emctl command
    # behavior unless -r is supplied.
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
      # START)  targets=$(exec_on_target -tty "${MF_SUDOER:-opc}@$node" "oracle" "$EMCTL config agent listtargets" | grep $CDB_NAME | sed -e "s;\[;;" -e "s;\];;" -e "s; *, *;:;" | tr '\n' ' ')
      START)  exec_on_target -verbose "${MF_SUDOER:-opc}@$node" "oracle" "$EMCTL config agent listtargets | grep $CDB_NAME | grep oracle_database"
              targets=$(exec_on_target -tty "${MF_SUDOER:-opc}@$node" "oracle" "$EMCTL config agent listtargets" | grep $CDB_NAME | grep oracle_database | sed -e "s;\[;;" -e "s;\];;" -e "s; *, *;:;" | cut -f1 -d":" |tr '\n' ' ')
              infoAction "Blacked out = $targets" "$I2"
              exec_on_target -verbose "${MF_SUDOER:-opc}@$node" "oracle" "$EMCTL start blackout MF_2_${CDB_NAME}_Migration \$(echo \"$targets\") -d $DURATION" \
                                     "Create Migration factory blackout for $CDB_NAME" "$I2"
             ;;
      STATUS) exec_on_target -verbose "${MF_SUDOER:-opc}@$node" "oracle" "$EMCTL status blackout | awk 'BEGIN {pr=0} /${CDB_NAME}_Migration/ {pr=1 ; printf(\"* * * * * * * * * * * * * * * * * * %s * * * * * * * * * * * * * * * * * *\n\",\$0) ; next} /Expired/ {if (pr==1) {print} ; pr=0 ; next } {if (pr==1) print}'" \
                                     "Status of Migration Factory blackout for $CDB_NAME" "$I2"      
             ;;
      STOP) exec_on_target -verbose "${MF_SUDOER:-opc}@$node" "oracle" "$EMCTL stop blackout MF_2_${CDB_NAME}_Migration" \
                                     "Remove Migration Factory blackout for $CDB_NAME" "$I2"      
             ;;
      IS_ON) libAction "Testing if MF_${CDB_NAME}_Migration id present" "$I2"
             if [ "$(exec_on_target -tty "${MF_SUDOER:-opc}@$node" "oracle" "$EMCTL status blackout" | grep MF_2.*${CDB_NAME}_Migration)" != "" ]
             then
               infoAction "Blackout is active" "$I2"
             else 
               infoAction "Blackout is not active" "$I2"
               die "One or more servers are not under blackout"
             fi
             ;;
    esac
    done
  fi
  endStep

  # ------------------------------------------------------------------------------------------------------
  endRun
