#
# -----------------------------------------------------------------------------
#
#  Generation marker  : MF_DOC_GENERATED
#  File               : mfStatistics.sh
#
#  Purpose            : Gather statistics.
#
#  Description        : Initializes the Migration Factory environment, validates the selected
#                       context, and executes the operational workflow for this entry point.
#
#  Functions           : 
#                        - detailed_usage
#                        - usage
#
# *****************************************************************************

VERSION=1.9
# ************************************************************************** 
# Modifications :
# =============
# 
# 13/09/2024 MBO - Delivery MF 1.2 @ BNP, change logging mechanism to avoid
#                  sub processes, temporary files cleanup (mktemp with suffixes)
#
# 15/11/2024 MBO - Version 1.2.5, before LOT-0 start,
#
# 18/08/2026 AIN - Version 1.9, skip the known approximate-NDV ORA-00600
#                   qeaeMinmaxFastFIV:inputlen failure with a warning and continue
#                   with the next schema. This is a probable Oracle Database bug.
#
# ************************************************************************** 
SCRIPT_LIB="Migration Factory 2.0 : Gather statistics"
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
#  Description         : Prints the detailed usage information for
#                        mfStatistics.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Parse command-line options and dispatch the requested action.
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
#         This script calculate initial statistics of all user schemas after migration.
#         
#         Since data migration is made by export/improt, it is useful to gather statistics
#       after copy, even in the case where the application has its own statistics management 
#       system
#     
#     The main functions are :
#     
#     - Gather Shema statistics
#       --------------
#       
#         run for each schema in the database
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

    Gather statistics.

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
      - Gather Statistic Schemas

  Operational notes
  =================

    - Review the selected migration context before running the script, because
      most actions are driven by repository and environment values.
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
# #  Description         : Prints the short usage information for mfStatistics.sh.
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
#
# {
#  echo "Usage :
#  $(basename $0) -m MIGRATION_ID [-Q|-V] [-n] [-h|-?]
#
#       $SCRIPT_LIB
#        
#       Gather the statistics on the migrated database. This script need to
#    be run AFTER each migration. You can start it while the client is
#    modifiying the connect strings of the application.
#       
#   Positional parameters (must appear first and in this order) :
#   ===========================================================
#   
#     --automatic          : Step tracked by automated migrations and/or having specific behauvior.
#     
#
#   Parameters :
#   ==========
#          -m MIGRATION_ID  : ID of the migration (base name for files)  MANDATORY
#          -Q               : Quiet mode (remove progress output)
#          -V               : Print all loging information
#          -?|-h            : Help
#
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
  Gather statistics.

Required:
  -m MIGRATION_ID        : ID of the migration (base name for files).

Options:
  -Q                     : Quiet mode (remove progress output).
  -V                     : Print all logging information.
  -n                     : Disable log output.
  -h, -?                 : Show this help and exit.
  --help                 : Show this help plus the detailed usage section and exit.

Examples:
  $(basename "$0") -m MIGRATION_ID

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
[ "$1" = "--automatic" ] && { MF_AUTOMATED_MIGRATIONS=Y ; shift ; }
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
  while getopts :m:QVnh opt
  do
    case $opt in
     # --------- Script parameters ---------------------------------------------
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

  # ------------------------------------------------------------------------------------------------------
  forcedOutput ON
  mfBUSpecificActions $SCRIPT 100-start

  startStep "Gather Statistic Schemas"
    exec_sql -verbose "$MF_TGT_PDB_CONNECT" "
                                    set serveroutput on
                                    ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';
                                    SELECT CURRENT_TIMESTAMP FROM DUAL;
                                        BEGIN
                                          FOR rec IN (SELECT * 
                                                      FROM all_users
                                                       WHERE oracle_maintained = 'N')
                                          LOOP
                                            dbms_output.put_line ('       - Statistics for : ' || rec.username) ;
                                            begin
                                              dbms_stats.gather_schema_stats('\"' || rec.username || '\"',CASCADE => TRUE,degree=>8);
                                              dbms_output.put_line ('         - end' || rec.username) ;
                                            exception
                                              when others then
                                                if sqlcode = -20011
                                                   and instr(sqlerrm,
                                                             'qeaeMinmaxFastFIV:inputlen') > 0
                                                then
                                                  dbms_output.put_line(
                                                    '         - WARNING: statistics skipped for schema '
                                                    || rec.username
                                                    || ' after the known approximate-NDV failure.'
                                                  );
                                                else
                                                  dbms_output.put_line(
                                                    '         - end (ERROR)' || rec.username
                                                  );
                                                  dbms_output.put_line(sqlerrm);
                                                end if;
                                            end ;
                                          END LOOP;
                                       END;
                                       /
                                    SELECT CURRENT_TIMESTAMP FROM DUAL;

                                  " || die "Unable to gather statistics"
  endStep

  # ------------------------------------------------------------------------------------------------------

  endRun

  mfBUSpecificActions $SCRIPT 900-finish
