utils_VERSION=1.8
#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_REUSED
#  File                : mfUtils_03_rspManagement.sh
#
#  Purpose             : Migration factory utilities functions: Management of
#                        ZDM response files to be sourced from other MF scripts.
#
#  Description         : List of functions in this script - mfGenResponseFile
#
#  Functions           : 
#                        - getSpecificExclusions
#                        - getSpecificExclusionsAsWhere
#                        - getSpecificExclusionsVolumes
#                        - mfGenResponseFile
#
#  Change History      : 
#                        - 12/08/2026 AIN - Prevented the blank template
#                          EXCLUDEOBJECTS-1 entry from being retained when
#                          table-only exclusions are generated, avoiding a
#                          duplicate EXCLUDEOBJECTS-1 and PRGZ-3621.
#                        - 15/11/2024 MBO - Version 1.2.5, before LOT-0 start,
#
# *****************************************************************************


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_REUSED
#  Function            : mfGenResponseFile
#
#  Description         : Based on a migration type, this function replaces
#                        variables in the ZDM response File
#
#  Input Parameters    : - mType : MIgration type to select the correct template
#
#  Output              : None
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Trace input parameters when debug logging is enabled.
#                        - Iterate over the selected values until all required checks or actions
#                          are complete.
#                        - Parse command output to derive the value or status returned to the
#                          caller.
#
#  Possible issues     : 
#                        - Some file paths are redirected without quotes and may fail when they
#                          contain spaces.
#                        - Temporary file cleanup relies on variable paths being set correctly.
#                        - The function can stop the caller through die when a required operation
#                          fails.
# -----------------------------------------------------------------------------
#

mfGenResponseFile()
{
  mfDebugLog parameters: [$*]
  case $1 in
    ONLINE_LOGICAL|OFFLINE_LOGICAL)
    MF_RSP_TPL=$ZDM_HOME/rhp/zdm/template/zdm_logical_template.rsp
      ;;
    *)
      echo "Error"
      die "mfGenResponseFile : Unimplemented migration method : $1"
      ;;
  esac
  [ ! -f $MF_RSP_TPL ] && { echo "Error" ; die "mfGenResponseFile : Template $MF_RSP_TPL not found" ; }

  setVar MF_RSP_TPL $MF_RSP_TPL
  libAction "Generating response file for $MF_MIGRATION_ID ($1)" 
  if [ "$MF_GENERATE_RSP" = "N" ]
  then
    echo "Keep existing"
    [ ! -f "$MF_RSP_FILE" ] && die "response file does not exists (use -r Y) to generate it"
    infoAction "Using existing response file ($MF_RSP_FILE)" "$I1"
    return
  fi

  svDATAPUMPSETTINGS_EXPORTDIRECTORYOBJECT_NAME=$DATAPUMPSETTINGS_EXPORTDIRECTORYOBJECT_NAME
  svDATAPUMPSETTINGS_IMPORTDIRECTORYOBJECT_NAME=$DATAPUMPSETTINGS_IMPORTDIRECTORYOBJECT_NAME
  svDATAPUMPSETTINGS_EXPORTDIRECTORYOBJECT_PATH=$DATAPUMPSETTINGS_EXPORTDIRECTORYOBJECT_PATH
  svDATAPUMPSETTINGS_IMPORTDIRECTORYOBJECT_PATH=$DATAPUMPSETTINGS_IMPORTDIRECTORYOBJECT_PATH
  svDATA_TRANSFER_MEDIUM="$DATA_TRANSFER_MEDIUM"
  if [ "$DATA_TRANSFER_MEDIUM" = "DBLINK" -o "$DATA_TRANSFER_MEDIUM" = "PDB_COPY" -o "$DATA_TRANSFER_MEDIUM" = "ROLLING_PDB_COPY" ]
  then
    unset DATAPUMPSETTINGS_EXPORTDIRECTORYOBJECT_NAME
    unset DATAPUMPSETTINGS_EXPORTDIRECTORYOBJECT_PATH

    # unset DATAPUMPSETTINGS_IMPORTDIRECTORYOBJECT_NAME
    # unset DATAPUMPSETTINGS_IMPORTDIRECTORYOBJECT_PATH
    if [ "$DATA_TRANSFER_MEDIUM" = "PDB_COPY" -o "$DATA_TRANSFER_MEDIUM" = "ROLLING_PDB_COPY" ]
    then
      DATA_TRANSFER_MEDIUM=DBLINK
    fi
  fi
  [ -f $MF_RSP_FILE ] && cp -p $MF_RSP_FILE $MF_RSP_FILE.bkp 
  awk '
/^ *#/ {print ; next }
/^ *INCLUDEOBJECTS-1 *=/ {
  tmp=ENVIRON["MF_ZDM_INCLUDED_SCHEMAS"]
  if ( tmp != "" ) { print tmp }
  else             { print }
  next
}
/^ *EXCLUDEOBJECTS-1 *=/ {
  schemas=ENVIRON["MF_ZDM_EXCLUDED_SCHEMAS"]
  tables=ENVIRON["MF_ZDM_EXCLUDED_TABLES"]
  if ( schemas != "" ) { print schemas }
  if ( tables  != "" ) { print tables }
  if ( schemas == "" && tables == "" ) { print }
  next
}
/^ *DATAPUMPSETTINGS_METADATAFILTERS-1 *=/ {
  tmp=ENVIRON["MF_ZDM_METADATA_FILTERS"]
  if ( tmp != "" ) { print tmp }
  else             { print }
  next
}
/^ *DATAPUMPSETTINGS_TRANSFORMS-1 *=/ {
  tmp=ENVIRON["MF_ZDM_METADATA_TRANSFORMS"]
  if ( tmp != "" ) { print tmp }
  else             { print }
  next
}
/.*=.*/ { 
  split($0,arr,"=")
  varName=arr[1]
  varValue=arr[2]
  varScriptValue=ENVIRON[varName]
  if ( varValue == varScriptValue || varScriptValue == "" )
  {
    print ;
  }
  else
  {
     printf ("%s=%s\n",varName,varScriptValue) 
  }
  next 
}
{print} ' $MF_RSP_TPL > $MF_RSP_FILE  || { [ -f $MF_RSP_FILE.bkp ] && cp $MF_RSP_FILE.bkp $MF_RSP_FILE && rm -f $MF_RSP_FILE.bkp ; \
                                    echo "Error" ; die "mfGenResponseFile : Error generating response file" ; }
  rm -f $MF_RSP_FILE.bkp
  echo "OK" 
  if [ "$MF_GENERATE_RSP" = "Y" ]
  then
    infoAction "$MF_RSP_FILE generated" "$B2"
  fi
  DATAPUMPSETTINGS_EXPORTDIRECTORYOBJECT_NAME=$svDATAPUMPSETTINGS_EXPORTDIRECTORYOBJECT_NAME
  DATAPUMPSETTINGS_IMPORTDIRECTORYOBJECT_NAME=$svDATAPUMPSETTINGS_IMPORTDIRECTORYOBJECT_NAME
  DATAPUMPSETTINGS_EXPORTDIRECTORYOBJECT_PATH=$svDATAPUMPSETTINGS_EXPORTDIRECTORYOBJECT_PATH
  DATAPUMPSETTINGS_IMPORTDIRECTORYOBJECT_PATH=$svDATAPUMPSETTINGS_IMPORTDIRECTORYOBJECT_PATH
  DATA_TRANSFER_MEDIUM=$svDATA_TRANSFER_MEDIUM
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : getSpecificExclusionsAsWhere
#
#  Description         : Performs the get Specific Exclusions As Where operation
#                        used by mfUtils_03_rspManagement.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Not applicable.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Trace input parameters when debug logging is enabled.
#                        - Execute SQL statements through the configured database connection.
# -----------------------------------------------------------------------------
#

getSpecificExclusionsAsWhere()
{
  mfDebugLog parameters: [$*]
  local c=${1^^}
  local alias=${2}
  case ${c^^} in
    %COMMON_USERS%) exec_sql "$MF_SRC_PDB_CONNECT" "
                         select '                1=2' from dual
                         UNION                         
                         select '             or ' || ' (${alias}owner=''' || owner || ''')'
                        from DBA_USERS 
                        where	username not in ($ORACLE_MAINTAINED_USERS) and	common='YES'
                         /
                                                        "
                        ;;
    %OGG_BAD_COLS_YES%) exec_sql "$MF_SRC_PDB_CONNECT" "
                         select '                1=2' from dual
                         UNION                         
                         select '             or ' || ' (${alias}owner=''' || owner || ''' and ${alias}table_name=''' || table_name || ''')'
                        from DBA_GOLDENGATE_NOT_UNIQUE where	owner not in ($ORACLE_MAINTAINED_USERS) and	bad_column='Y'
                                                        and table_name not like 'AQ$%'
                                                         and (owner,table_name) not in (select 
                                                                                             owner
                                                                                            ,queue_table
                                                                                          from
                                                                                            dba_queue_tables)                                                        
                         /
                                                        "
                        ;;
    %OGG_ID_KEY%) exec_sql "$MF_SRC_PDB_CONNECT" "
                         select '                1=2' from dual
                         UNION                         
                         select '             or ' || ' (${alias}owner=''' || sm.owner || ''' and ${alias}table_name=''' || sm.object_name || ''')'
                          from DBA_GOLDENGATE_support_mode sm
                          join dba_objects ob on (sm.owner=ob.owner and sm.object_name = ob.object_name)
                          where	
                                sm.owner not in ($ORACLE_MAINTAINED_USERS) 
                                --sm.owner not in (select username from dba_users where oracle_maintained='Y')
                            and sm.support_mode='ID KEY'
                            and ob.object_type='TABLE'
                                                        and sm.object_name not like 'AQ$%'
                                                         and (sm.owner,sm.object_name) not in (select 
                                                                                             owner
                                                                                            ,queue_table
                                                                                          from
                                                                                            dba_queue_tables)                                                        
                         /
                                                 "
                        ;;
    %OGG_NOT_SUPPORTED%) exec_sql "$MF_SRC_PDB_CONNECT" "
                         select '                1=2' from dual
                         UNION                         
                         select '             or ' ||' (${alias}owner=''' || sm.owner || ''' and ${alias}table_name=''' || sm.object_name || ''')'
                          from DBA_GOLDENGATE_support_mode sm
                          join dba_objects ob on (sm.owner=ob.owner and sm.object_name = ob.object_name)
                          where	
                                sm.owner not in ($ORACLE_MAINTAINED_USERS) 
                                --sm.owner not in (select username from dba_users where oracle_maintained='Y')
                            and sm.support_mode in ('PLSQL','NONE')
                            and ob.object_type='TABLE'    
                                                        and sm.object_name not like 'AQ$%'
                                                         and (sm.owner,sm.object_name) not in (select 
                                                                                             owner
                                                                                            ,queue_table
                                                                                          from
                                                                                            dba_queue_tables)                                                        
                         /
                                                 "
                        ;;
  esac
  
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : getSpecificExclusions
#
#  Description         : Performs the get Specific Exclusions operation used by
#                        mfUtils_03_rspManagement.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Not applicable.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Trace input parameters when debug logging is enabled.
#                        - Execute SQL statements through the configured database connection.
# -----------------------------------------------------------------------------
#

getSpecificExclusions()
{
  mfDebugLog parameters: [$*]
  local c=${1^^}
  case ${c^^} in
    %COMMON_USERS%) exec_sql "$MF_SRC_PDB_CONNECT" "
                                                        select 
                                                          'owner:' || username
                                                        from DBA_USERS
                                                        where	username not in ($ORACLE_MAINTAINED_USERS) and	common='YES'
                                                        /
                                                        "
                        ;;
    %OGG_BAD_COLS_YES%) exec_sql "$MF_SRC_PDB_CONNECT" "
                                                        select 
                                                          'TABLE:' || owner || '.' || table_name 
                                                        from DBA_GOLDENGATE_NOT_UNIQUE 
                                                        where	owner not in ($ORACLE_MAINTAINED_USERS) and	bad_column='Y'
--                                                        and table_name not like 'AQ$%'
  --                                                       and (owner,table_name) not in (select 
    --                                                                                         owner
      --                                                                                      ,queue_table
        --                                                                                  from
          --                                                                                  dba_queue_tables)                                                        
                                                                                            /
                                                        "
                        ;;
    %OGG_ID_KEY%) exec_sql "$MF_SRC_PDB_CONNECT" "
                                                        select 
                                                          'TABLE:' || sm.owner || '.' || sm.object_name
                                                        from DBA_GOLDENGATE_support_mode sm
                                                        join dba_objects ob on (sm.owner=ob.owner and sm.object_name = ob.object_name)
                                                        where	
                                                              sm.owner not in ($ORACLE_MAINTAINED_USERS) 
                                                              --sm.owner not in (select username from dba_users where oracle_maintained='Y')
                                                          and sm.support_mode='ID KEY'
                                                          and ob.object_type='TABLE'
--                                                          and table_name not like 'AQ$%'
  --                                                       and (sm.owner,sm.object_name) not in (select 
    --                                                                                         owner
      --                                                                                      ,queue_table
        --                                                                                  from
          --                                                                                  dba_queue_tables)                                                        
                                                                                            /
                                                         "
                        ;;
    %OGG_NOT_SUPPORTED%) exec_sql "$MF_SRC_PDB_CONNECT" "
                                                        select 
                                                          'TABLE:' || owner || '.' || object_name 
                                                        from DBA_GOLDENGATE_SUPPORT_MODE  
                                                        where	
                                                              owner not in ($ORACLE_MAINTAINED_USERS) 
                                                              -- owner not in (select username from dba_users where oracle_maintained='Y')
                                                          and support_mode in ('PLSQL','NONE')
--                                                        and object_name not like 'AQ$%'
  --                                                       and (owner,object_name) not in (select 
    --                                                                                         owner
      --                                                                                      ,queue_table
        --                                                                                  from
          --                                                                                  dba_queue_tables)                                                        
                                                                                            /
                                                        "
                                                          ;;
  esac
  
}


#
# -----------------------------------------------------------------------------
#
#  Generation marker   : MF_DOC_GENERATED
#  Function            : getSpecificExclusionsVolumes
#
#  Description         : Performs the get Specific Exclusions Volumes operation
#                        used by mfUtils_03_rspManagement.sh.
#
#  Input Parameters    : - None.
#
#  Output              : Prints information to stdout or the configured log.
#
#  Return Code         : Not explicitly defined.
#
#  Algorithm           : 
#                        - Trace input parameters when debug logging is enabled.
#                        - Execute SQL statements through the configured database connection.
# -----------------------------------------------------------------------------
#

getSpecificExclusionsVolumes()
{
  mfDebugLog parameters: [$*]
  local c=${1^^}
  case ${c^^} in
    %OGG_BAD_COLS_YES%) exec_sql "$MF_SRC_PDB_CONNECT" "
set lines 200 tab off head on pages 2000
col segment_name format a30
col segment_type format a30
col seg_gb       format 999G999G999D99
col rows         format 999G999G999D99
col partitioned  format a10

break on report
compute sum of seg_Gb on report

select
   segment_name
  ,segment_type
  ,t.num_rows
  ,t.partitioned
  ,bytes/1024/1024/1024 seg_GB
from 
  dba_segments se
  join (
    select 
      owner, table_name object_name
    from DBA_GOLDENGATE_NOT_UNIQUE 
    where	owner not in ($ORACLE_MAINTAINED_USERS) and	bad_column='Y' ) l on (l.owner = se.owner and l.object_name = se.segment_name)
 join dba_tables t on ( l.owner = t.owner and l.object_name = t.table_name)
/  
"
                        ;;
    %OGG_ID_KEY%) exec_sql "$MF_SRC_PDB_CONNECT" "
set lines 200 tab off head on pages 2000
col segment_name format a30
col segment_type format a30
col seg_gb       format 999G999G999D99
col rows         format 999G999G999D99
col partitioned  format a10

break on report
compute sum of seg_Gb on report

select
   segment_name
  ,segment_type
  ,t.num_rows
  ,t.partitioned
  ,bytes/1024/1024/1024 seg_GB
from 
  dba_segments se
  join (
        select
          sm.owner ,sm.object_name
        from 
          DBA_GOLDENGATE_support_mode sm
          join dba_objects ob on (sm.owner=ob.owner and sm.object_name = ob.object_name)
        where
              sm.owner not in ($ORACLE_MAINTAINED_USERS) 
              --sm.owner not in (select username from dba_users where oracle_maintained='Y')
          and sm.support_mode='ID KEY'
          and ob.object_type='TABLE'
       ) l on (l.owner = se.owner and l.object_name = se.segment_name)
 join dba_tables t on ( l.owner = t.owner and l.object_name = t.table_name)
/  
                                                          "
                        ;;
    %OGG_NOT_SUPPORTED%) exec_sql "$MF_SRC_PDB_CONNECT" "
set lines 200 tab off head on pages 2000
col segment_name format a30
col segment_type format a30
col seg_gb       format 999G999G999D99
col rows         format 999G999G999D99
col partitioned  format a10

break on report
compute sum of seg_Gb on report

select
   segment_name
  ,segment_type
  ,t.num_rows
  ,t.partitioned
  ,bytes/1024/1024/1024 seg_GB
from 
  dba_segments se
  join (
        select
          sm.owner ,sm.object_name
        from 
          DBA_GOLDENGATE_support_mode sm
          join dba_objects ob on (sm.owner=ob.owner and sm.object_name = ob.object_name)
        where
              sm.owner not in ($ORACLE_MAINTAINED_USERS) 
              --sm.owner not in (select username from dba_users where oracle_maintained='Y')
          and support_mode in ('PLSQL','NONE')
          and ob.object_type='TABLE'
       ) l on (l.owner = se.owner and l.object_name = se.segment_name)
 join dba_tables t on ( l.owner = t.owner and l.object_name = t.table_name)
/  
                                                          "
                        ;;
    *) echo "ERROR Unknown code : $c"
  esac
  
}

