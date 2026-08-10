#
# -----------------------------------------------------------------------------
#
#  Generation marker  : MF_DOC_GENERATED
#  File               : mfUpdateparams.sh
#
#  Purpose            : Update database parameters.
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
# 13/09/2024 PBE - Version 1.2.5, Script creation
#
# 05/02/2025 CBI - Version 1.2.6, modified by CBI to secure script and
#                  adding verify/remediation modes
#
# 05/06/2025 CBI - Version 1.5, modified by CBI to update parameters
#                  with formulas
#
# **************************************************************************
SCRIPT_LIB="Migration Factory 2.0 : Update database parameters"
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
#                        mfUpdateparams.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Parse command-line options and dispatch the requested action.
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
#         This script updates the SPFILE parameter of the target and of its stand-by if it
#       exists, based on the values of the source equivalent parameters.
#     
#     The main functions are :
#     
#     - Update parameters
#       --------------
#       
#         For every parameter not default on the source, we read the action to take in the repository
#       and,if an update is necesayry in the target we update the SPFILE, at the CDB or PDB level, 
#       depending on the parameter.
#       
#         A backup of spfile before modification is taken in case the database is not able to restart.
#         
#         parameters are updated only if the value differs.
#         
#     - Update parameters
#       --------------
#       
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

    Update database parameters.

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
      - Pfile has been created
      - Pfile does not exists
      - Failed to rename old version of pfile
      - The latest version of pfile has been downloaded to the hub server
      - Failed to download the latest version of pfile to the hub server
      - Calculating requiered SGA memory on Container Database
      - Retrieve SGA from each PDB
      - Updating instance parameters
      - Fix CDB parameters on standby database

  Integration points
  ==================

    The script interacts with or delegates work to:

      - mfEmBlackout.sh
      - mfGetDbInfo.sh
      - ASM

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
# #  Description         : Prints the short usage information for
# #                        mfUpdateparams.sh.
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
#  $(basename $0) -m MIGRATION_ID [-r] [-e] [-f] [-Q|-V] [-n] [-h|-?]
#
#       $SCRIPT_LIB
#
#       Update SPFILE parameters with values gathered on the source depending on decisions
#   registered in the migration factory. The database is restarted if necessary and the rolling
#   mode is used if -r flag is positioned.
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
#          -t ROLE          : Apply changes to PRIMARY|STANDBY database (default PRIMARY)
#          -r               : Restart in rolling mode
#          -e               : Evaluate mode
#          -f               : Force database to restart (rolling or complete)
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
  Update database parameters.

Required:
  -m MIGRATION_ID        : ID of the migration (base name for files).

Options:
  -t ROLE                : Apply changes to PRIMARY|STANDBY database (default PRIMARY).
  -f                     : Force database to restart (rolling or complete).
  -r                     : Restart in rolling mode.
  -e                     : Evaluate mode.
  -Q                     : Quiet mode (remove progress output).
  -V                     : Print all logging information.
  -n                     : Disable log output.
  -h, -?                 : Show this help and exit.
  --help                 : Show this help plus the detailed usage section and exit.

Examples:
  $(basename "$0") -m MIGRATION_ID
$(basename "$0") -m MIGRATION_ID -t ROLE

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
  MF_DATABASE_ROLE="PRIMARY"
  ROLLING_MODE=N
  FORCE_RESTART=N
  EVALUATE_ONLY=N
  toShift=0
  while getopts :m:t:freQVnh opt
  do
    case $opt in
     # --------- Script parameters ---------------------------------------------
     # --------- Common parameters ---------------------------------------------
     Q) setVar LOG_QUIET                  Y           ; toShift=$(($toShift + 1)) ;;
     V) setVar LOG_QUIET                  N           ; toShift=$(($toShift + 1)) ;;
     m) setVar MF_MIGRATION_ID            ${OPTARG^^} ; toShift=$(($toShift + 2)) ;;
     t) setVar MF_DATABASE_ROLE           ${OPTARG^^} ; toShift=$(($toShift + 2)) ;;
     e) setVar EVALUATE_ONLY              Y           ; toShift=$(($toShift + 1)) ;;
     r) setVar ROLLING_MODE               Y           ; toShift=$(($toShift + 1)) ;;
     f) setVar FORCE_RESTART              Y           ; toShift=$(($toShift + 1)) ;;
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
  [[ "$MF_DATABASE_ROLE" != "PRIMARY" && "$MF_DATABASE_ROLE" != "STANDBY" ]] && die "DATABASE_ROLE (-t) should be PRIMARY or STANDBY"
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
  
  if [ "${MF_DATABASE_ROLE}" != "PRIMARY" ]; then
   
    DATABASE_LIST=$(exec_sql "$MF_TGT_CDB_CONNECT" "SET HEADING OFF;
SET FEEDBACK OFF;
SELECT db_unique_name || ':' || REGEXP_REPLACE(dest_role, ' ', '_')
FROM v\$dataguard_config
WHERE UPPER(dest_role) LIKE '%${MF_DATABASE_ROLE}%';"
)
        
    if [ ! -z "$DATABASE_LIST" ]
    then
    
      for DATABASE in $DATABASE_LIST
      do
        
        if [ "$(echo $DATABASE | cut -d ':' -f1 | grep "_")" != "" ]
        then
          echo
          echo "            - ORACLE Naming convention"
          CDB_NAME_STANDBY=$(echo $DATABASE | cut -d ':' -f1 | sed -e "s;_.*$;;")
          CDB_UNIQUE_NAME_STANDBY=$(echo $DATABASE | cut -d ':' -f1)
          CDB_ROLE_STANDBY=$(echo $DATABASE | cut -d ':' -f2)
        elif [[ "$(echo $DATABASE | cut -d ':' -f1)" =~ ^C.*M[0-9]*$ ]]
        then
          echo
          echo "            - BNP Naming convention"
          CDB_NAME_STANDBY=$(echo $DATABASE | cut -d ':' -f1 | sed -e "s;M[0-9]*$;;")
          CDB_UNIQUE_NAME_STANDBY=$(echo $DATABASE | cut -d ':' -f1)
          CDB_ROLE_STANDBY=$(echo $DATABASE | cut -d ':' -f2)
        else
          echo
          echo "            - Direct naming"
          CDB_NAME_STANDBY=$(echo $DATABASE | cut -d ':' -f1)
          CDB_UNIQUE_NAME_STANDBY=$(echo $DATABASE | cut -d ':' -f1)
          CDB_ROLE_STANDBY=$(echo $DATABASE | cut -d ':' -f2)
        fi
        
        echo
        echo "      CDB_NAME           : $CDB_NAME_STANDBY ($CDB_ROLE_STANDBY)"
        echo "      CDB_UNIQUE_NAME    : $CDB_UNIQUE_NAME_STANDBY ($CDB_ROLE_STANDBY)"
        
      done
    
    else
    
      die "No database with ${MF_DATABASE_ROLE} role"
    
    fi
  
  else

    DATABASE_LIST="${CDB_UNIQUE_NAME}:PRIMARY"
  
  fi
  
  echo

  endStep

  # ------------------------------------------------------------------------------------------------------
  forcedOutput ON
  
  
  envFile=$(echo "${CDB_NAME}." | cut -d "." -f1)
  envFile=$(echo "${envFile}_" | cut -d "_" -f1)

  echo

  infoAction "Determine how to set environment for : $envFile" "$I2"
  if [ "$targetSystem" = "DBSYSTEM" ]
  then
    envCommand=". oraenv <<< $envFile"
  else
    envCommand="[ -f \$HOME/$envFile.env ] && { . \$HOME/$envFile.env ; } \
                || { echo \"Unable to find the env file\"; exit 1 ; }"
  fi
  
  hosts=$(echo "$MF_TGT_CLUSTER_HOSTS" | sed 's/ /,/g')
  remoteHost=$(echo "$hosts" | cut -d ',' -f1)
  
        
  if [ ! -z "$DATABASE_LIST" ]
  then
  
    for DATABASE in $DATABASE_LIST
    do
  
      if [ "$(echo $DATABASE | cut -d ':' -f1 | grep "_")" != "" ]
      then
        CDB_NAME=$(echo $DATABASE | cut -d ':' -f1 | sed -e "s;_.*$;;")
        CDB_UNIQUE_NAME=$(echo $DATABASE | cut -d ':' -f1)
      elif [[ "$(echo $DATABASE | cut -d ':' -f1)" =~ ^C.*M[0-9]*$ ]]
      then
        CDB_NAME=$(echo $DATABASE | cut -d ':' -f1 | sed -e "s;M[0-9]*$;;")
        CDB_UNIQUE_NAME=$(echo $DATABASE | cut -d ':' -f1)
      else
        CDB_NAME=$(echo $DATABASE | cut -d ':' -f1)
        CDB_UNIQUE_NAME=$(echo $DATABASE | cut -d ':' -f1)
      fi
  
      CDB_ROLE=$(echo $DATABASE | cut -d ':' -f2)
      CDB_CREDENTIALS=$(echo $MF_TGT_CDB_CONNECT | rev | cut -d '@' -f2- | rev)

      remoteCommand=$(cat <<%%
$envCommand
tnsping ${CDB_UNIQUE_NAME} | grep -i 'Attempting to contact' -A1 -B1
%%
)

      resultCommand=$(exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHost" "oracle" "$remoteCommand" "Retrieving ${CDB_UNIQUE_NAME} TNS on remote host [$remoteHost]" "$I2")
      echo "$resultCommand"
      
      CDB_TNS=$(echo "$resultCommand" | grep -i 'Attempting to contact' | cut -d '(' -f2- | rev | cut -d ')' -f2- |rev)

      startStep "Apply database parameters to the target database ${CDB_UNIQUE_NAME} (${CDB_ROLE})"

      exec_sql "$MF_REPO_CONNECT" "select 1 from dual;" "Testing repository connection" "$I2" \
        || die "Unable to connect to repository, use disconnected script (MFAUTO_REPO_USER is not set)"
        
      ## TNS ENTRY FROM STANDBY --> IP ADDRESS FROM DISASTER RECOVERY NETWORK --> NSLOOKUP NOT POSSIBLE
      CDB_HOSTS=$(echo "$CDB_TNS" | grep -oP '(?<=\(HOST=)[^)]+(?=\))' | paste -sd, | sed 's/ /,/g')
      CDB_REMOTE_HOST=$(echo "$CDB_HOSTS" | cut -d ',' -f1)
      
      #CDB_SCAN_ADDRESS=$(nslookup ${CDB_REMOTE_HOST} | grep scan | sed 's/ //g' | cut -d '=' -f2- | rev |cut -d '.' -f2- | rev)
      
      ## RETRIEVE CLUSTER NODES FROM STANDBY
#sqlplus ${CDB_CREDENTIALS}@${CDB_UNIQUE_NAME} <<SQL
      remoteCommand=$(cat <<%%
$envCommand
sqlplus ${CDB_CREDENTIALS} <<SQL
SET HEADING OFF;
SET FEEDBACK OFF;
SELECT 'host=' || host_name FROM v\\\\\$instance;
SQL
%%
)

# echo "$remoteCommand"
# echo "$remoteHost"

      resultCommand=$(exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHost" "oracle" "$remoteCommand" "Retrieving ${CDB_UNIQUE_NAME} cluster name" "$I2")
# echo "$resultCommand"
      CDB_CLUSTER=$(echo "$resultCommand" | grep 'host=' | cut -d '=' -f2)
      
	  # echo " CDB_CLUSTER : $CDB_CLUSTER"
	  
      CDB_CLUSTER_HOSTS=$(exec_sql "$MF_REPO_CONNECT" "SET HEADING OFF;
SET FEEDBACK OFF;
SELECT LISTAGG(FQDN, ' ') WITHIN GROUP (ORDER BY NAME) 
FROM TARGET_NODES 
WHERE TCLU_ID IN (SELECT TCLU_ID 
                  FROM TARGET_NODES 
                  WHERE NAME = '${CDB_CLUSTER}'
                  and prj_name = (select prj_name from databases where db_id=$MFAUTO_DB_ID)
                 );")

#      CDB_CLUSTER_HOSTS=$(exec_sql "$MF_REPO_CONNECT" "SET HEADING OFF;
#SET FEEDBACK OFF;
#SELECT LISTAGG(IP, ' ') WITHIN GROUP (ORDER BY NAME) FROM MFBNP.TARGET_NODES WHERE TCLU_ID IN (
#SELECT TCLU_ID FROM MFBNP.TARGET_NODES WHERE NAME = '${CDB_CLUSTER}'
#);")

      ## RETRIEVE SCAN_ADDRESS FROM STANDBY      
      CDB_SCAN_ADDRESS=$(exec_sql "$MF_REPO_CONNECT" "SET HEADING OFF;
SET FEEDBACK OFF;
SELECT SCAN_ADDRESS 
FROM TARGET_CLUSTERS 
WHERE TCLU_ID IN (SELECT TCLU_ID 
                  FROM TARGET_NODES 
                  WHERE NAME = '${CDB_CLUSTER}'
                  and prj_name = (select prj_name from databases where db_id=$MFAUTO_DB_ID)
                 );")

      CDB_CONNECT="${CDB_CREDENTIALS}@\"(DESCRIPTION=(ADDRESS=(HOST=${CDB_SCAN_ADDRESS})(protocol=tcp)(port=1521))(connect_data=(service_name=${CDB_UNIQUE_NAME})))\""
      
      PDB_NAME="${TARGETDATABASE_CONNECTIONDETAILS_SERVICENAME}"
      PDB_CONNECT="${CDB_CREDENTIALS}@\"(DESCRIPTION=(ADDRESS=(HOST=${CDB_SCAN_ADDRESS})(protocol=tcp)(port=1521))(connect_data=(service_name=${PDB_NAME})))\""
      
       # echo "CDB_CLUSTER_HOSTS=$CDB_CLUSTER_HOSTS"

  remoteHostAvailable=""

  for host in $CDB_CLUSTER_HOSTS
  do
    echo
# echo "host=$host"
    remoteCommand=$(cat <<%%
$envCommand
srvctl status database -d \$ORACLE_UNQNAME | grep -i \$ORACLE_SID
%%
)

    resultCommand=$(exec_on_target -verbose "${MF_SUDOER:-opc}@$host" "oracle" "$remoteCommand" "Checking local instance on $(echo $host | cut -d '.' -f1)" "$I2")

    echo "$resultCommand"

    if [ $(echo "$resultCommand" | grep -i 'is running' | wc -l | tr -d ' ') -gt 0 ]
    then
      remoteHostAvailable=$host
      break
    fi

  done

  if [ -z "$remoteHostAvailable" ]
  then
    die "Unable to identify remote host with running instance"
  else
    echo
    infoAction "A running instance has been identified on $remoteHostAvailable" "$B2"
  fi

  echo

  mfRepo_updateProgress UPD_REF
  exec_sql -verbose "$MF_REPO_CONNECT" "
set feedback on
update db_parameters dbp
set migration_action=(select migration_action
                      from   SPFILE_PARAMETERS spp
                      where  spp.name=dbp.name
                      and    spp.prj_name=dbp.prj_name)
where dbp.mig_id=$MFAUTO_MIG_ID
and   nvl(dbp.MIGRATION_ACTION,'MANUAL') = 'MANUAL'
and exists ( select 1
             from   SPFILE_PARAMETERS
             where  prj_name=dbp.PRJ_NAME
             and    name = dbp.name
             and    migration_action is not null);" "Set default action for parameters still not defined" "$I2"

  # Get the number of NULL and MANUAL entries in the MIGRATION_ACTION column
  migp=$(exec_sql "$MF_REPO_CONNECT" "select count(*) from db_parameters  where nvl(MIGRATION_ACTION,'MANUAL') = 'MANUAL'  and  MIG_ID = $MFAUTO_MIG_ID;")
  migp=$(echo "$migp" | tr -d ' ')

  echo
  infoAction "$migp parameter(s) with NULL or MANUAL in MIGRATION_ACTION" "$B2"

  if [ $migp -ne 0 ]
  then
    echo "Please, review parameters and/or default actions"
    die "Check MIGRATION_ACTION parameters list"
  fi

  echo

  remoteCommand0=$(cat <<%%
chown oracle:oinstall /tmp/$CDB_UNIQUE_NAME.ora
%%
)

  remoteCommand=$(cat <<%%
echo "Target host is : \$(hostname -f)"
$envCommand
echo "Environment variables are :"
env | grep "^ORA"
echo "Creating pfile from spfile :"
echo "/tmp/$CDB_UNIQUE_NAME.ora"
sqlplus -s / as sysdba <<SQL_AT_TARGET | egrep -v "^\$"
create pfile='/tmp/$CDB_UNIQUE_NAME.ora' from spfile;
SQL_AT_TARGET
%%
)

  exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHostAvailable" "oracle" "$remoteCommand" \
    "Creating pfile from spfile" "$I2" || die "Unable to create pfile from spfile"

  echo

  ssh -o StrictHostKeyChecking=no ${MF_SUDOER:-opc}@$remoteHostAvailable sudo -su root chown opc:opc /tmp/$CDB_UNIQUE_NAME.ora
  ssh -q ${MF_SUDOER:-opc}@$remoteHostAvailable [[ -f /tmp/$CDB_UNIQUE_NAME.ora ]] && infoAction "Pfile has been created" "$B2" || infoAction "Pfile does not exists" "$B2";

  if  [ -f /u01/app/migrationFactory/data/target_pfile/$CDB_UNIQUE_NAME.ora ];
  then
    newPfile="$CDB_UNIQUE_NAME.ora"
    oldPfile="$CDB_UNIQUE_NAME.$(date +"%Y-%m-%d_%H-%M-%S").ora"
    cp /u01/app/migrationFactory/data/target_pfile/$newPfile /u01/app/migrationFactory/data/target_pfile/$oldPfile && infoAction "An old version of pfile has been found and renamed to $oldPfile" "$B2" || infoAction "Failed to rename old version of pfile" "$B2";
  fi

  scp ${MF_SUDOER:-opc}@$remoteHostAvailable:/tmp/$CDB_UNIQUE_NAME.ora /u01/app/migrationFactory/data/target_pfile/ && infoAction "The latest version of pfile has been downloaded to the hub server" "$B2" || infoAction "Failed to download the latest version of pfile to the hub server" "$B2";

  echo

  exec_on_target "${MF_SUDOER:-opc}@$remoteHostAvailable" "root" "$remoteCommand0" \
    "Change the ownership of the pfile to oracle:oinstall" "$I2" || die "Change the ownership of the pfile to oracle:oinstall"


  COUNT_UPDATE=0
  COUNT_TODO=0
  COUNT_SKIP=0

  # START IF DB ROLE IS PRIMARY
  if [ "${MF_DATABASE_ROLE}" = "PRIMARY" ]; then

    echo
    infoAction "Calculating requiered SGA memory on Container Database" "$I2"

    mfRepo_updateProgress UPD_SGA
    CDB_SGA_TARGET=0
    CDB_STREAMS_POOL_SIZE=0
    MIN_SGA_TARGET=2147483648
    MIN_STREAMS_POOL_SIZE=268435456

    REPO_SGA_TARGET=$(exec_sql "$MF_REPO_CONNECT" "select a.NAME || ';'||a.SOURCE_VALUE || ';'|| nvl(a.formula,a.TARGET_VALUE) || ';'|| a.MIGRATION_ACTION ||';'|| NVL(b.ISPDB_MODIFIABLE,'FALSE') from db_parameters a left join v\$parameter b on a.NAME=b.NAME where MIG_ID = $MFAUTO_MIG_ID AND a.NAME='sga_target';")
    
    #REPO_SGA_TARGET=$(exec_sql "$MF_REPO_CONNECT" "select distinct a.NAME ||';'|| a.SOURCE_VALUE ||';'|| a.TARGET_VALUE ||';'|| a.MIGRATION_ACTION ||';'|| NVL(b.ISPDB_MODIFIABLE,'FALSE') ||';'|| c.FORMULA from db_parameters a join spfile_parameters c on (c.name = a.name and a.prj_name = c.prj_name) left join v\$parameter b on a.NAME=b.NAME where MIG_ID = $MFAUTO_MIG_ID AND a.NAME='sga_target';")

    #echo "REPO_SGA_TARGET='$REPO_SGA_TARGET'"

    SGA_SOURCE_VALUE=$(echo "$REPO_SGA_TARGET" | cut -d ";" -f2)
    SGA_TARGET_VALUE=$(echo "$REPO_SGA_TARGET" | cut -d ";" -f3)
    SGA_MIGRATION_ACTION=$(echo "$REPO_SGA_TARGET" | cut -d ";" -f4)
    #SGA_FORMULA=$(echo "$REPO_SGA_TARGET" | cut -d ";" -f6)
    
    #echo "SGA_MIGRATION_ACTION='$SGA_MIGRATION_ACTION'"
    #echo "SGA_FORMULA='$SGA_FORMULA'"
  
    if [ "$SGA_MIGRATION_ACTION" = "FORMULA" ] && [ ! -z "$SGA_TARGET_VALUE" ]
    then
      SGA_FORMULA="NULL"
      if [ ! -z "$SGA_TARGET_VALUE" ]; then
        SGA_FORMULA="$SGA_TARGET_VALUE"
        SGA_FORMULA=$(echo "${SGA_FORMULA}" | sed "s/\[MIG_ID\]/${MFAUTO_MIG_ID}/gI")
      fi
      SGA_TARGET=$(exec_sql "$MF_REPO_CONNECT" "select ${SGA_FORMULA} from dual;")
      #echo "SGA_FORMULA='$SGA_FORMULA'"
      #echo "SGA_TARGET='$SGA_TARGET'"
    fi
  
    #if [ "$SGA_MIGRATION_ACTION" = "FORMULA" ] && [ ! -z "$SGA_FORMULA" ]
    #then
    #  SGA_FORMULA=$(echo "${SGA_FORMULA}" | sed "s/\[MIG_ID\]/${MFAUTO_MIG_ID}/gI")
    #  SGA_TARGET=$(exec_sql "$MF_REPO_CONNECT" "select TO_CHAR(${SGA_FORMULA}) from dual;")
    #  
    #  if [[ "$SGA_TARGET" =~ ^[0-9]+$ ]] || [[ "${SGA_TARGET^^}" == "FALSE" ]] || [[ "${SGA_TARGET^^}" == "TRUE" ]]; then
    #    SGA_TARGET=$SGA_TARGET
    #  else
    #    SGA_TARGET="'$SGA_TARGET'"
    #  fi
    #  
    #  echo "SGA_FORMULA='$SGA_FORMULA'"
    #  echo "SGA_TARGET='$SGA_TARGET'"
    #fi

    if [ "$SGA_MIGRATION_ACTION" = "KEEP" ] && [ ! -z "$SGA_SOURCE_VALUE" ]
    then
      SGA_TARGET=$SGA_SOURCE_VALUE
    fi

    if [ "$SGA_MIGRATION_ACTION" = "KEEP_GREATER" ] && [ "$SGA_SOURCE_VALUE" -gt "$SGA_TARGET_VALUE" ] && [ ! -z "$SGA_SOURCE_VALUE" ]
    then
      SGA_TARGET=$SGA_SOURCE_VALUE
    fi

    if [ "$SGA_MIGRATION_ACTION" = "KEEP_SMALLER" ] && [ "$SGA_SOURCE_VALUE" -lt "$SGA_TARGET_VALUE" ] && [ ! -z "$SGA_SOURCE_VALUE" ]
    then
      SGA_TARGET=$SGA_SOURCE_VALUE
    fi

    if [ "$SGA_TARGET" = "0" ] || [ -z "$SGA_TARGET" ]
    then
      SGA_TARGET=$MIN_SGA_TARGET
    fi

    CDB_SGA_TARGET=$SGA_TARGET

    REPO_STREAMS_POOL_SIZE=$(exec_sql "$MF_REPO_CONNECT" "select a.NAME || ';'||a.SOURCE_VALUE || ';'|| nvl(a.formula,a.TARGET_VALUE) || ';'|| a.MIGRATION_ACTION ||';'|| NVL(b.ISPDB_MODIFIABLE,'FALSE') from db_parameters a left join v\$parameter b on a.NAME=b.NAME where MIG_ID = $MFAUTO_MIG_ID AND a.NAME='streams_pool_size';")

    #REPO_STREAMS_POOL_SIZE=$(exec_sql "$MF_REPO_CONNECT" "select a.NAME ||';'|| a.SOURCE_VALUE ||';'|| a.TARGET_VALUE ||';'|| a.MIGRATION_ACTION ||';'|| NVL(b.ISPDB_MODIFIABLE,'FALSE') ||';'|| c.FORMULA from db_parameters a join spfile_parameters c on (c.name = a.name and a.prj_name = c.prj_name) left join v\$parameter b on a.NAME=b.NAME where MIG_ID = $MFAUTO_MIG_ID AND a.NAME='streams_pool_size';")  

    #echo "REPO_STREAMS_POOL_SIZE='$REPO_STREAMS_POOL_SIZE'"

    STREAMS_POOL_SOURCE_VALUE=$(echo "$REPO_STREAMS_POOL_SIZE" | cut -d ";" -f2)
    STREAMS_POOL_TARGET_VALUE=$(echo "$REPO_STREAMS_POOL_SIZE" | cut -d ";" -f3)
    STREAMS_POOL_MIGRATION_ACTION=$(echo "$REPO_STREAMS_POOL_SIZE" | cut -d ";" -f4)
    #STREAMS_POOL_FORMULA=$(echo "$REPO_STREAMS_POOL_SIZE" | cut -d ";" -f6)
    
    if [ "$STREAMS_POOL_MIGRATION_ACTION" = "FORMULA" ] && [ ! -z "$STREAMS_POOL_TARGET_VALUE" ]
    then
      STREAMS_POOL_FORMULA="NULL"
      if [ ! -z "$STREAMS_POOL_TARGET_VALUE" ]; then
        STREAMS_POOL_FORMULA="$STREAMS_POOL_TARGET_VALUE"
        STREAMS_POOL_FORMULA=$(echo "${STREAMS_POOL_FORMULA}" | sed "s/\[MIG_ID\]/${MFAUTO_MIG_ID}/gI")
      fi
      STREAMS_POOL_SIZE=$(exec_sql "$MF_REPO_CONNECT" "select ${STREAMS_POOL_FORMULA} from dual;")
      #echo "STREAMS_POOL_FORMULA='$STREAMS_POOL_FORMULA'"
      #echo "STREAMS_POOL_SIZE='$STREAMS_POOL_SIZE'"
    fi
  
    #if [ "$STREAMS_POOL_MIGRATION_ACTION" = "FORMULA" ] && [ ! -z "$STREAMS_POOL_FORMULA" ]
    #then
    #  STREAMS_POOL_FORMULA=$(echo "${STREAMS_POOL_FORMULA}" | sed "s/\[MIG_ID\]/${MFAUTO_MIG_ID}/gI")
    #  STREAMS_POOL_SIZE=$(exec_sql "$MF_REPO_CONNECT" "select TO_CHAR(${STREAMS_POOL_FORMULA}) from dual;")
    #  STREAMS_POOL_SIZE="'$STREAMS_POOL_SIZE'"
    #  #echo "STREAMS_POOL_FORMULA='$STREAMS_POOL_FORMULA'"
    #  #echo "STREAMS_POOL_SIZE='$STREAMS_POOL_SIZE'"
    #fi

    if [ "$STREAMS_POOL_MIGRATION_ACTION" = "KEEP" ] && [ ! -z "$STREAMS_POOL_SOURCE_VALUE" ]
    then
      STREAMS_POOL_SIZE=$STREAMS_POOL_SOURCE_VALUE
    fi

    if [ "$STREAMS_POOL_MIGRATION_ACTION" = "KEEP_GREATER" ] && [ "$STREAMS_POOL_SOURCE_VALUE" -gt "$STREAMS_POOL_TARGET_VALUE" ] && [ ! -z "$STREAMS_POOL_SOURCE_VALUE" ]
    then
      STREAMS_POOL_SIZE=$STREAMS_POOL_SOURCE_VALUE
    fi

    if [ "$STREAMS_POOL_MIGRATION_ACTION" = "KEEP_SMALLER" ] && [ "$STREAMS_POOL_SOURCE_VALUE" -lt "$STREAMS_POOL_TARGET_VALUE" ] && [ ! -z "$STREAMS_POOL_SOURCE_VALUE" ]
    then
      STREAMS_POOL_SIZE=$STREAMS_POOL_SOURCE_VALUE
    fi

    if [ "$STREAMS_POOL_SIZE" = "0" ] || [ -z "$STREAMS_POOL_SIZE" ]
    then
      STREAMS_POOL_SIZE=$MIN_STREAMS_POOL_SIZE
    fi

    CDB_STREAMS_POOL_SIZE=$STREAMS_POOL_SIZE

    ## On va vérifier les valeurs pour les autres PDB, si on ne trouve pas, on va récupérer la valeur par défaut dans le REPO.

    PDB_LIST=$(exec_sql "$CDB_CONNECT" "SET HEADING OFF;
SET FEEDBACK OFF;
SELECT name
FROM v\$pdbs
WHERE UPPER(name) NOT IN ('PDB\$SEED','${CDB_UNIQUE_NAME^^}');"
)

    if [ ! -z "$PDB_LIST" ]
    then

      infoAction "Retrieve SGA from each PDB" "$I3"

      for PDB in $PDB_LIST
      do

        SGA_TARGET=0
	echo "CDB_CONNECT : $CDB_CONNECT"
	
        SGA_TARGET=$(exec_sql "$CDB_CONNECT" "ALTER SESSION SET CONTAINER=$PDB;
SET PAGESIZE 0;
SET HEADING OFF;
SET FEEDBACK OFF;
SELECT value FROM v\$spparameter WHERE UPPER(name) = 'SGA_TARGET';"
) || die "$SGA_TARGET"                                            

        if [ -z "$SGA_TARGET" ]
        then

          SGA_TARGET=$(exec_sql "$MF_REPO_CONNECT" "SET PAGESIZE 0;
SET HEADING OFF;
SET FEEDBACK OFF;
SELECT TO_CHAR(MAX(COALESCE(TO_NUMBER(P.TARGET_VALUE), TO_NUMBER(P.SOURCE_VALUE), $MIN_SGA_TARGET))) AS SGA_TARGET
FROM MIGRATION_ATTEMPTS MA
JOIN DATABASES DB
ON (MA.DB_ID = DB.DB_ID)
LEFT OUTER JOIN DB_PARAMETERS P
ON (MA.DB_ID = P.DB_ID)
WHERE UPPER(MA.TARGET_CONTAINER_SERVICE) = '${CDB_UNIQUE_NAME^^}'
AND UPPER(MA.TARGET_SERVICE) = '${PDB^^}'
AND UPPER(P.NAME) = 'SGA_TARGET';"
) || die "$SGA_TARGET" 

        fi

        STREAMS_POOL_SIZE=0

        STREAMS_POOL_SIZE=$(exec_sql "$CDB_CONNECT" "ALTER SESSION SET CONTAINER=$PDB;
SET PAGESIZE 0;
SET HEADING OFF;
SET FEEDBACK OFF;
SELECT nvl(value,0) FROM v\$spparameter WHERE UPPER(name) = 'STREAMS_POOL_SIZE';"
) || die "$STREAMS_POOL_SIZE"

        if [ -z "$STREAMS_POOL_SIZE" ]
        then

          STREAMS_POOL_SIZE=$(exec_sql "$MF_REPO_CONNECT" "SET PAGESIZE 0;
SET HEADING OFF;
SET FEEDBACK OFF;
SELECT TO_CHAR(MAX(COALESCE(TO_NUMBER(P.TARGET_VALUE), TO_NUMBER(P.SOURCE_VALUE), $MIN_STREAMS_POOL_SIZE))) AS STREAMS_POOL_SIZE
FROM MIGRATION_ATTEMPTS MA
JOIN DATABASES DB
ON (MA.DB_ID = DB.DB_ID)
LEFT OUTER JOIN DB_PARAMETERS P
ON (MA.DB_ID = P.DB_ID)
WHERE UPPER(MA.TARGET_CONTAINER_SERVICE) = '${CDB_UNIQUE_NAME^^}'
AND UPPER(MA.TARGET_SERVICE) = '${PDB^^}'
AND UPPER(P.NAME) = 'STREAMS_POOL_SIZE';"
) || die "$STREAMS_POOL_SIZE"

        fi

        if [ "$STREAMS_POOL_SIZE" = "0" ] || [ -z "$STREAMS_POOL_SIZE" ]
        then
          STREAMS_POOL_SIZE=$MIN_STREAMS_POOL_SIZE
        fi

        ### CBI - Dans le cadre des migrations à blanc, on ne met pas la taille cumulée des SGA mais plutôt la taille de la plus grosse SGA
        if [ $SGA_TARGET -gt $CDB_SGA_TARGET ]
        then
          CDB_SGA_TARGET=$SGA_TARGET
        fi
        if [ $STREAMS_POOL_SIZE -gt $CDB_STREAMS_POOL_SIZE ]
        then
          CDB_STREAMS_POOL_SIZE=$STREAMS_POOL_SIZE
        fi
        ###

        # CDB_SGA_TARGET=$(echo "$CDB_SGA_TARGET + $SGA_TARGET" | bc)
        # CDB_STREAMS_POOL_SIZE=$(echo "$CDB_STREAMS_POOL_SIZE + $STREAMS_POOL_SIZE" | bc)

        infoAction "The SGA_TARGET value for $PDB (PDB) is $SGA_TARGET" "$B3"
        infoAction "The STREAMS_POOL_SIZE value for $PDB (PDB) is $STREAMS_POOL_SIZE" "$B3"

      done
    else
      infoAction "No additional PDB identified on CDB ${CDB_UNIQUE_NAME^^}" "$B3"
    fi


    ### CBI - TEST TO DELETE - 20250306
    # CDB_STREAMS_POOL_SIZE=$(echo "2*1024*1024*1024" | bc)
    # CDB_SGA_TARGET=$(echo "1*1024*1024*1024" | bc)
    # COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
    ###


    infoAction "Cumulative size of SGA_TARGET is $CDB_SGA_TARGET" "$B3"
    infoAction "Cumulative size of STREAMS_POOL_SIZE is $CDB_STREAMS_POOL_SIZE" "$B3"

    if [ $CDB_SGA_TARGET -gt 0 ]
    then

      if [ $CDB_SGA_TARGET -lt $MIN_SGA_TARGET ]
      then
        infoAction "The minimum allowed size for SGA_TARGET (CDB) is $MIN_SGA_TARGET" "$B3"
        CDB_SGA_TARGET=$MIN_SGA_TARGET
      fi

      if [ $CDB_STREAMS_POOL_SIZE -lt $MIN_STREAMS_POOL_SIZE ]
      then
        infoAction "The minimum allowed size for STREAMS_POOL_SIZE (CDB) is $MIN_STREAMS_POOL_SIZE" "$B3"
        CDB_STREAMS_POOL_SIZE=$MIN_STREAMS_POOL_SIZE
      fi

      if [ $CDB_STREAMS_POOL_SIZE -gt $MIN_STREAMS_POOL_SIZE ]
      then
        CDB_SGA_TARGET=$(echo "$CDB_SGA_TARGET + $CDB_STREAMS_POOL_SIZE - $MIN_STREAMS_POOL_SIZE" | bc)
        infoAction "The cumulative size for SGA_TARGET + STREAMS_POOL_SIZE (CDB) is $CDB_SGA_TARGET" "$B3"
      fi

      ACTUAL_SGA_TARGET_VALUE=$(exec_sql "$CDB_CONNECT" "select value from v\$spparameter where name='sga_target';")

      infoAction "Actual value of SGA_TARGET (CDB) is $ACTUAL_SGA_TARGET_VALUE" "$B3"

      ACTUAL_STREAMS_POOL_SIZE_VALUE=$(exec_sql "$CDB_CONNECT" "select nvl(value,0) from v\$spparameter where name='streams_pool_size';")

      infoAction "Actual value of STREAMS_POOL_SIZE (CDB) is $ACTUAL_STREAMS_POOL_SIZE_VALUE" "$B3"

      if [ "$ACTUAL_SGA_TARGET_VALUE" != "$CDB_SGA_TARGET" ]
      then

        echo
        infoAction "Updating SGA_TARGET on container database $CDB_UNIQUE_NAME" "$I2"

        if [ $EVALUATE_ONLY != "Y" ]
        then
          exec_sql "$CDB_CONNECT" "ALTER SYSTEM SET SGA_TARGET=$CDB_SGA_TARGET SCOPE=SPFILE SID='*';" "Set SGA_TARGET=$CDB_SGA_TARGET (CDB) - Updated ($SGA_MIGRATION_ACTION)" "$I3" || die "Unable to apply SGA_TARGET ($SGA_MIGRATION_ACTION)"
          COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
        else
          libAction "Update SGA_TARGET to '$CDB_SGA_TARGET' (CDB)" "$I3"
          echo "$SGA_MIGRATION_ACTION"
          COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
        fi

      fi

      if [ "$ACTUAL_STREAMS_POOL_SIZE_VALUE" != "$CDB_STREAMS_POOL_SIZE" ]
      then

        echo
        infoAction "Updating STREAMS_POOL_SIZE on container database $CDB_UNIQUE_NAME" "$I2"

        if [ $EVALUATE_ONLY != "Y" ]
        then
          exec_sql "$CDB_CONNECT" "ALTER SYSTEM SET STREAMS_POOL_SIZE=$CDB_STREAMS_POOL_SIZE SCOPE=SPFILE SID='*';" "Set STREAMS_POOL_SIZE=$CDB_STREAMS_POOL_SIZE (CDB) - Updated ($STREAMS_POOL_MIGRATION_ACTION)" "$I3" || die "Unable to apply STREAMS_POOL_SIZE ($STREAMS_POOL_MIGRATION_ACTION)"
          COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
        else
          libAction "Update STREAMS_POOL_SIZE to '$CDB_STREAMS_POOL_SIZE' (CDB)" "$I3"
          echo "$STREAMS_POOL_MIGRATION_ACTION"
          COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
        fi
      fi
    fi

    #echo "CDB_SGA_TARGET='$CDB_SGA_TARGET'"
    #echo "CDB_STREAMS_POOL_SIZE='$CDB_STREAMS_POOL_SIZE'"
    #exit
  fi
  # END IF DB ROLE IS PRIMARY

  echo
  infoAction "Updating instance parameters" "$I2"
  mfRepo_updateProgress UPD_SPFILE

  # Get the spfile path
  spfilevalue=$(exec_sql "$CDB_CONNECT" "select value from v\$parameter where name='spfile';")
  spfilepath=${spfilevalue%/*}
  exec_sql "$MF_REPO_CONNECT" "select 
                                  a.NAME || ';'||
                                  a.SOURCE_VALUE || ';'|| 
                                  trim(nvl(a.formula,a.TARGET_VALUE)) || ';'|| 
                                  a.MIGRATION_ACTION ||';'|| 
                                  NVL(b.ISPDB_MODIFIABLE,'FALSE')||';'||
                                  b.ISINSTANCE_MODIFIABLE||';'||
                                  b.ISSYS_MODIFIABLE||';'||
                                  c.formula 
                               from 
                                  db_parameters a 
                                  join spfile_parameters c on (a.name = c.name and a.prj_name = c.prj_name)
                                  left join v\$parameter b on a.name=b.name
                               where
                                  MIG_ID = $MFAUTO_MIG_ID
                               and
                                  lower(a.NAME) not in ('sga_target','streams_pool_size')
                               and 
                                  lower(a.name) not like 'nls%'
                               union
                               select
                                  lower(a.parameter) || ';'||
                                  a.SOURCE_VALUE || ';'|| 
                                  a.TARGET_VALUE || ';'|| 
                                  'KEEP' || ';'|| 
                                  'TRUE' || ';'|| 
                                  'TRUE' || ';'||
                                  null                                  
                               from
                                 db_nls_parameters a
                               where
                                  MIG_ID = $MFAUTO_MIG_ID and parameter not like '%CURRENCY%'
                                  and lower(parameter) not in ('nls_characterset','nls_nchar_characterset','nls_rdbms_version')
                               ;" > $TMPFILE2 || { cat $TMPFILE2 ; die "Error retrieving the parameters from REPO" ; }
  while read line
  do
    NAME=$(echo "$line" | cut -d ";" -f1)
    PARAM=$NAME
    SOURCE_VALUE=$(echo "$line" | cut -d ";" -f2)
    TARGET_VALUE=$(echo "$line" | cut -d ";" -f3)
    MIGRATION_ACTION=$(echo "$line" | cut -d ";" -f4)
    ISPDB_MODIFIABLE=$(echo "$line" | cut -d ";" -f5)
    ISINSTANCE_MODIFIABLE=$(echo "$line" | cut -d ";" -f6)
    ISSYS_MODIFIABLE=$(echo "$line" | cut -d ";" -f7)
    FORMULA=$(echo "$line" | cut -d ";" -f8)
    NAME="\"${NAME}\""


    # MBO : Paramètres ISINSTANCE_MODIFIABLE=FALSE mais que l'on peut modifier quand même
    case $PARAM in
      audit_trail) ISINSTANCE_MODIFIABLE=TRUE ;;
    esac
    
    ### CBI
    # if [ $(echo "${PARAM^^}" | grep -i 'SGA_TARGET' | wc -l | tr -d ' ') -gt 0 ]
    # then
    #  echo "SKIP - $PARAM"
    #  continue
    # fi
    ###

    ## Controle à effectuer avant la boucle (sinon application de paramètre dans la cible)
    if [ "$MIGRATION_ACTION" = "MANUAL" ] || [ -z "$MIGRATION_ACTION" ]
    then
      die "ERROR  -  Kindly REVERIFY the parameter $NAME"
    fi
    if [ "${ISPDB_MODIFIABLE^^}" = "FALSE" ]
    then
      TARGET_CHECK="CDB"
      ACTUAL_TARGET_VALUE=$(exec_sql "$CDB_CONNECT" "select value from v\$spparameter where name='$PARAM';")
      ACTUAL_TARGET_VALUE=$(echo "$ACTUAL_TARGET_VALUE" | sed "s/^'//;s/'$//")
    else
      TARGET_CHECK="PDB"
      #ACTUAL_TARGET_VALUE=$(exec_sql "$CDB_CONNECT" "select value from v\$parameter where name='$PARAM';")
      ACTUAL_TARGET_VALUE=$(exec_sql "$CDB_CONNECT" "SELECT ps.value\$
FROM sys.pdb_spfile\$ ps
JOIN v\$pdbs p ON p.con_uid = ps.pdb_uid
WHERE UPPER(p.name) = '${PDB_NAME^^}'
AND ps.name = '$PARAM';")
      ACTUAL_TARGET_VALUE=$(echo "$ACTUAL_TARGET_VALUE" | sed "s/^'//;s/'$//")
    fi

    if [ -z "$ACTUAL_TARGET_VALUE" ]
    then
      ACTUAL_TARGET_VALUE="<UNASSIGNED>"
    fi

    #echo "$B3${PARAM^^}:$MIGRATION_ACTION|'$SOURCE_VALUE':'$TARGET_VALUE':'$ACTUAL_TARGET_VALUE'|ISINSTANCE_MODIFIABLE='$ISINSTANCE_MODIFIABLE'|ISSYS_MODIFIABLE='$ISSYS_MODIFIABLE'"

    SPFILE_VALUE=$(cat /u01/app/migrationFactory/data/target_pfile/$CDB_UNIQUE_NAME.ora | grep -i ".$PARAM=" | head -1 | cut -d '=' -f2-)
    SPFILE_VALUE=$(echo "$SPFILE_VALUE" | sed "s/^'//;s/'$//")

    #if [ "$SOURCE_VALUE" = "$ACTUAL_TARGET_VALUE" ] && [ "$MIGRATION_ACTION" = "KEEP" ]
    #then
    #  libAction "Match $NAME=$SOURCE_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
    #  echo "MATCH"
    #  continue
    #fi

    if [ "$ROLLING_MODE" = "Y" ]
    then
      if [ "${ISINSTANCE_MODIFIABLE^^}" = "FALSE" ]
      then
        libAction "Ignore change on $NAME ($TARGET_CHECK) - Ignored" "$I3"
        echo "IGNORE"
        COUNT_SKIP=$(echo "$COUNT_SKIP + 1" | bc)
        continue
      fi
    fi

    #
    # Case of KEEP
    #

    #
    # When ISPDB_MODIFIABLE is TRUE
    #

    if [ "$MIGRATION_ACTION" = "KEEP" ] && [ ! -z "$SOURCE_VALUE" ] && [ $ISPDB_MODIFIABLE = "TRUE" ]
    then
      if [[ "$SOURCE_VALUE" =~ ^[0-9]+$ ]] || [[ "${SOURCE_VALUE^^}" == "FALSE" ]] || [[ "${SOURCE_VALUE^^}" == "TRUE" ]]
      then
        if [ "${SOURCE_VALUE^^}" != "${ACTUAL_TARGET_VALUE^^}" ]
        then
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SESSION SET CONTAINER=$MF_TGT_DBNAME;
ALTER SYSTEM SET $NAME=$SOURCE_VALUE SCOPE=SPFILE SID='*';" "Set $NAME=$SOURCE_VALUE (PDB) - Updated (KEEP)" "$I3" || die "Unable to apply $NAME (KEEP)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $NAME=$ACTUAL_TARGET_VALUE -> $SOURCE_VALUE (PDB)" "$I3"
            echo "KEEP"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        else
          libAction "Match $NAME=$SOURCE_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
          echo "MATCH"
          continue
        fi
      else
        if [ "${SOURCE_VALUE^^}" != "${ACTUAL_TARGET_VALUE^^}" ]
        then
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SESSION SET CONTAINER=$MF_TGT_DBNAME;
ALTER SYSTEM SET $NAME='$SOURCE_VALUE' SCOPE=SPFILE SID='*';" "Set $NAME='$SOURCE_VALUE' (PDB) - Updated (KEEP)" "$I3" || die "Unable to apply $NAME (KEEP)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $NAME=$ACTUAL_TARGET_VALUE -> '$SOURCE_VALUE' (PDB)" "$I3"
            echo "KEEP"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        else
          libAction "Match $NAME=$SOURCE_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
          echo "MATCH"
          continue
        fi
      fi
    fi


    #
    # When ISPDB_MODIFIABLE is FALSE
    #

    if [ "$MIGRATION_ACTION" = "KEEP" ] && [ ! -z "$SOURCE_VALUE" ] && [ $ISPDB_MODIFIABLE = "FALSE" ]
    then
      if [[ "$SOURCE_VALUE" =~ ^[0-9]+$ ]] || [[ "${SOURCE_VALUE^^}" == "FALSE" ]] || [[ "${SOURCE_VALUE^^}" == "TRUE" ]]
      then
        if [ "${SOURCE_VALUE^^}" != "${ACTUAL_TARGET_VALUE^^}" ]
        then
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SYSTEM SET $NAME=$SOURCE_VALUE CONTAINER=CURRENT SCOPE=SPFILE SID='*';" "Set $NAME=$SOURCE_VALUE (CDB) - Updated (KEEP)" "$I3" || die "Unable to apply $NAME (KEEP)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $NAME=$ACTUAL_TARGET_VALUE -> $SOURCE_VALUE (CDB)" "$I3"
            echo "KEEP"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        else
          libAction "Match $NAME=$SOURCE_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
          echo "MATCH"
          continue
        fi
      else
        if [ "${SOURCE_VALUE^^}" != "${ACTUAL_TARGET_VALUE^^}" ]
        then
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SYSTEM SET $NAME='$SOURCE_VALUE' CONTAINER=CURRENT SCOPE=SPFILE SID='*';" "Set $NAME='$SOURCE_VALUE' (CDB) - Updated (KEEP)" "$I3" || die "Unable to apply $NAME (KEEP)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $NAME=$ACTUAL_TARGET_VALUE -> '$SOURCE_VALUE' (CDB)" "$I3"
            echo "KEEP"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        else
          libAction "Match $NAME=$SOURCE_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
          echo "MATCH"
          continue
        fi
      fi
    fi

#
# CASE of FORMULA
#

    #
    # When ISPDB_MODIFIABLE is TRUE
    #

    if [ "$MIGRATION_ACTION" = "FORMULA" ] && [ ! -z "$TARGET_VALUE" ] && [ $ISPDB_MODIFIABLE = "TRUE" ]
    then
      
      FORMULA=$(echo "${TARGET_VALUE}" | sed "s/\[MIG_ID\]/${MFAUTO_MIG_ID}/gI")
      FORMULA_VALUE=$(exec_sql "$MF_REPO_CONNECT" "select ${FORMULA} from dual;")
      FORMULA_VALUE=$(echo "$FORMULA_VALUE" | sed -e "s;^[ \t]*;;" -e "s;[ \t]*$;;")
      
      #echo "FORMULA='$FORMULA'"
      #echo "FORMULA_VALUE='$FORMULA_VALUE'"
    
      if [[ "$FORMULA_VALUE" =~ ^[0-9]+$ ]] || [[ "${FORMULA_VALUE^^}" == "FALSE" ]] || [[ "${FORMULA_VALUE^^}" == "TRUE" ]]
      then
        if [ "${FORMULA_VALUE^^}" != "${ACTUAL_TARGET_VALUE^^}" ]
        then
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SESSION SET CONTAINER=$MF_TGT_DBNAME;
ALTER SYSTEM SET $NAME=$FORMULA_VALUE SCOPE=SPFILE SID='*';" "Set $NAME=$FORMULA_VALUE (PDB) - Updated (FORMULA)" "$I3" || die "Unable to apply $NAME (FORMULA)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $NAME=$ACTUAL_TARGET_VALUE -> $FORMULA_VALUE (PDB)" "$I3"
            echo "FORMULA"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        else
          libAction "Match $NAME=$FORMULA_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
          echo "MATCH"
          continue
        fi
      else
        if [ "${FORMULA_VALUE^^}" != "${ACTUAL_TARGET_VALUE^^}" ]
        then
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SESSION SET CONTAINER=$MF_TGT_DBNAME;
ALTER SYSTEM SET $NAME='$FORMULA_VALUE' SCOPE=SPFILE SID='*';" "Set $NAME='$FORMULA_VALUE' (PDB) - Updated (FORMULA)" "$I3" || die "Unable to apply $NAME (FORMULA)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $NAME=$ACTUAL_TARGET_VALUE -> '$FORMULA_VALUE' (PDB)" "$I3"
            echo "FORMULA"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        else
          libAction "Match $NAME=$FORMULA_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
          echo "MATCH"
          continue
        fi
      fi
    fi


    #
    # When ISPDB_MODIFIABLE is FALSE
    #

    if [ "$MIGRATION_ACTION" = "FORMULA" ] && [ ! -z "$TARGET_VALUE" ] && [ $ISPDB_MODIFIABLE = "FALSE" ]
    then
    
      FORMULA=$(echo "${TARGET_VALUE}" | sed "s/\[MIG_ID\]/${MFAUTO_MIG_ID}/gI")
      FORMULA_VALUE=$(exec_sql "$MF_REPO_CONNECT" "select trim(${FORMULA}) from dual;")      
      FORMULA_VALUE=$(echo "$FORMULA_VALUE" | sed -e "s;^[ \t]*;;" -e "s;[ \t]*$;;")

      #echo "FORMULA='$FORMULA'"
      #echo "FORMULA_VALUE='$FORMULA_VALUE'"
    
      if [[ "$FORMULA_VALUE" =~ ^[0-9]+$ ]] || [[ "${FORMULA_VALUE^^}" == "FALSE" ]] || [[ "${FORMULA_VALUE^^}" == "TRUE" ]]
      then
        if [ "${FORMULA_VALUE^^}" != "${ACTUAL_TARGET_VALUE^^}" ]
        then
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SYSTEM SET $NAME=$FORMULA_VALUE CONTAINER=CURRENT SCOPE=SPFILE SID='*';" "Set $NAME=$FORMULA_VALUE (CDB) - Updated (FORMULA)" "$I3" || die "Unable to apply $NAME (FORMULA)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $NAME=$ACTUAL_TARGET_VALUE -> $FORMULA_VALUE (CDB)" "$I3"
            echo "FORMULA"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        else
          libAction "Match $NAME=$FORMULA_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
          echo "MATCH"
          continue
        fi
      else
        if [ "${FORMULA_VALUE^^}" != "${ACTUAL_TARGET_VALUE^^}" ]
        then
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SYSTEM SET $NAME='$FORMULA_VALUE' CONTAINER=CURRENT SCOPE=SPFILE SID='*';" "Set $NAME='$FORMULA_VALUE' (CDB) - Updated (FORMULA)" "$I3" || die "Unable to apply $NAME (FORMULA)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $NAME=$ACTUAL_TARGET_VALUE -> '$FORMULA_VALUE' (CDB)" "$I3"
            echo "FORMULA"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        else
          libAction "Match $NAME=$FORMULA_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
          echo "MATCH"
          continue
        fi
      fi
    fi
#
# CASE of KEEP_GREATER / KEEP_SMALLER
#

    #
    # When TARGET_VALUE is NUMERIC and SOURCE_VALUE is NOT NULL and ISPDB_MODIFIABLE is TRUE
    #

    if [[ $TARGET_VALUE =~ ^[0-9]+$ ]] && [ $ISPDB_MODIFIABLE = "TRUE" ] && [ ! -z "$SOURCE_VALUE" ]
    then
      if [ "$MIGRATION_ACTION" = "KEEP_GREATER" ] && [ "$SOURCE_VALUE" -gt "$TARGET_VALUE" ] && [ ! -z "$SOURCE_VALUE" ]
      then
        if [ "${SOURCE_VALUE^^}" != "${ACTUAL_TARGET_VALUE^^}" ]
        then
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SESSION SET CONTAINER=$MF_TGT_DBNAME;
ALTER SYSTEM SET $NAME=$SOURCE_VALUE SCOPE=SPFILE SID='*';" "Set $NAME=$SOURCE_VALUE (PDB) - Updated (KEEP_GREATER)" "$I3"  || die "Unable to apply $NAME (KEEP_GREATER)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $NAME=$ACTUAL_TARGET_VALUE -> $SOURCE_VALUE (PDB)" "$I3"
            echo "KEEP_GREATER"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        else
          libAction "Match $NAME=$SOURCE_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
          echo "MATCH"
          continue
        fi
      fi
      if [ "$MIGRATION_ACTION" = "KEEP_SMALLER" ] && [ "$SOURCE_VALUE" -lt "$TARGET_VALUE" ] && [ ! -z "$SOURCE_VALUE" ]
      then
        if [ "${SOURCE_VALUE^^}" != "${ACTUAL_TARGET_VALUE^^}" ]
        then
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SESSION SET CONTAINER=$MF_TGT_DBNAME;
ALTER SYSTEM SET $NAME=$SOURCE_VALUE scope=spfile sid='*';" "Set $NAME=$SOURCE_VALUE (PDB) - Updated (KEEP_SMALLER)" "$I3"  || die "Unable to apply $NAME (KEEP_SMALLER)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $NAME=$ACTUAL_TARGET_VALUE -> $SOURCE_VALUE (PDB)" "$I3"
            echo "KEEP_SMALLER"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        else
          libAction "Match $NAME=$SOURCE_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
          echo "MATCH"
          continue
        fi
      fi
    fi

    #
    # When TARGET_VALUE is NUMERIC and SOURCE_VALUE is NOT NULL and ISPDB_MODIFIABLE is FALSE
    #

    if [[ $TARGET_VALUE =~ ^[0-9]+$ ]] && [ $ISPDB_MODIFIABLE = "FALSE" ] && [ ! -z "$SOURCE_VALUE" ]
    then
      if [ "$MIGRATION_ACTION" = "KEEP_GREATER" ] && [ "$SOURCE_VALUE" -gt "$TARGET_VALUE" ] && [ ! -z "$SOURCE_VALUE" ]
      then
        if [ "${SOURCE_VALUE^^}" != "${ACTUAL_TARGET_VALUE^^}" ]
        then
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SYSTEM SET $NAME=$SOURCE_VALUE CONTAINER=CURRENT SCOPE=SPFILE SID='*';" "Set $NAME=$SOURCE_VALUE (CDB) - Updated (KEEP_GREATER)" "$I3"  || die "Unable to apply $NAME (KEEP_GREATER)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $NAME=$ACTUAL_TARGET_VALUE -> $SOURCE_VALUE (CDB)" "$I3"
            echo "KEEP_GREATER"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        else
          libAction "Match $NAME=$SOURCE_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
          echo "MATCH"
          continue
        fi
      fi
      if [ "$MIGRATION_ACTION" = "KEEP_SMALLER" ] && [ "$SOURCE_VALUE" -lt "$TARGET_VALUE" ] && [ ! -z "$SOURCE_VALUE" ]
      then
        if [ "${SOURCE_VALUE^^}" != "${ACTUAL_TARGET_VALUE^^}" ]
        then
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SYSTEM SET $NAME=$SOURCE_VALUE CONTAINER=CURRENT SCOPE=SPFILE SID='*';" "Set $NAME=$SOURCE_VALUE (CDB) - Updated (KEEP_SMALLER)" "$I3"  || die "Unable to apply $NAME (KEEP_SMALLER)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $NAME=$ACTUAL_TARGET_VALUE -> $SOURCE_VALUE (CDB)" "$I3"
            echo "KEEP_SMALLER"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        else
          libAction "Match $NAME=$SOURCE_VALUE >< $ACTUAL_TARGET_VALUE ($TARGET_CHECK)" "$I3"
          echo "MATCH"
          continue
        fi
      fi
    fi

  done < $TMPFILE2
  rm -f $TMPFILE2
  
  
  ## FIXING CDB PARAMETERS ON STANDBY DATABASES TO ALIGN WITH PRIMARY
  
  if [ "${MF_DATABASE_ROLE}" != "PRIMARY" ]; then
  
    echo
    infoAction "Fix CDB parameters on standby database" "$I2"
    mfRepo_updateProgress FIX_STANDBY_CDB_PARAMS
  
    #cpu_count
    #pga_aggregate_target
    #pga_aggregate_limit
    #sga_max_size
    #sga_target
    #streams_pool_size
    #db_flashback_retention_target
    #db_recovery_file_dest_size
    
    for p in cpu_count pga_aggregate_target pga_aggregate_limit sga_max_size sga_target streams_pool_size db_flashback_retention_target db_recovery_file_dest_size
    do
      
      ACTUAL_PRIMARY_CDB_VALUE=$(exec_sql "$MF_TGT_CDB_CONNECT" "SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT value FROM v\$spparameter WHERE name = '$p';")

      ACTUAL_STANDBY_CDB_VALUE=$(exec_sql "$CDB_CONNECT" "SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT value FROM v\$spparameter WHERE name = '$p';")

      ACTUAL_PRIMARY_CDB_VALUE=${ACTUAL_PRIMARY_CDB_VALUE:-"<NULL>"}
      ACTUAL_STANDBY_CDB_VALUE=${ACTUAL_STANDBY_CDB_VALUE:-"<NULL>"}

      if [[ "${ACTUAL_PRIMARY_CDB_VALUE^^}" != "${ACTUAL_STANDBY_CDB_VALUE^^}" ]];then
      
        if [[ "$ACTUAL_PRIMARY_CDB_VALUE" == "<NULL>" ]]; then
        
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SYSTEM RESET $p scope=spfile sid='*';" "Reset $p (CDB) - Updated (FIX_STANDBY)" "$I3"  || die "Unable to reset $p (FIX_STANDBY)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Reset $p (CDB)" "$I3"
            echo "FIX_STANDBY"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
      
        else
        
          if [ "$EVALUATE_ONLY" != "Y" ]
          then
            exec_sql "$CDB_CONNECT" "ALTER SYSTEM SET $p=$ACTUAL_PRIMARY_CDB_VALUE scope=spfile sid='*';" "Set $p=$ACTUAL_PRIMARY_CDB_VALUE (CDB) - Updated (FIX_STANDBY)" "$I3"  || die "Unable to apply $p (FIX_STANDBY)"
            COUNT_UPDATE=$(echo "$COUNT_UPDATE + 1" | bc)
          else
            libAction "Update $p=$ACTUAL_STANDBY_CDB_VALUE -> $ACTUAL_PRIMARY_CDB_VALUE (CDB)" "$I3"
            echo "FIX_STANDBY"
            COUNT_TODO=$(echo "$COUNT_TODO + 1" | bc)
          fi
        fi
      else
        libAction "Match $p=$ACTUAL_PRIMARY_CDB_VALUE >< $ACTUAL_STANDBY_CDB_VALUE (CDB)" "$I3"
        echo "MATCH"
      fi
    done  
  fi

  if [ $COUNT_UPDATE -gt 0 ] || [ $COUNT_TODO -gt 0 ] || [ $COUNT_SKIP -gt 0 ] ; then
    echo
  else
    echo "$B3--> No parameter to update."
  fi
  if [ $COUNT_UPDATE -gt 0 ]; then
    echo "$B3--> $COUNT_UPDATE parameter(s) updated."
  fi
  if [ $COUNT_TODO -gt 0 ]; then
    echo "$B3--> $COUNT_TODO parameter(s) to update."
  fi
  if [ $COUNT_SKIP -gt 0 ]; then
    echo "$B3--> $COUNT_SKIP parameter(s) ignored because rolling restart is not possible."
  fi
  
  if [[ "$EVALUATE_ONLY" != "Y" && ( "$COUNT_UPDATE" -gt 0 || "$FORCE_RESTART" = "Y" ) ]]; then

    echo
    libAction "Testing if database is under blackout" "$I1"
    if ! $MF_BIN/mfEmBlackout.sh -m $MF_MIGRATION_ID -r -A IS_ON -n </dev/null >/dev/null 2>&1
    then
      echo "No Blackout"
      libAction "Start Blackout (00:30), until : $(date -d "now + 30 minutes")"  "$I2"
      if $MF_BIN/mfEmBlackout.sh -m $MF_MIGRATION_ID -r -A START -d "00:30" -n </dev/null >/dev/null 2>&1
      then
        echo Ok
      else
        echo Error
        die "Unable to create blackout"
      fi
      # $MF_BIN/mfEmBlackout.sh -m $MF_MIGRATION_ID -r -A IS_ON -n </dev/null >/dev/null 2>&1 || die "Blackout not active (error creating it)"
    else
      echo "Active blackout"
    fi

    if [ "$FORCE_RESTART" = "Y" ]; then
      
      infoAction "Restart in rolling mode is possible" "$B2"
      
      echo
    
    fi 
    
    ## Backup updated spfile to quick fix ORA-00821
    remoteCommand=$(cat <<%%
echo "Target host is : \$(hostname -f)"
$envCommand
echo "Environment variables are :"
env | grep "^ORA"
echo "Creating backup from updated spfile :"
echo "/tmp/$CDB_UNIQUE_NAME.updated.ora"
sqlplus -s / as sysdba <<SQL_AT_TARGET | egrep -v "^\$"
create pfile='/tmp/$CDB_UNIQUE_NAME.updated.ora' from spfile;
SQL_AT_TARGET
%%
)

    exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHostAvailable" "oracle" "$remoteCommand" \
      "Creating backup from updated spfile" "$I2" || die "Unable to create a backup from updated spfile"
    
    exitCode=0

    remoteCommand=$(cat <<%%
$envCommand
srvctl status database -d \$ORACLE_UNQNAME
%%
)

    if [ $ROLLING_MODE = "Y" ]
    then

      # Restart database (rolling mode)

      mfRepo_updateProgress RESTART_ROLLING
      resultCommand=$(exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHostAvailable" "oracle" "$remoteCommand" "Checking the number of running instances" "$I2")
      echo "$resultCommand"

      echo

      if [ $(echo "$resultCommand" | grep -i 'is running' | wc -l | tr -d ' ') -gt 1 ]
      then
        rollingRestart=1
        infoAction "Restart in rolling mode is possible" "$B2"
      else
        rollingRestart=0
        if [ $(echo "$resultCommand" | grep -i 'instance' | wc -l | tr -d ' ') -gt 0 ]
        then
          infoAction "Restart in rolling mode is possible but only 1 instance is running" "$B2"
          echo

          remoteCommand=$(cat <<%%
$envCommand
srvctl start database -d \$ORACLE_UNQNAME
srvctl status database -d \$ORACLE_UNQNAME
%%
)

          exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHostAvailable" "oracle" "$remoteCommand" "Starting non running instances" "$I3"
          echo
          remoteCommand=$(cat <<%%
$envCommand
srvctl status database -d \$ORACLE_UNQNAME
%%
)

          resultCommand=$(exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHostAvailable" "oracle" "$remoteCommand" "Checking the number of running instances" "$I3")
          echo "$resultCommand"
          echo
          if [ $(echo "$resultCommand" | grep -i 'is running' | wc -l | tr -d ' ') -gt 1 ]
          then
            rollingRestart=1
            infoAction "Restart in rolling mode is now possible" "$B3"
          else
            infoAction "Restart in rolling mode is still not possible" "$B3"
            infoAction "Please, restart database in non rolling mode (downtime)" "$B3"
            rollingRestart=0
          fi

        else
          infoAction "Restart in rolling mode is not possible" "$B2"
          infoAction "Please, restart database in non rolling mode (downtime)" "$B2"
        fi
      fi

      if [ $rollingRestart -eq 1 ]
      then
        for tgtHost in $CDB_CLUSTER_HOSTS
        do
          echo
          remoteCommand=$(cat <<%%
$envCommand
echo "    - HOST=\$(hostname -f)"
echo "      - DATABASE=\$ORACLE_UNQNAME"
echo "      - ORACLE_SID=\$ORACLE_SID"
echo "        - Database status"
srvctl status database -d \$ORACLE_UNQNAME -v
echo "        - Stop the instance"
srvctl stop instance -d \$ORACLE_UNQNAME -i \$ORACLE_SID -f
sleep 5
echo "        - Database status"
srvctl status database -d \$ORACLE_UNQNAME -v
if [ -n "\$(srvctl status database -d \$ORACLE_UNQNAME | grep -i \$ORACLE_SID | grep -i 'is running')" ]; then
  echo "Error : Instance \$ORACLE_SID is not stopped correctly !"
  exit 1
fi
echo "        - Start the instance"
srvctl start instance -d \$ORACLE_UNQNAME -i \$ORACLE_SID
sleep 5
echo "        - Database status"
srvctl status database -d \$ORACLE_UNQNAME -v
if [ -z "\$(srvctl status database -d \$ORACLE_UNQNAME | grep -i \$ORACLE_SID | grep -i 'is running')" ]; then
  echo "Error : Instance \$ORACLE_SID is not started correctly !"
  exit 1
fi
%%
)

          exec_on_target -verbose "${MF_SUDOER:-opc}@$tgtHost" "oracle" "$remoteCommand" \
                          "Restart database instance on node $tgtHost" "$I2"
          if [ $? -ne 0 ]
          then
            exitCode=1
            echo
            echo "Unable to restart database instance, trying to revert changes ..."

            DGDATA="DATAC1"

            remoteCommand=$(cat <<%%
$envCommand
asmcmd --privilege sysdba ls | grep -i DATAC | head -1 | cut -d '/' -f1
%%
)
            resultCommand=$(exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHostAvailable" "oracle" "$remoteCommand" "Checking diskgroup on $remoteHostAvailable" "$I2")

            DGDATA=$(echo "$resultCommand" | grep -i DATAC | cut -d '|' -f2 | tr -d ' ')
            
            echo "Parameter file will be restored in \"${DGDATA}\" diskgroup"

            remoteCommand=$(cat <<%%
$envCommand
sqlplus -s / as sysdba <<SQL_AT_TARGET
shutdown immediate;
shutdown abort;
startup nomount pfile='/tmp/$CDB_UNIQUE_NAME.ora'
create spfile='+$DGDATA' from pfile='/tmp/$CDB_UNIQUE_NAME.ora';
shutdown immediate;
SQL_AT_TARGET
echo "        - Start the instance"
srvctl start instance -d \$ORACLE_UNQNAME -i \$ORACLE_SID
sleep 5
echo "        - Database status"
srvctl status database -d \$ORACLE_UNQNAME -v
if [ -z "\$(srvctl status database -d \$ORACLE_UNQNAME | grep -i \$ORACLE_SID | grep -i 'is running')" ]; then
  echo "Error : Instance \$ORACLE_SID is not started correctly !"
  exit 1
fi
%%
)

            exec_on_target -verbose "${MF_SUDOER:-opc}@$tgtHost" "oracle" "$remoteCommand" \
                          "Restart database instance on node $tgtHost" "$I2"
            if [ $? -ne 0 ]
            then
              exitCode=2
              echo "Unable to restart database instance, after revert changes on parameters ..."
              ### CBI - On ne met un break qu'en cas de KO sur le retour arrière, sinon on redémarre toutes les instances..
              ### CBI - Car il se peut que certains paramètres persistent en mémoire et comme l'accès se fait à travers le scan, les valeurs remontées pourrait ne pas être les valeurs initiales..
              ### CBI - Attention aux interruptions du script après modification des paramètres mais avant redémarrage des instances..
              break
            fi
          fi
        done
      fi

    else
      # Restart database (no rolling mode)
      mfRepo_updateProgress RESTART_NON_ROLLING
      remoteCommand=$(cat <<%%
$envCommand
echo "    - HOST=\$(hostname -f)"
echo "      - DATABASE=\$ORACLE_UNQNAME"
echo "      - ORACLE_SID=\$ORACLE_SID"
echo "        - Database status"
srvctl status database -d \$ORACLE_UNQNAME -v
echo "        - Stop the database"
srvctl stop database -d \$ORACLE_UNQNAME
sleep 5
echo "        - Database status"
srvctl status database -d \$ORACLE_UNQNAME -v
if [ -n "\$(srvctl status database -d \$ORACLE_UNQNAME | grep -i 'is running')" ]; then
  echo "Error : Database \$ORACLE_UNQNAME is not stopped correctly !"
  exit 1
fi
echo "        - Start the database"
srvctl start database -d \$ORACLE_UNQNAME
sleep 5
echo "        - Database status"
srvctl status database -d \$ORACLE_UNQNAME -v
if [ -z "\$(srvctl status database -d \$ORACLE_UNQNAME | grep -i 'is running')" ]; then
  echo "Error : Database \$ORACLE_UNQNAME is not started correctly !"
  exit 1
fi
%%
)

      output=$(exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHostAvailable" "oracle" "$remoteCommand" \
                              "Restart complete database on node $remoteHostAvailable" "$I2")
      
      retCode=$?
      
      echo
      echo "$output"
      
      if [ $retCode -ne 0 ]
      then
        exitCode=1
    
#      outputErr=$(echo "$output" | grep 'ORA-00821')
#
#      if [[ -n "$outputErr" ]]; then
#      
#        specifiedSGA=$(echo "$outputErr" | grep -oP 'sga_target \K[0-9]+[KMGTP]' | head -1)
#        minimumSGA=$(echo "$outputErr" | grep -oP 'least \K[0-9]+[KMGTP]' | head -1)
#        
#        echo "An error \"ORA-00821\" has been identidied"
#        echo "Trying to fix the issue by adjusting the sga_target value"
#        echo "Specified sga_target : $specifiedSGA"
#        echo "Minimum sga_target required : $minimumSGA"
#        
#        minimumSGAValue=${minimumSGA%[KkMmGgTt]}
#        minimumSGAUnit=${minimumSGA##*[0-9]}
#        
#        case "$minimumSGAUnit" in
#            "")  minimumSGAMB=$((minimumSGAValue / 1024 / 1024)) ;;
#            [Kk]) minimumSGAMB=$((minimumSGAValue / 1024)) ;;
#            [Mm]) minimumSGAMB=$minimumSGAValue ;;
#            [Gg]) minimumSGAMB=$((minimumSGAValue * 1024)) ;;
#            [Tt]) minimumSGAMB=$((minimumSGAValue * 1024 * 1024)) ;;
#            *) minimumSGAMB=$minimumSGAValue ;;
#        esac
#        
#        # Ajout de 100M puis arrondi à 512M suppérieur pour éviter un end of file communication channel dans certains cas..
#        minimumSGARounded=$((minimumSGAMB + 100))
#        minimumSGARounded=$(( ((minimumSGARounded + 512 - 1) / 512) * 512 ))
#        minimumSGARounded="$(( ((minimumSGARounded + 512 - 1) / 512) * 512 ))M"
#        
#        echo "Minimum sga_target rounded : ${minimumSGARounded}"
#        
#        echo
#
#        DGDATA="DATAC1"
#
#        remoteCommand=$(cat <<%%
#$envCommand
#asmcmd --privilege sysdba ls | grep -i DATAC | head -1 | cut -d '/' -f1
#%%
#)
#        resultCommand=$(exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHostAvailable" "oracle" "$remoteCommand" "Checking diskgroup on $remoteHostAvailable" "$I2")
#        
#        DGDATA=$(echo "$resultCommand" | grep -i DATAC | cut -d '|' -f2 | tr -d ' ')
#        
#        remoteCommand=$(cat <<%%
#$envCommand
#echo "        - Stop the database"
#sqlplus -s / as sysdba <<SQL_AT_TARGET
#shutdown immediate;
#shutdown abort;
#SQL_AT_TARGET
#echo "        - Update parameters"
#echo "          - Copy pfile /tmp/$CDB_UNIQUE_NAME.updated.ora to /tmp/$CDB_UNIQUE_NAME.fixed.ora"
#cp /tmp/$CDB_UNIQUE_NAME.updated.ora /tmp/$CDB_UNIQUE_NAME.fixed.ora
#echo "          - Values from sga_target before fix"
#egrep -i sga_target /tmp/$CDB_UNIQUE_NAME.fixed.ora
#echo "          - Update values from sga_target"
#sed -i "/__sga_target/I d" /tmp/$CDB_UNIQUE_NAME.fixed.ora
#sed -i "s/^\([*.A-Za-z0-9_]*sga_target[[:space:]]*=\)[[:space:]]*[0-9a-zA-Z]\+/\\1$minimumSGARounded/" /tmp/$CDB_UNIQUE_NAME.fixed.ora
#echo "          - Values from sga_target after fix"
#egrep -i sga_target /tmp/$CDB_UNIQUE_NAME.fixed.ora
#sqlplus -s / as sysdba <<SQL_AT_TARGET
#startup nomount pfile='/tmp/$CDB_UNIQUE_NAME.ora'
#create spfile='+$DGDATA' from pfile='/tmp/$CDB_UNIQUE_NAME.fixed.ora';
#shutdown immediate;
#SQL_AT_TARGET
#echo "        - Start the database"
#srvctl start database -d \$ORACLE_UNQNAME
#sleep 5
#echo "        - Database status"
#srvctl status database -d \$ORACLE_UNQNAME -v
#if [ -z "\$(srvctl status database -d \$ORACLE_UNQNAME | grep -i 'is running')" ]; then
#  echo "Error : Database \$ORACLE_UNQNAME is not started correctly !"
#  exit 1
#fi
#%%
#)
#
#        output=$(exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHostAvailable" "oracle" "$remoteCommand" \
#                            "Restart complete database on node $remoteHostAvailable" "$I2")
#    
#        retCode=$?
#        
#        echo
#        echo "$output"
#    
#        if [ $retCode -ne 0 ]
#        then
#          exitCode=1
#          echo
#          echo "Failed to quick fix SGA issue ..."
#        fi
#      
#      else
#        exitCode=1
#      fi

      
        if [ $exitCode -ne 0 ]; then
          echo "Unable to restart database, trying to revert changes ..."
          DGDATA="DATAC1"
          remoteCommand=$(cat <<%%
$envCommand
asmcmd --privilege sysdba ls | grep -i DATAC | head -1 | cut -d '/' -f1
%%
)
          resultCommand=$(exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHostAvailable" "oracle" "$remoteCommand" "Checking diskgroup on $remoteHostAvailable" "$I2")
          DGDATA=$(echo "$resultCommand" | grep -i DATAC | cut -d '|' -f2 | tr -d ' ')
          echo "Parameter file will be restored in \"${DGDATA}\" diskgroup"
          remoteCommand=$(cat <<%%
$envCommand
sqlplus -s / as sysdba <<SQL_AT_TARGET
shutdown immediate;
shutdown abort;
startup nomount pfile='/tmp/$CDB_UNIQUE_NAME.ora'
create spfile='+$DGDATA' from pfile='/tmp/$CDB_UNIQUE_NAME.ora';
shutdown immediate;
SQL_AT_TARGET
echo "        - Start the database"
srvctl start database -d \$ORACLE_UNQNAME
sleep 5
echo "        - Database status"
srvctl status database -d \$ORACLE_UNQNAME -v
if [ -z "\$(srvctl status database -d \$ORACLE_UNQNAME | grep -i 'is running')" ]; then
  echo "Error : Database \$ORACLE_UNQNAME is not started correctly !"
  exit 1
fi
%%
)

            exec_on_target -verbose "${MF_SUDOER:-opc}@$remoteHostAvailable" "oracle" "$remoteCommand" \
                        "Restart database on node $remoteHostAvailable" "$I2"
            if [ $? -ne 0 ]
            then
              exitCode=2
              echo "Unable to restart database instance, after revert changes on parameters ..."
            fi
          break
        fi
      fi
    fi

    if [ $exitCode -ne 0 ]
    then
      die "Failed to update parameters"
    fi

    echo

    mfRepo_updateProgress UPD_REPO
    #startStep "Run mfGetDbInfo.sh (target) to update the repository"
    libAction "Running mfGetDbInfo.sh (target) to update the repository" "$I2"
    $MF_BIN/mfGetDbInfo.sh -m $MF_MIGRATION_ID -D TGT -n > /dev/null
    if [ $exitCode -eq 0 ]
    then
        echo "Ok"
    else
        echo "Ko"
    fi
  #endStep

  fi

  endStep


done
  
fi

  #forcedOutput OFF

  # ------------------------------------------------------------------------------------------------------

  endRun
