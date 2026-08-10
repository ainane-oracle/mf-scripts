VERSION=1.8
#
# -----------------------------------------------------------------------------
#
#  Generation marker  : MF_DOC_REUSED
#  File               : mfCreateTargetPDB.sh
#
#  Purpose            : Container/Target Pluggable database creation/setup.
#
#  Description        : Initializes the Migration Factory environment, validates the selected
#                       context, and executes the operational workflow for this entry point.
#
#  Functions           : 
#                        - createTheCDB
#                        - detailed_usage
#                        - usage
#
# *****************************************************************************

SCRIPT_LIB="Migration Factory 2.0 : Container/Target Pluggable database creation/setup"
CATEGORY="10-Preparation"
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
#                        mfCreateTargetPDB.sh.
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
#         This script manages the target CDB/PDB for migration factory usage, the scrip not only creates 
#       the database, but it also prepares it for migration factory usage.
#       
#         The script is idempotet and can be run at any time in the migration phase, even after
#       the migration has been done (this use-case is rare, but may exist).
#       
#     
#     The main functions are :
#     
#     - General Checks
#       --------------
#       
#         Milestone check to avoid running is migration started. 
#         
#         Character set control, is the character set of the source is not known, we try to run mfGetDbInfos.sh 
#       on the source to retreive it.
#       
#     - Target CDB creation (BNP restrictions)
#       --------------
#         
#         If the provided CDB service starts with 'MF', the script connect to the target cluster
#       and creates a CDB using dabaascli.
#       
#         See 'Specific cases/variants' for the process implemented with BNP's marketplace
#         
#     - Blackout
#       --------------
#       
#         SInce the process includes restarts, we set a blackout via the script mfEEmBlackout.sh to
#       avoid alerts
#       
#     - Database checks
#       --------------
#       
#         The script checks and fixes the following
#           - Common user prefix (C__ in place of C##)
#           
#     - CDB Setup
#       --------------
#         All these tasks may be modified to fit customer's needs
#         
#         The following setup is done :
#         - database domain removal
#         - Common migration user creation at CDB level
#         - Cdb Compilation, (the script fails if uncompiled objects remains)
#         - Set SGA to 3 Gb if smaller
#         - Set audit_trail to DB
#         - Configure audit
#         
#     - Target PDB creation (BNP restrictions)
#       --------------
#         
#         If the provided PDB name starts with 'MF', the script connect to the target cluster
#       and creates a CDB using dabaascli.
#       
#         See 'Specific cases/variants' for the process implemented with BNP's marketplace
#          
#     - CDB Setup
#       --------------
#         All these tasks may be modified to fit customer's needs
#       
#         The following setup is done :
#         - Create migration user at PDB level or update its privileges if non existent
#         - Set parameters for migration
#         - Removes the global name if any
#         - Creates a temporary tablespace for migration
#         - Enforce BIGFILES to be autoextendable
#         - last compilation and checks
#         
#     - Update the repository
#       --------------
#       
#         Write target information in the repository for the migration
#         
#         
#   - Specific cases/variants
#     =======================
#     
#         BNP Market place Database creation
#         
#         At BNP, the CDB/PDBS must be created by the market place vian an API. This 
#       creation processis coded in the mfSpecificfunctions./BNP.sh and is described ther, 
#       basically it consists in :
#       
#         - Request a PDB creation, which is generally refused because there are no 'migration' 
#           CDBs available
#         - Determine a suitable cluster based on the BU and the environment, we query ORAREF 
#           to determine where to put the CDB
#         - Wait for the CDB to be created (automatic restarts are done since the creation 
#           process often fails)
#         - Request a PDB which will go in the newly created CDB
#         - Wait for the PDB to be created (automatic restarts are done since the creation 
#           process often fails)
#       
#         The rest of the process is the one above. At the end of marketplace PDB creation, 
#       an ultimate restart of the script is done to run the setup steps.
#     
#   - Knonwn Issues/Evolutions needed
#     ===============================
#
#         Sometimes, marketplace operation fails, in this case, you may have additionale informations
#       by directly accessing the swagger of the orchestrator. A direct link is available in the
#       migration attempt définition pop-up.
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

    Container/Target Pluggable database creation/setup.

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

      - password ID
      - password
      - Initialization
      - Analyze parameters
      - Set general dependent variables
      - Set script specific variables
      - Preliminary verifications
      - Unknown character set, try run getDbinfo.sh and re-test
      - GetDbInfo step is
      - Step has been run, get its return code
      - Number of lines
      - Permanently delete
      - ==> Fix the password
      - Testing if database is under blackout

  Integration points
  ==================

    The script interacts with or delegates work to:

      - mfEmBlackout.sh
      - GoldenGate
      - DBMS_AUDIT_MGMT

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
# #                        mfCreateTargetPDB.sh.
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
#  $(basename $0) -m MIGRATION_ID [-O options] [-F] [-Q|-V] [-n] [-h|-?] [-T try]
#
#      $SCRIPT_LIB
#          
#      Prepare the target PDB for migration factory usage. If the CDB does not exists
#   it is created via the marketplace or directly if its name begins with MF. Then, 
#   initialization and preparation is performed. 
#   
#      For marketplace creations, some operations need to be retried, if the scipt fails on
#   one of these operations, it is automatically restarted aftyer $RESTART_DELAY minutes 
#   (up to $MAX_TRYS retrys allowed)
#   
#      This script can be run multiple times, it does not run already run actions
#
#   Parameters :
#   ==========       
#          -m MIGRATION_ID  : ID of the migration (base name for files)  MANDATORY
#          -F               : Force CDB creation (in marketplace mode)
#          -N               : Do not restart the database
#          -O options       : Various options (NCHAR= CPU= RAM= ...)
#          -Q               : Quiet mode (remove progress output)
#          -V               : Print all loging information
#          -T num           : Try number (interanl)
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
  Container/Target Pluggable database creation/setup.

Required:
  -m MIGRATION_ID        : ID of the migration (base name for files).

Options:
  -F                     : Force CDB creation (in marketplace mode).
  -T num                 : Try number (interanl).
  -O options             : Various options (NCHAR= CPU= RAM= ...).
  -N                     : Do not restart the database.
  -Q                     : Quiet mode (remove progress output).
  -V                     : Print all logging information.
  -n                     : Disable log output.
  -h, -?                 : Show this help and exit.
  --help                 : Show this help plus the detailed usage section and exit.

Examples:
  $(basename "$0") -m MIGRATION_ID
$(basename "$0") -m MIGRATION_ID -T num

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
#  Function            : createTheCDB
#
#  Description         : Performs the create The CDB step used by
#                        mfCreateTargetPDB.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Run remote operations on the configured host when required.
#                        - Iterate over the selected objects or command output.
#                        - Parse command output to derive status or generated values.
#
#  Possible issues     : 
#                        - Remote operations depend on SSH access and the configured target
#                          account.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

createTheCDB()
{
  #die "DO NOT CREATE MF Databases for now"
  startStep "Create a test Container Database $CDB_NAME"
  mfRepo_updateProgress CRE_CDB
  echo
  echo "                   The database is named MF%, this is a test database, it will be"
  echo "              created automatically, please allow 20-30 minutes for the creation to complete"
  echo
  echo "      - CHARACTER SET : $MF_SOURCE_CS"
  echo "      - SGA           : 3GB"
  echo
  passwordID="${CDB_NAME}_$(echo "${TARGETCONTAINERDATABASE_CONNECTIONDETAILS_HOST}" | cut -f1 -d".")"
  libAction "password ID" "$I1"; echo $passwordID
  CDBPass=$(getSecretPassword "MANUALCDB" "$passwordID")
  # libAction "password" "$I1" ; echo $CDBPass
remoteCommand=$(cat <<%%
if [ ! -f /home/oracle/$CDB_NAME.env ]
then
  echo "Launching dbaascli command"
  home=\$(dbaascli system getDBHomes | egrep "homePath" | tail -1 | sed -e "s;^.*: \\\";;" -e "s;\\\".*;;")
  echo "$CDBPass
$CDBPass
$CDBPass
$CDBPass" | dbaascli database create --dbName $CDB_NAME --dbUniqueName $TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME --oracleHome \$home --sgaSizeInMB 3092 --dbCharset $MF_SOURCE_CS
else
  echo "Database already exists"
fi
%%
)
# echo "$remoteCommand"

   infoAction "Run command on root via ${MF_SUDOER:-opc}@$databaseHost"
   exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "root" "$remoteCommand" \
                  "Create the $CDB_NAME test CDB" "$I3" || die "Unable to create the target CDB"
   endStep
}

# changeCommonUserPrefix
# {
   # remoteCommand=$(cat <<%%
# if [ ! -f /home/oracle/$CDB_NAME.env ]
# then
# echo "Unable to find the env file for $CDB_NAME"; exit 1 ;
# else
# . \$HOME/$CDB_NAME.env

# sqlplus -s / as sysdba <<SQL_AT_TARGET
# alter system set common_user_prefix=C__ scope=spfile sid='*';
# SQL_AT_TARGET

# srvctl stop database -db \$ORACLE_UNQNAME
# srvctl start database -db \$ORACLE_UNQNAME
# fi
# %%
# )

# echo "$remoteCommand"

   # infoAction "Run command on oracle via ${MF_SUDOER:-opc}@$databaseHost"
   # exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                  # "Change the common_user_prefix to 'C__'" "$I3" || die "Unable to change common_user_prefix"

# }


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
  for s in $SCRIPT_DIR/mfUtils_[0-9][0-9]_*.sh
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
  NUM_TRY=1
  MAX_TRYS=10
  RESTART_DELAY=15                           # Delay in munutes to next try 
  ALLOW_RESTART=Y
  
  while getopts :m:FT:O:NQVnh opt
  do
    case $opt in
     # --------- Script parameters ---------------------------------------------
     F) FORCE_CDB=Y                                   ; toShift=$(($toShift + 1)) ;;
     N) ALLOW_RESTART=N                               ; toShift=$(($toShift + 1)) ;;
     T) NUM_TRY=${OPTARG}                             ; toShift=$(($toShift + 2)) ;;
     O) OPTIONS=${OPTARG}                             ; toShift=$(($toShift + 2)) ;;
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

  startStep "Preliminary verifications"
  mfSetGlobalEnv
  mfSetConnectStrings                                        # Build connection strings
  mfTestDatabaseConnections                                  # Tests all the database connections (must be OK to continue)

  [ "$MF_BYPASS_MLS" != "Y" ] && dieIfCurrentMilestoneIs "ge" 241  0                         # Exit Without error if current milestone is greater or equals to 241 Go for Switch


  if [ "$MF_SOURCE_CS" = "" ] 
  then
    if [ "$MF_REPO_CONNECT" = "" ]
    then
      die "Unknown character set, run getDbinfo.sh on source first (from the UI)"
    else
      infoAction "Unknown character set, try run getDbinfo.sh and re-test" "$I1"
      libAction "GetDbInfo step is" "$I2"
      step_id=$(exec_sql "$MF_REPO_CONNECT" "select to_char(mstep_id) from migration_steps where mig_id=$MFAUTO_MIG_ID and global_step_code='110-PRE_GET_INFO_SRC';") || die "Unable to get the step ID for mfGetDbInfo.sh\n$step_id"
      echo $step_id
      mfRepo_updateProgress "RUN_getDbInfo"
      exec_sql "$MF_REPO_CONNECT" "
                                   exec mf_utils_context_mgmt.setOriginatingUser('$MFAUTO_APEX_USER');
                                   exec mf_mig_actions.launchMigrationStep($step_id,true,false)" "Run GetDbInfo.sh (mstep_id=$mstep_id)" "$I3"
      if [ $? -eq 0 ]
      then
        libAction "Step has been run, get its return code" "$I3"
        rc="$(exec_sql "$MF_REPO_CONNECT" "select to_char(return_code)
                                          from v_migration_step_last_execs
                                          where mstep_id = $step_id ;")"
        [ "$rc" = "0" ] && echo "Success ($rc)" || { echo "Failure ($rc)" ; die "Unable to run mfGetDbInfo, database creation aborted" ; }
        MF_SOURCE_CS=$(exec_sql "$MF_REPO_CONNECT" "select source_value from db_nls_parameters where parameter='NLS_CHARACTERSET' and db_id=$MFAUTO_DB_ID and rownum=1;")
        [ "$MF_SOURCE_CS" = "" ] && die "Source character set still unknown, please check before restarting"        
      else
        die "Unable to run mfGetDbInfo.sh from the migration factory, please run manually"
      fi
    fi
  fi

  [  "$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME" = "DUMMY" -o "$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME" = "TONOTCREATE" -o "$TARGETDATABASE_CONNECTIONDETAILS_SERVICENAME" = "DUMMY" -o "$TARGETDATABASE_CONNECTIONDETAILS_SERVICENAME" = "TONOTCREATE" ] && die "Migration attempt manually set to DO NOT CREATE, please set target informations to 'TOCREATE' if you want to."

  if [ "$TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME" = "TOCREATE" -o "$TARGETDATABASE_CONNECTIONDETAILS_SERVICENAME" = "TOCREATE" ]
  then
    #
    #    The CDB will be created via the customer's specific procedure, ate the end of the creation
    #  Re repository wil be updated with the real CDB name
    #
    #    see corresponding functions in the scustomer's specific script. mfSpecificFunctuions.XXX.sh
    #
    mfCustomCreateCDB_PDB "$OPTIONS" || die "Error when creating the CDB with customer's procedures"
    mfSetConnectStrings                                        # Build connection strings
    mfTestDatabaseConnections                                  # Tests all the database connections (must be OK to continue)
  fi

  NAMING=""
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
    NAMING="BNP"
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

  endStep 

  # ------------------------------------------------------------------------------------------------------
  #
  #   After this line, all output is printed, even if the -Q has been used
  #
  forcedOutput ON
  
  # fixPasswordIssues # Trouver un autre endroit, là, c'est pas bon!!
  
  
  infoAction "Check if we have several lines in keepass for $CDB_NAME" "$I1"
  lines=$(keepassxc-cli ls -k $MF_PW_KEY $MF_PW_DATABASE  --no-password | grep $CDB_NAME)
  nb=$(echo "$lines" | wc -l)
  libAction "Number of lines" "$I2"
  echo $nb
  if [ $nb -ge 2 ]
  then
    for l in $lines
    do
      PASS_TYPE=$(echo "$l" | cut -f1 -d"|")
      PWD_ID=$(echo "$l" | cut -f2 -d"|")
      case $PWD_ID in
        ${TARGETCONTAINERDATABASE_ADMINUSERNAME}*) : ;;
        *) 
          libAction "Delete password  $PASS_TYPE|${PWD_ID} before update" "$I4"
          res=$(keepassxc-cli rm -k $MF_PW_KEY $MF_PW_DATABASE "$PASS_TYPE|${PWD_ID}" --no-password 2>&1)
          if [ "$(echo "$res" | grep -i "recycled")" != "" ]
          then
            echo "Recycled"
            libAction "Permanently delete" "  $I4"
            res=$(keepassxc-cli rm -k $MF_PW_KEY $MF_PW_DATABASE "$PASS_TYPE|${PWD_ID}" --no-password 2>&1)
            if [ "$(echo "$res" | grep -i "deleted")" != "" ]
            then
              echo "Deleted"
            fi
          fi
          continue ;
          ;;
      esac
      libAction "Check password for $PWD_ID" "$I3"
      p=$(getSecretPassword "$PASS_TYPE" "$PWD_ID")
      if [ "$p" != "$MF_TGT_CDB_PASSWORD" ]
      then
        echo "Incorrect"
        infoAction "==> Fix the password" "$B3"
        MF_FIXED_PASSWORD=$MF_TGT_CDB_PASSWORD
        #
        #    Delete password before recreating password
        #
        libAction "Delete password  $PASS_TYPE|${PWD_ID} before update" "$I4"
        res=$(keepassxc-cli rm -k $MF_PW_KEY $MF_PW_DATABASE "$PASS_TYPE|${PWD_ID}" --no-password 2>&1)
        if [ "$(echo "$res" | grep -i "recycled")" != "" ]
        then
          echo "Recycled"
          libAction "Permanently delete" "  $I4"
          res=$(keepassxc-cli rm -k $MF_PW_KEY $MF_PW_DATABASE "$PASS_TYPE|${PWD_ID}" --no-password 2>&1)
        fi
        if [ "$(echo "$res" | grep -i "deleted")" != "" ]
        then
          echo "Deleted"
        elif [  "$(echo "$res" | grep -i "not found")" != "" ]
        then
          echo "Non existent"
        else
          die "ERROR: Unknown state"
        fi
        getSecretPassword $PASS_TYPE $PWD_ID >/dev/null
        libAction "" "$B4" ; echo "Password changed/created"
        MF_FIXED_PASSWORD=
      else
        echo "Correct"
      fi    
    done
  fi

  #
  #   Setting up the blackout
  #
  #infoAction "Setting blackout for target database : $CDB_UNIQUE_NAME" "$I2" 
  #.$SCRIPT_DIR/mfEmBlackout.sh -m $MF_MIGRATION_ID -r -A start
  mfRepo_updateProgress BLACKOUT
  libAction "Testing if database is under blackout" "$I1"
  if ! $MF_BIN/mfEmBlackout.sh -m $MF_MIGRATION_ID -r -A IS_ON -n </dev/null >/dev/null 2>&1
  then
    echo "No Blackout"
    libAction "Start blackout until planned GO-LIVE + 2 hours" "$I2"
    
    if $MF_BIN/mfEmBlackout.sh -m $MF_MIGRATION_ID -r -A START -n </dev/null >/dev/null 2>&1
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

  #
  #  Find the first accessible DB HOST (if not dertermined before)
  #
  if [ "$databaseHost" = "" ]
  then
    databaseHost=$( mfGetDbSshHost "$MF_TGT_CLUSTER_HOSTS") || die "Unable to find a host accepting ssh"
  fi
  
  libAction "Checking primary UNIQUE Name" "$I2"
  primary=$(exec_on_target -tty "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$(cat <<%%
  . $CDB_NAME.env || exit 1
  dgmgrl / "show Configuration" | grep "Primary database" | awk '{print \$1}'
%%
)")
  echo "$primary"
  if [ "$primary" != "" -a "$primary" != "$CDB_UNIQUE_NAME" ]
  then
    exec_sql "$MF_REPO_CONNECT" "
    update 
      migration_attempts ma
    set 
      target_container_service='$primary'
      ,tclu_id=(select peer_tclu_id
                from   target_clusters
                where  tclu_id = ma.tclu_id)
    where
      mig_id='$MFAUTO_MIG_ID' ;" "Updating migration attempt to peer database" "$I1" || die "Unable to update migration_attempt"    
    die "Primary is not $CDB_UNIQUE_NAME, migration attempt modified restart the step"
  fi

  infoAction "$databaseHost hosts the primary ($primary) create the services" "$I2"
  createServices PRIMARY $databaseHost
  
  if [ "$tgtCDB" = "OK" ]
  then
    libAction "Target CDB accessible get its CHARSET" "$I1"
    tgtCS=$(exec_sql "$MF_TGT_CDB_CONNECT" "select value from v\$nls_parameters where parameter = 'NLS_CHARACTERSET';")
    echo $tgtCS
    if [ "$tgtCS" = "$MF_SOURCE_CS" ]
    then
      infoAction "Character set is correct, can use this CDB" "$I2"
      cdbOK="Y"
    else
      infoAction "Character set is NOT correct, CANNOT use this CDB" "$I2"
      cdbOK="N"
    fi
  else
    libAction "Target CDB NOT ACCESSIBLE (will be created if MF%)" "$I1"
    cdbOK="N"
  fi

  if [ "$cdbOK" != "Y" ]
  then
    case $CDB_NAME in
      MF*) createTheCDB "$OPTIONS"    ;;
      *) echo "Assume the CDB exists" ;;
    esac
  else
    echo
    libAction "The container database will be used" "$I1"
    echo $CDB_NAME
  fi

  echo
  
  [ "$MF_TGT_CDB_USER" = "" ] && die "Target CDB migration user is null, please fix the Migration Attempt definition"
  [ "$MF_TGT_CDB_USER" = "N/A" ] && die "Target CDB migration user=$MF_TGT_CDB_USER, please fix the Migration Attempt definition"
  [ "$MF_TGT_CDB_USER" = "N/A" ] && die "Target CDB migration user=$MF_TGT_CDB_USER, please fix the Migration Attempt definition"
  [ "$MF_TGT_CDB_USER" = "DUMMY" ] && die "Target CDB migration user=$MF_TGT_CDB_USER, please fix the Migration Attempt definition"

  [ "$MF_TGT_PDB_USER" = "" ] && die "Target PDB migration user is null, please fix the Migration Attempt definition"
  [ "$MF_TGT_PDB_USER" = "N/A" ] && die "Target PDB migration user=$MF_TGT_CDB_USER, please fix the Migration Attempt definition"
  [ "$MF_TGT_PDB_USER" = "DUMMY" ] && die "Target PDB migration user=$MF_TGT_CDB_USER, please fix the Migration Attempt definition"
  
# if mfDbIs_PRIMARY
# then
    
  
  libAction "Check common_user_prefix value" "$I1" 
  mfRepo_updateProgress CHECK
    tgtCUP=$(exec_on_target -tty "${MF_SUDOER:-opc}@$databaseHost" "oracle" ". $CDB_NAME.env || exit 1
    echo \"
    set pages 0
    select value from v\\\\\$parameter where name = 'common_user_prefix';\" | sqlplus -s / as sysdba") 
  # tgtCUP=$(exec_sql "$MF_TGT_CDB_CONNECT" "set pagesize 0
# set linesize 100
# select value from v\$parameter where name = 'common_user_prefix';" | grep -v "^$" | tr -d ' ')
  echo $tgtCUP
  
  if [ "$(echo "$tgtCUP" | grep "ORA-12514")" != "" ]
  then  
    createServices PRIMARY $databaseHost
    libAction "Check common_user_prefix value" "$I1" 

    mfRepo_updateProgress CHECK

    tgtCUP=$(exec_on_target -tty "${MF_SUDOER:-opc}@$databaseHost" "oracle" ". $CDB_NAME.env || exit 1
    echo \"
    set pages 0
    select value from v\\\\\$parameter where name = 'common_user_prefix';\" | sqlplus -s / as sysdba")
    # tgtCUP=$(exec_sql "$MF_TGT_CDB_CONNECT" "set pagesize 0
  # set linesize 100
  # select value from v\$parameter where name = 'common_user_prefix';" | grep -v "^$" | tr -d ' ')
    echo $tgtCUP
  fi
  # if [ "${tgtCUP^^}" != "C__" ]; then
    # case $CDB_NAME in
      # MF*) changeCommonUserPrefix ;;
      # *) infoAction "Assume the common_user_prefix is in the expected value" "$I2" ;;
    # esac
  # else
    # infoAction "The common_user_prefix is in the expected value" "$I2"
  # fi
  libAction "Check if migration CDB user exists" "$I2" 
    cdb_user_exists=$(exec_on_target -tty "${MF_SUDOER:-opc}@$databaseHost" "oracle" ". $CDB_NAME.env || exit 1
    echo \"
    set pages 0
    select to_char(count(*)) from dba_users where username='$TARGETCONTAINERDATABASE_ADMINUSERNAME';\" | sqlplus -s / as sysdba") || die "Unable to check for CDB user existence"
  mfDebugLog "cdb_user_exists=$cdb_user_exists"
  # cdb_user_exists=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(count(*) from dba_users where username='$TARGETCONTAINERDATABASE_ADMINUSERNAME';")
  if [ "$cdb_user_exists" = "0" ]
  then
    echo "Not exists"
    user_prefix=$(echo "$TARGETCONTAINERDATABASE_ADMINUSERNAME" | cut -c1-3 | tr '[a-z]' '[A-Z]')
    if [ "$user_prefix" != "${tgtCUP^^}" ]
    then
      old_user=$TARGETCONTAINERDATABASE_ADMINUSERNAME
      TARGETCONTAINERDATABASE_ADMINUSERNAME="${tgtCUP^^}$(echo "$TARGETCONTAINERDATABASE_ADMINUSERNAME" | cut -c4-20)"
      MF_TGT_CDB_CONNECT="${tgtCUP^^}$(echo "$MF_TGT_CDB_CONNECT" | cut -c4-1000)"
      infoAction "Renaming CDB user to $TARGETCONTAINERDATABASE_ADMINUSERNAME" "$I3"
      infoAction "Saving password to keepass" "$I3"
      usr=${TARGETCONTAINERDATABASE_ADMINUSERNAME}
      hst=${TARGETCONTAINERDATABASE_CONNECTIONDETAILS_HOST}
      svc=${TARGETCONTAINERDATABASE_CONNECTIONDETAILS_SERVICENAME}
      prt=${TARGETCONTAINERDATABASE_CONNECTIONDETAILS_PORT}
      typ=DB_USER
      libAction "Password ID" "$I4"
      cnxName=$(mfConnectName $usr $hst $svc)
      echoForLog "$typ $cnxName"
      MF_FIXED_PASSWORD=$MF_TGT_CDB_PASSWORD
      pass=$(getSecretPassword $typ $cnxName TARGET)
      MF_FIXED_PASSWORD=""
      exec_sql "$MF_REPO_CONNECT" "update migration_attempts set target_container_admin_user='$TARGETCONTAINERDATABASE_ADMINUSERNAME' where mig_id=$MFAUTO_MIG_ID;" "Updating username in REPO" "$I3"
    fi
  else 
    echo "Exists (nothing to do)"
  fi
  startStep "Create target PDB if it does not exists"
  infoAction "Target database host is : $databaseHost" "$I2" 
  mfRepo_updateProgress VALID_CDB
  echo
  libAction "Determine on which system the target is running" "$I2"
  if ssh -o StrictHostKeyChecking=no ${MF_SUDOER:-opc}@$databaseHost test -f /opt/oracle/dcs/bin/dbcli #2>/dev/null
  then
    targetSystem=DBSYSTEM
  else
    targetSystem=EXADATA
  fi
  echo $targetSystem
  
  if [ "$MF_TGT_SYS_AVAILABLE" = "N" ]
  then
    infoAction "SYS user is not available at target, trying with migration User" "$I2"
    echo
    MF_TGT_CDB_SYS_CONNECT=$MF_TGT_CDB_CONNECT
  fi


   envFile=$(echo "${CDB_NAME}."  | cut -f1 -d".")
   envFile=$(echo "${envFile}_" | cut -f1 -d "_") 
   infoAction "Determine how to set environment for : $envFile" "$I2" 
   if [ "$targetSystem" = "DBSYSTEM" ]
   then
     envCommand=". oraenv <<< $envFile"
   else
     envCommand="[ -f \$HOME/$envFile.env ] && { . \$HOME/$envFile.env ; } \
                 || { echo \"Unable to find the env file\"; exit 1 ; }"
   fi
#  [ -f \$HOME/$envFile.env ] && { . \$HOME/$envFile.env ; } || { echo "Unable to find the env file"; exit 1 ; }
   #
   #     Check if the PDB really belongs to the CDB
   #
  
  libAction "is the DB is running on all nodes" "$I1"
    remoteCommand=$(cat <<%%
  echo " - Set DB environment with $(whoami) user"
  $envCommand
  srvctl status database -d \$ORACLE_UNQNAME | grep -i "not running"
%%
) 
   result=$(exec_on_target -tty "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand")

  if [ "$result" != "" -a "$ALLOW_RESTART" = "Y" ]
  then  
    echo "No"
    remoteCommand=$(cat <<%%
  echo " - Set DB environment with $(whoami) user"
  $envCommand
  srvctl stop database -d \$ORACLE_UNQNAME 
  srvctl start database -d \$ORACLE_UNQNAME 
  srvctl status database -d \$ORACLE_UNQNAME | grep -i "not running" && exit 1 || exit 0
%%
) 
    exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand"  "Bounce target database" "$I2" || die "Unable to start tarrget DB on both nodes"
  else
    
    [ "$result" = "" ] && echo "Yes" || die "DB not started on all nodes and restart not allowed"
  fi
  
    remoteCommand=$(cat <<%%
  echo " - Set DB environment with $(whoami) user"
  $envCommand
  echo "    - ORACLE_UNQNAME=\$ORACLE_UNQNAME"
  echo -e "set head off pages 0\nselect 'PDB_FOUND:' || count(*) from cdb_pdbs where pdb_name='$TARGETDATABASE_CONNECTIONDETAILS_SERVICENAME';" | sqlplus -s / as sysdba
%%
) 
   result=$(exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand")
   pdb_found=$(echo "$result" | grep PDB_FOUND | cut -f2 -d":")
   if [ "$pdb_found" = "1" ]
   then
     infoAction "PDB/CDB are ok, continuing" "$I2"
   elif [ "$pdb_found" = "0" ]
   then
     case $TARGETDATABASE_CONNECTIONDETAILS_SERVICENAME in
       MF*) echo "PDB Will be created by the script" ;;
       *) die "The $CDB_NAME CDB does not contain the $TARGETDATABASE_CONNECTIONDETAILS_SERVICENAME PDB (check attempt definition)" ;;
     esac 
   else
     die "Unable to check that $TARGETDATABASE_CONNECTIONDETAILS_SERVICENAME belongs to $CDB_NAME\n$result"
   fi
   
  remoteCommand=$(cat <<%%
  echo " - Set DB environment with $(whoami) user"
  $envCommand
  echo "    - ORACLE_UNQNAME=\$ORACLE_UNQNAME"
  dbd=\$(echo -e "set head off pages 0\nselect value from v\\\\\$parameter where name='db_domain';" | sqlplus -s / as sysdba)
  echo "    - DB domain=\$dbd"
  if [ "\$dbd" != "" ]
  then
    echo "      - Domain is set, removing it"
    echo -e "alter system set db_domain='' scope=spfile sid='*';" | sqlplus -s / as sysdba
    if [ "$ALLOW_RESTART" = "Y" ]
    then
      echo "      - Stop the database"
      srvctl stop database -d \$ORACLE_UNQNAME
      echo "      - Remove domain from clusterware"
      srvctl modify database -d \$ORACLE_UNQNAME -domain "" 
      echo "      - Start the database"
      srvctl start database -d \$ORACLE_UNQNAME
    else
      echo "Database should be restarted"
    fi
  else
    echo "      - Domain is not set"
  fi
  echo
  echo "    - ----------- \$ORACLE_UNQNAME database configuration ------------------------"
  srvctl config database -d \$ORACLE_UNQNAME
%%
)
   exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                  "Check if target CDB have a db_domain and remove it" "$I2" || die "Unable to get/fix db_domain"

  remoteCommand=$(cat <<%%
$envCommand
sqlplus -s / as sysdba <<SQL_AT_TARGET
whenever sqlerror exit failure
set serveroutput on
DECLARE
   user_CDB NUMBER;
error_code NUMBER := 0;
   stmt varchar2(2000) ;


BEGIN
    SELECT COUNT(*) INTO user_CDB FROM DBA_USERS WHERE USERNAME = UPPER('$TARGETCONTAINERDATABASE_ADMINUSERNAME');
	
    IF user_CDB = 0 THEN
        begin 
          stmt := 'drop profile ' || '$TARGETCONTAINERDATABASE_ADMINUSERNAME' || '_PROFILE';
          dbms_output.put_line (stmt) ; execute immediate stmt ;
        exception when others then null ;
        end ;
        -- Si l'utilisateur n'existe pas, le créer
        stmt := 'CREATE USER  $TARGETCONTAINERDATABASE_ADMINUSERNAME IDENTIFIED BY "$MF_TGT_CDB_PASSWORD"';
        dbms_output.put_line ('CREATE USER  $TARGETCONTAINERDATABASE_ADMINUSERNAME IDENTIFIED BY "XXXXXX"') ; execute immediate stmt ;

        stmt := 'GRANT CONNECT, CREATE SESSION, DBA TO ' || '$TARGETCONTAINERDATABASE_ADMINUSERNAME' ||' container=all';
        dbms_output.put_line (stmt) ; execute immediate stmt ;

        stmt := 'ALTER USER ' || '$TARGETCONTAINERDATABASE_ADMINUSERNAME ' || 'SET container_data=all CONTAINER=CURRENT';
        dbms_output.put_line (stmt) ; execute immediate stmt ;
      
        stmt := 'create profile ' || '$TARGETCONTAINERDATABASE_ADMINUSERNAME' || '_PROFILE limit password_life_time unlimited';
        dbms_output.put_line (stmt) ; execute immediate stmt ;
    else
     dbms_output.put_line ('User Exists');
    END IF;
    
END ;
/
   grant execute on dbms_lock to $TARGETCONTAINERDATABASE_ADMINUSERNAME with grant option ;
   
SQL_AT_TARGET
%%
)

   exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                  "Create the $TARGETCONTAINERDATABASE_ADMINUSERNAME user on target CDB" "$I3" || die "Unable to create the migration user on target CDB"
                  
  echo "MF_TGT_CDB_SYS_CONNECT=$MF_TGT_CDB_SYS_CONNECT"
  echo "MF_TGT_CDB_SYS_CONNECT=$MF_TGT_CDB_CONNECT"
  domain_name="$(exec_sql "$MF_TGT_CDB_SYS_CONNECT" "select value from v\$parameter where name='db_domain';")" || die "Get domain : $domain_name"
  [ "$domain_name" != "" ] && domain_name=".$domain_name"
  infoAction "Search PDB for service : $TARGETDATABASE_CONNECTIONDETAILS_SERVICENAME" "$I3"
  libAction "Domain Name" "$I3"
  echo $domain_name
  
  libAction "Invalid objects in the CDB" "$I3"
  invalidCount=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(count(*)) from dba_objects where status='INVALID' ;")
  echo $invalidCount
  
  if [ "$invalidCount" != "0" ]
  then
remoteCommand=$(cat <<%%
$envCommand
sqlplus -s / as sysdba <<SQL_AT_TARGET
@?/rdbms/admin/utlrp.sql
SQL_AT_TARGET
%%
)
   exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                  "Recompile CDB" "$I4" || die "Unable to recompile objects in the CDB"
    libAction "Invalid objects in the CDB" "$I4"
    invalidCount=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(count(*)) from dba_objects where status='INVALID' ;")
    echo $invalidCount
  fi
  
  [ "$invalidCount" != "0" ] && die "There are $invalidCount INVALID objects in the CDB, please check" 
  
  echo
  dbBounce=N
  libAction "sga_target at the CDB level" "$I2"
  sga_target=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(value) from v\$parameter where name='sga_target' ;")
  echo $sga_target ;
  if [ $sga_target -lt $((3 * 1024 * 1024 * 1024)) ]
  then 
    exec_sql "$MF_TGT_CDB_CONNECT" "
      alter system set sga_target=3G scope=spfile sid='*'  ;
      whenever sqlerror continue
      alter system reset sga_max_size scope=spfile sid='*' ; " "Set SGA to 3 GB" "$I3"
      dbBounce=Y
  fi
  libAction "sga_audit_trail=DB at the CDB level" "$I2"
  audit_trail=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(value) from v\$parameter where name='audit_trail' ;")
  echo $audit_trail ;
  if [ "$audit_trail" != "DB" ]
  then 
    exec_sql "$MF_TGT_CDB_CONNECT" "
      alter system set audit_trail='DB' scope=spfile sid='*'  ;" "Set audit_trail to DB" "$I3"
      dbBounce=Y
  fi
  libAction "Remove pga_aggregate_limit at CDB level" "$I2"
  pga_aggregate_limit=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(value) from v\$spparameter where name='pga_aggregate_limit' ;")
  echo $pga_aggregate_limit ;
  if [ "$pga_aggregate_limit" != "" ]
  then 
    exec_sql "$MF_TGT_CDB_CONNECT" "
      alter system reset pga_aggregate_limit scope=spfile sid='*'  ;" "Remove pga_aggregate_limit" "$I3" && dbBounce=Y || true
  fi
  
  
  libAction "Parallel force local must be true" "$I2"
  parallel_force_local=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(value) from v\$spparameter where name='parallel_force_local' ;")
  echo $parallel_force_local ;
  if [ "$parallel_force_local" != "true" ]
  then 
    exec_sql "$MF_TGT_CDB_CONNECT" "
      alter system set parallel_force_local=true scope=both sid='*'  ;" "Set parallel_force_local=true" "$I3" && dbBounce=N || true
  fi

  libAction "target_pdbs must be 1" "$I2"
  target_pdbs=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(value) from v\$spparameter where name='target_pdbs' ;")
  echo $target_pdbs ;
  if [ "$target_pdbs" != "1" ]
  then 
    exec_sql "$MF_TGT_CDB_CONNECT" "
      alter system set target_pdbs=1 scope=spfile sid='*'  ;" "Set target_pdbs=1" "$I3" && dbBounce=Y || true
  fi
 
  if [ "$dbBounce" = "Y" -a "$ALLOW_RESTART" = "Y" ]
  then
    remoteCommand=$(cat <<%%
$envCommand
    echo "      - Stop the database"
    srvctl stop database -d \$ORACLE_UNQNAME
    echo "      - Start the database"
    srvctl start database -d \$ORACLE_UNQNAME
%%
)
   exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                  "Restart CDB" "$I3" || die "Unable to restart the CDB"
  fi  
    remoteCommand=$(cat <<%%
$envCommand
sqlplus -s / as sysdba <<SQL_AT_TARGET
AUDIT CREATE SESSION;
AUDIT ALTER ANY TABLE;
AUDIT ALTER USER;
AUDIT CREATE ROLE;
AUDIT CREATE USER;
AUDIT DROP ANY PROCEDURE;
AUDIT DROP ANY TABLE;
AUDIT GRANT ANY PRIVILEGE;
AUDIT GRANT ANY ROLE;
AUDIT EXECUTE PROCEDURE;
AUDIT SELECT ANY DICTIONARY;
AUDIT GRANT ANY OBJECT PRIVILEGE BY ACCESS;
AUDIT CREATE LIBRARY;
AUDIT ALL ON sys.aud$ BY ACCESS;

-- SCRIPT: To manage AUD$ table with dbms_audit_mgmt (Doc ID 1362997.1)
BEGIN
  IF NOT DBMS_AUDIT_MGMT.IS_CLEANUP_INITIALIZED(DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD)
  THEN
    DBMS_AUDIT_MGMT.INIT_CLEANUP(audit_trail_type => dbms_audit_mgmt.AUDIT_TRAIL_AUD_STD, default_cleanup_interval => 24*14);
  END IF;
END;
/

-- NOT NECESSSARY. EXPLICIT INSTEAD OF IMPLICIT
BEGIN
  DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION(audit_trail_type => dbms_audit_mgmt.AUDIT_TRAIL_AUD_STD, audit_trail_location_value => 'SYSAUX') ;
END;
/

BEGIN
  DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,last_archive_time => sysdate - 14);
END;
/

BEGIN
  DBMS_AUDIT_MGMT.DROP_PURGE_JOB(AUDIT_TRAIL_PURGE_NAME => 'Exacc_Standard_Audit_Trail_Purge_Job');
EXCEPTION
WHEN OTHERS THEN NULL;
END;
/

BEGIN
  DBMS_AUDIT_MGMT.CREATE_PURGE_JOB (AUDIT_TRAIL_TYPE => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,
  AUDIT_TRAIL_PURGE_INTERVAL => 24,
  AUDIT_TRAIL_PURGE_NAME => 'Exacc_Standard_Audit_Trail_Purge_Job',
  USE_LAST_ARCH_TIMESTAMP => TRUE );
END;
/

CREATE OR REPLACE procedure exacc_set_audit_archive_retention(retention in number default 14) as
BEGIN
  DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(
  audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,
  last_archive_time => sysdate - retention);
END;
/

BEGIN
  DBMS_SCHEDULER.disable('exacc_audit_advance_archive_timestamp');
  DBMS_SCHEDULER.drop_job('exacc_audit_advance_archive_timestamp');
EXCEPTION
WHEN OTHERS THEN NULL;
end;
/

BEGIN
   DBMS_SCHEDULER.create_job (
   job_name => 'exacc_audit_advance_archive_timestamp',
   job_type => 'STORED_PROCEDURE',
   job_action => 'exacc_set_audit_archive_retention',
   number_of_arguments => 1,
   start_date => SYSDATE,
   repeat_interval => 'freq=daily' ,
   enabled => false,
   auto_drop => FALSE);
   DBMS_SCHEDULER.set_job_argument_value(job_name =>'exacc_audit_advance_archive_timestamp', argument_position =>1, argument_value => 14);
   DBMS_SCHEDULER.ENABLE('exacc_audit_advance_archive_timestamp');
END;
/

BEGIN
    DBMS_SCHEDULER.run_job (job_name => 'exacc_audit_advance_archive_timestamp',
    use_current_session => FALSE);
END;
/
SQL_AT_TARGET
%%
)
   exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                  "Configure AUDIT TRAIL" "$I2" || die "Unable to Configure AUDIT TRAIL"

  if [ "$domain_name" = "" ]
  then
    pdb_name="$TARGETDATABASE_CONNECTIONDETAILS_SERVICENAME"
  else
    pdb_name="$(echo "$TARGETDATABASE_CONNECTIONDETAILS_SERVICENAME" | sed -e "s;$domain_name;;")" || die "get pdb_name : $pdb_name"
  fi
  [ "$pdb_name" = "" ] && die "unable to determine the PDB name"

  libAction "Testing for $pdb_name existence" "$I1"
  exists=$(exec_sql "$MF_TGT_CDB_SYS_CONNECT" "select to_char(count(*)) from dba_pdbs where pdb_name=UPPER('$pdb_name') ;") || die "Unable to test PDB $pdb_name existence"
  if [ "$exists" != "0" ]
  then
    echo "Exists"
  else
    echo "Non existent"
    pass=$(getSecretPassword DB_USER admin_pdb_$pdb_name) || die "$pass"
    pass_wallet=$(getSecretPassword DB_WALLET wallet_pdb_$pdb_name) || die "$pass_wallet"
    pass_key=$(getSecretPassword DB_KEY key_pdb_$pdb_name) || die "$pass_key"
    libAction  "Target is" "$I2"

    mfRepo_updateProgress CREATE_PDB
    if [ "$targetSystem" = "DBSYSTEM" ]
    then
      #
      #      target is a DB System, we use dbcli
      #
      echo "DB System"
      DBCLI=/opt/oracle/dcs/bin/dbcli

      #
      #      Get the DBName and execute an action with the API to be sure it works
      #

      CDBName=$(exec_sql "$MF_TGT_CDB_SYS_CONNECT" "select name from V\$database;") || die "Unable to connect to the CDB"
      DRID=$(ssh -o StrictHostKeyChecking=no ${MF_SUDOER:-opc}@$databaseHost sudo -su root $DBCLI describe-database -in $CDBName | grep -i "  ID:" | awk '{print $2}') \
                     || die "Unable to access the database with the API"

      infoAction "Creating the new PDB" "$I2"
      libAction "Launch the create PDB JOB" "$I3"
      #echo ssh ${MF_SUDOER:-opc}@$databaseHost sudo -su root $DBCLI create-pdb -i $DRID -n $pdb_name -p $pass_key -tp $pass_wallet --json 
      command="$DBCLI create-pdb -i $DRID -n $pdb_name -p $pass_key -tp $pass_wallet --json"
#      echo $command
#      echo $pass_wallet
      job=$(ssh -o StrictHostKeyChecking=no ${MF_SUDOER:-opc}@$databaseHost sudo -su root $command | jq -jr '.jobId') || die "Unable to launch the create Job (command=$command)"
      echo $job

      #
      #     The job is a background task, the script needs to wait for completion of the action
      #  30 minutes should be sufficient
      #
      infoAction "Waiting 30 minutes (maximum) for $job to complete" "$I4"
      i=0
      status=XXX
      while [ "$status" != "Success" -a "$status" != "Failure" -a $i -le 180 ]
      do
        #
        #     Get the status and error message from the JSON result
        #
        l=$(ssh -o StrictHostKeyChecking=no ${MF_SUDOER:-opc}@$databaseHost sudo -su root $DBCLI describe-job --jobid  "$job" --json | jq -jr '.|.status,";",.message') || die "Error invoking JOB Status"
        prev_status=$status
        status=$(echo "$l" | cut -f1 -d";")
        message=$(echo "$l" | cut -f2 -d";")
        if [ "$status" != "$prev_status" ]
        then
          #
          #      Print only status changes
          #
          infoAction "       - $status" "$B4"
          continue
        fi
        i=$(($i + 1))
        mfRepo_updateProgress WAIT_$(($i * 10))_SECS
        sleep 10
      done
      [ "$status" != "Success" ] && die "Removal failed ($message)"

    else
      echo "ExaCC"
#      Usage: dbaascli pdb create --pdbName <value> --dbName <value> [--maxCPU <value>] [--maxSize <value>] [--pdbAdminUserName <value>] [--lockPDBAdminAccount <value>] [--resume [--sessionID <value>]] [--executePrereqs] [--waitForCompletion <value>]
      libAction "Get CDB Name" "$I3"
      CDBName=$(exec_sql "$MF_TGT_CDB_SYS_CONNECT" "select name from V\$database;") || die "Unable to connect to the CDB"
      echo $CDBName
      command="dbaascli pdb create --pdbName $pdb_name --dbName $CDBName --waitForCompletion TRUE"
      # echo $command
      libAction "Creating the PDB on ExaCC (dbaascli)" "$I3"
      ssh -o StrictHostKeyChecking=no ${MF_SUDOER:-opc}@$databaseHost sudo -su root $command >$TMPFILE1 2>&1 \
        && { echo Ok ; rm -f $TMPFILE1 ; } \
        || { echo Error ; cat $TMPFILE1 ; rm -f $TMPFILE1 ; die "Error creating the PDB" ; }
    fi         
    
  fi

  echo
  infoAction "Test connections to Migration Users" "$I1"
  mfRepo_updateProgress TEST_CNX

  libAction "CDB Level($TARGETCONTAINERDATABASE_ADMINUSERNAME)" "$I2"
  if exec_sql "$MF_TGT_CDB_CONNECT" "select 1 from dual ;" >/dev/null 2>&1
  then
    echo "Ok" 
  else
    die "Unable to connect to the CDB admin user, and it should not!!!!"
  fi
  
  profile_mig=$(exec_sql "$MF_TGT_CDB_CONNECT" "select profile from dba_profiles where profile like '%MIG_EXACC%' and rownum=1;")
  exec_sql "$MF_TGT_CDB_CONNECT" "
    alter profile $profile_mig limit password_reuse_max unlimited ;
    alter profile $profile_mig limit password_reuse_time unlimited ;
    alter profile $profile_mig limit password_life_time unlimited ;
    Alter user $TARGETCONTAINERDATABASE_ADMINUSERNAME profile $profile_mig ;" \
           "CDB Level($TARGETCONTAINERDATABASE_ADMINUSERNAME) set profile:$profile_mig" "$I2" || die "unable to set no password expiry for $TARGETCONTAINERDATABASE_ADMINUSERNAME"
           
  mfRepo_updateProgress CRE_MIGUSER 
  libAction "PDB Level($TARGETDATABASE_ADMINUSERNAME)" "$I2"
  if exec_sql "$MF_TGT_PDB_CONNECT" "select 1 from dual ;" >/dev/null 2>&1
  then
    echo "Ok"

    remoteCommand=$(cat <<%%
$envCommand
sqlplus -s / as sysdba <<SQL_AT_TARGET
alter session set container=${pdb_name} ;
alter user ${TARGETDATABASE_ADMINUSERNAME} identified by "$MF_TGT_PDB_PASSWORD" account unlock ; 
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
SQL_AT_TARGET
%%
)

    exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                  "Updating privileges to the ${TARGETDATABASE_ADMINUSERNAME} (dba) user on ${pdb_name}" "$I3" || die "Unable to update privileges from migration user on target PDB"

  else
    echo "Non Existent"


#    exec_sql "$MF_TGT_CDB_CONNECT" "
#    alter session set container=$pdb_name ;
#    create profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE limit password_life_time unlimited ;
#    create user $TARGETDATABASE_ADMINUSERNAME profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE identified by \"$MF_TGT_PDB_PASSWORD\" ;
#    grant dba to $TARGETDATABASE_ADMINUSERNAME ;
#    grant connect, resource to ${TARGETDATABASE_ADMINUSERNAME};
#    alter user ${TARGETDATABASE_ADMINUSERNAME} quota 100m on users;
#    grant unlimited tablespace to ${TARGETDATABASE_ADMINUSERNAME};
#    grant select any dictionary to ${TARGETDATABASE_ADMINUSERNAME};
#    grant select any table to ${TARGETDATABASE_ADMINUSERNAME};
#    grant create view to ${TARGETDATABASE_ADMINUSERNAME};
#    grant execute on dbms_lock to ${TARGETDATABASE_ADMINUSERNAME};
#    exec dbms_goldengate_auth.grant_admin_privilege('${TARGETDATABASE_ADMINUSERNAME}');
#    grant insert any table to ${TARGETDATABASE_ADMINUSERNAME};
#    grant update any table to ${TARGETDATABASE_ADMINUSERNAME};
#    grant delete any table to ${TARGETDATABASE_ADMINUSERNAME};
#    grant create any table to ${TARGETDATABASE_ADMINUSERNAME};
#    grant alter any table to ${TARGETDATABASE_ADMINUSERNAME};
#    grant drop any table to ${TARGETDATABASE_ADMINUSERNAME};
#    grant comment any table to ${TARGETDATABASE_ADMINUSERNAME};
#    grant create any index to ${TARGETDATABASE_ADMINUSERNAME};
#    grant alter any index to ${TARGETDATABASE_ADMINUSERNAME};
#    grant drop any index to ${TARGETDATABASE_ADMINUSERNAME};
#    grant create any view to ${TARGETDATABASE_ADMINUSERNAME};
#    grant drop any view to ${TARGETDATABASE_ADMINUSERNAME};
#    grant create any materialized view to ${TARGETDATABASE_ADMINUSERNAME};
#    grant alter any materialized view to ${TARGETDATABASE_ADMINUSERNAME};
#    grant drop any materialized view to ${TARGETDATABASE_ADMINUSERNAME};
#    grant create any procedure to ${TARGETDATABASE_ADMINUSERNAME};
#    grant alter any procedure to ${TARGETDATABASE_ADMINUSERNAME};
#    grant drop any procedure to ${TARGETDATABASE_ADMINUSERNAME};
#    /    " "Creating the $TARGETDATABASE_ADMINUSERNAME (dba) user on $pdb_name" "$I3"


    remoteCommand=$(cat <<%%
$envCommand
sqlplus -s / as sysdba <<SQL_AT_TARGET
whenever sqlerror exit failure ;
alter session set container=${pdb_name} ;

whenever sqlerror continue
drop profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE ;
create profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE limit password_life_time unlimited ;
create user $TARGETDATABASE_ADMINUSERNAME profile ${TARGETDATABASE_ADMINUSERNAME}_PROFILE identified by "${MF_TGT_PDB_PASSWORD}" ;
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
SQL_AT_TARGET
%%
)

    exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                  "Creating the ${TARGETDATABASE_ADMINUSERNAME} (dba) user on ${pdb_name}" "$I3" || die "Unable to create the migration user on target PDB"

    #
    #    Error management is not reliable on the previous step, so, we check here
    #
    exec_sql "$MF_TGT_PDB_CONNECT" "select 1 from dual;" "Testing PDB Connection" || die "Target PDB connection unsuccessful, check manually (dropping $MF_TGT_PDB_USER may help)"

  fi

  echo

  mfRepo_updateProgress PARAMETERS
  infoAction "Enforcing parameters for migration (PDB Level)" "$I1"
  exec_sql "$MF_TGT_PDB_CONNECT" "alter system set global_names=false scope=both;" "Enforce Global Names to FALSE (PDB)" "$I2"
  exec_sql "$MF_TGT_CDB_CONNECT" "alter system set streams_pool_size=256M scope=both;" "Enforce streams pool size to 256M (CDB)" "$I2"
  exec_sql "$MF_TGT_CDB_CONNECT" "alter system set enable_goldengate_replication=true scope=both;" "Enable GOLDEN Gate on target (CDB)" "$I2"
  exec_sql "$MF_TGT_CDB_CONNECT" "alter database add supplemental log data;" "Add supplemental LOGGING (CDB)" "$I2"
  exec_sql "$MF_TGT_PDB_CONNECT" "alter database add supplemental log data;" "Add supplemental LOGGING (PDB)" "$I2"

  mfRepo_updateProgress CHECK_GNAME
  libAction "Has GLOBAL_NAME a domain name?" "$I2"
  domainExists=$(exec_sql "$MF_TGT_PDB_CONNECT" "SELECT to_char(count(*)) FROM global_name where global_name like '%.%' ;")
  echo $domainExists
  cdb="cdb\\\\\\\$root"
  if [ "$domainExists" != "0" ]
  then

    remoteCommand=$(cat <<%%
    $envCommand
    sqlplus -s / as sysdba <<SQL_AT_TARGET
    prompt going to $pdb_name
    alter session set container=$pdb_name ;
    prompt Update GLOBAL_NAME
    UPDATE GLOBAL_NAME set GLOBAL_NAME= substr(global_name,1,INSTR(global_name, '.') -1) ;
    commit ;
    prompt Going to cdb\\\\\$root
    alter session set container=cdb\\\\\$root;
    prompt Closing $pdb_name
    alter pluggable database $pdb_name close immediate instances=all;
    prompt Opening $pdb_name
    alter pluggable database $pdb_name open instances=all;
SQL_AT_TARGET
%%
)
Sxheduke
   exec_on_target -verbose "${MF_SUDOER:-opc}@$databaseHost" "oracle" "$remoteCommand" \
                  "Changing the global name and restarting the PDB" "$I3" || die "Unable to delete the domain in the global name"

  fi
  
  echo
  infoAction "Check/Create the migration temporary tablespace" "$I1"
  if [ "$(exec_sql "$MF_TGT_PDB_CONNECT" "select to_char(count(*)) from dba_tablespaces where tablespace_name='MIG_EXACC_TEMP';")" = "0" ]
  then
    exec_sql "$MF_TGT_PDB_CONNECT" "create bigfile temporary tablespace MIG_EXACC_TEMP tempfile size 10G autoextend on;" "Creating migration temporary tablespace" "$I2"
  fi
  libAction "Current temporary tablespace for ${TARGETDATABASE_ADMINUSERNAME}" "$I2"
  ttbs=$(exec_sql "$MF_TGT_PDB_CONNECT" "select TEMPORARY_TABLESPACE from user_users;")
  echo $ttbs
  if [ "$ttbs" != "MIG_EXACC_TEMP" ]
  then
    exec_sql "$MF_TGT_PDB_CONNECT" "alter user ${TARGETDATABASE_ADMINUSERNAME} temporary tablespace MIG_EXACC_TEMP ;" "Set temporary tablespace for ${TARGETDATABASE_ADMINUSERNAME}" "$I3"
  fi
  
  echo
  mfRepo_updateProgress TBS
  infoAction "Enforce Autoextend oon BIGFILE tablespaces" "$I1"

  exec_sql "$MF_TGT_PDB_CONNECT" "select tablespace_name,file_name,autoextensible 
                                  from dba_data_files
                                  where tablespace_name in (select tablespace_name 
                                                            from dba_tablespaces
                                                            where BIGFILE='YES') ;" | while read tbs file ae
  do
    libAction "Tablespace $tbs autoextensible" "$I2" ; echo $ae
    if [ "$ae" = "NO" ]
    then
      exec_sql "$MF_TGT_PDB_CONNECT" "alter database datafile '$file' autoextend on ; " "Set autoextend for datafile in $tbs" "$I3" || die "Unable to set autoextend"
    fi
  done


  
  endStep
  
  mfRepo_updateProgress LIST_OBJ
  startStep "Object status in the target CDB"
  exec_sql "$MF_TGT_CDB_CONNECT" "
set pages 1000 lines 1000 trimout on heading on

col action_time    format a30
col action         format a20
col namespace      format a10
col version        format a30
col id             format 999
col COMMENTS       format a100
col VALUE          format a100

col COMP_ID        format a10
col COMP_NAME      format a50


alter session set nls_date_format='dd-Mon-yyyy hh24:mi:ss';
col rdate head \"Run Time\"
select sysdate rdate from dual;

Prompt
Prompt =========================================
Prompt PDB List
Prompt =========================================
Prompt

select
   pdb_name
  ,status
from 
  cdb_pdbs ;

show parameter audit

Prompt
Prompt =========================================
Prompt DBA Registry History
Prompt =========================================
Prompt

select * from dba_registry_history;

Prompt
Prompt =========================================
Prompt DBA Registry
Prompt =========================================
Prompt
select COMP_ID, comp_name,version,status from dba_registry;

Prompt
Prompt =========================================
Prompt INVALID Objects
Prompt =========================================
Prompt

select count(*) from dba_objects where status='INVALID';

Prompt
Prompt =========================================
Prompt INVALID Objects Per user
Prompt =========================================
Prompt

select owner, count(*) from dba_objects where status='INVALID' group by owner order by owner;

Prompt
Prompt =========================================
Prompt INVALID Objects list
Prompt =========================================
Prompt

select owner,object_name,object_type,status,last_ddl_time from DBA_OBJECTS where status <> 'VALID' order by owner,object_name;"

  #
  #    If we are HERE, the CDB has been created,
  #  get its information from the repository and update the corresponding runbook line for customer created PDBS/CDBS
  #
  updateRepoForFinalPDB
# else
  # infoAction "Preparation Actions not done on stand-by" "$I2"
# fi
  #
  #    Prepare services ans check HA status
  #
  echo 
  infoAction "Check/create service and check HA status" "$I1"
  infoAction "========================================" "$B1"
  echo
  svc=
  
  mfDbIs_PRIMARY && { role1=PRIMARY ; role2="STANDBY" ; } || { role1=STANDBY ; role2="PRIMARY" ; }
  createServices $role1 $databaseHost
  echo 
  
  echo
  infoAction "Check for dataguard congiguration and perform actions on the stand-by if needed" "$I1"
  infoAction "-------------------------------------------------------------------------------" "$B1"
  echo
  libAction "Number of stand-by databases" "$I2"
  nbStandBy=$(exec_sql "$MF_TGT_CDB_CONNECT" "select to_char(count(*)) from v\$dataguard_config where dest_role like '%STANDBY%';")
  echo "$nbStandBy"
  echo
  if [ "$nbStandBy" = "0" ]
  then
    infoAction "No stand-by is configured, no action taken" "$I2"
  else
    infoAction "DATAGUARD is configured, perform actions on stand-by site" "$I2"
    libAction "PRIMARY Cluster" "$I3"
    tmp=$(exec_sql "$MF_REPO_CONNECT" "
                                              select 
                                                ma.tclu_id || ';' || tc.real_name 
                                              from 
                                                migration_attempts ma
                                                join target_clusters tc on (tc.tclu_id = ma.tclu_id)
                                              where 
                                                mig_id=$MFAUTO_MIG_ID;")
    prim_cluster_id=$(echo "$tmp" | cut -f1 -d";")
    prim_cluster_name=$(echo "$tmp" | cut -f2 -d";")
    echo "$prim_cluster_name ($prim_cluster_id)"
    libAction "PEER Cluster" "$I3"
    tmp=$(exec_sql "$MF_REPO_CONNECT" "select 
                                         tclu_id || ';' || real_name
                                       from 
                                         target_clusters  tc
                                       where 
                                         peer_tclu_id=$prim_cluster_id;")
    peer_cluster_id=$(echo "$tmp" | cut -f1 -d";")
    peer_cluster_name=$(echo "$tmp" | cut -f2 -d";")
    echo "$peer_cluster_name ($peer_cluster_id)"
    peer_nodes=$(exec_sql "$MF_REPO_CONNECT" "select fqdn from target_nodes where tclu_id=$peer_cluster_id;")
    infoAction "Testing SSH access to peer cluster nodes" "$I2"
    for host in $peer_nodes 
    do
      exec_on_target "${MF_SUDOER:-opc}@$host" "" "true" \
                "SSH to $host" "$I3" || die "SSH access to $host is not working" </dev/null
    done

   peerHost=$( mfGetDbSshHost "$peer_nodes") || die "Unable to find a PEER host accepting ssh"
   
   echo
   createServices $role2  $peerHost  

   echo
   infoAction "Update migration attempt for DATAGUARDED databases" "$I1"
   infoAction "--------------------------------------------------" "$I1"
   echo
   
   exec_sql "$MF_REPO_CONNECT" "update migration_attempts set PDB_HA_SERVICE='${MF_TGT_DBNAME}_MFPDB' where mig_id=$MFAUTO_MIG_ID ;" \
            "Store PDB_HA_SERVICE=${MF_TGT_DBNAME}_MFPDB in MIGRATION_ATTEMPTS" "$I2"

   exec_sql "$MF_REPO_CONNECT" "update migration_attempts set CDB_HA_SERVICE='${CDB_NAME}_MFCDB' where mig_id=$MFAUTO_MIG_ID ;" \
            "Store CDB_HA_SERVICE=${CDB_NAME}_MFCDB in MIGRATION_ATTEMPTS" "$I2"
 fi


  endStep

  # ------------------------------------------------------------------------------------------------------

  endRun
