
  CREATE OR REPLACE EDITIONABLE PACKAGE "MFBNP"."MF_APEX_UTILS" as
/*
 *
 *  **************************************************************************
 *  Documentation marker : MF_DOC_GENERATED
 *  Package              : MF_APEX_UTILS
 *  File                 : 060_package_mf_apex_utils.pks
 *  Version              : 1.00.00
 *  Author               : ORACLE Consulting France (c)
 *  Creation date        : 28/08/24
 *
 *  Purpose
 *  -------
 *
 *        Package MF_APEX_UTILS routines.
 *
 *  Description
 *  -----------
 *
 *        Read individual routine descriptions in the package specification for
 *    details.
 *
 *  Public procedures/functions
 *  ---------------------------
 *
 *       - p6100_showHelp
 *       - p323_getMessage
 *       - p101_getStatusMessage
 *       - p200_genWhere
 *       - p318_clu_info
 *       - p318_ma_info
 *       - p318_tgt_info
 *       - p319_mini_runbook
 *       - showOnlineHelp
 *       - p300_dbInfo
 *       - p3503_quick_plan_wbp
 *       - p3109_getMessage
 *       - p20050_removeUser
 *       - p20050_createUser
 *       - getTimelineToolTip
 *       - batchedMigrationActivity
 *       - batchCommand
 *       - printMatrix
 *       - runBatch_clientDetect
 *       - update_who_does_what
 *       - p5001_mergeFlowTestResults
 *       - p5001_singleFlowTest
 *       - p3505_approvePlanningCR
 *       - p3505_rejectPlanningCR
 *       - p0000_default_logo
 *       - remove_plan_wbp
 *
 *  **************************************************************************
 */

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p6100_showHelp
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function p6100_showHelp(p_page in varchar2,p_app_id in number , p_session in number) return clob ;
/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p323_getMessage
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function  p323_getMessage(p_mig_id in number) return varchar2 ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p101_getStatusMessage
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function p101_getStatusMessage (  p_mig_id            in number
                                   ,p_target_dbname     in varchar2
                                   ,p_zdm_type          in varchar2
                                   ,p_milestone         in varchar2
                                   ,p_target_replica    in varchar2
                                   ,p_job_name          in varchar2
                                   ,p_ogg_check_date    in date
                                   ,p_ogg_check_result  in varchar2
                                   ,p_ogg_check_minutes in number
                                   ,p_ogg_check_status  in number
                                   ,p_cancelled         in varchar2
                                   ,p_gl_time           in date
                                   ) return varchar2 ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p200_genWhere
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function p200_genWhere (P200_EXTERNAL_CALL in out varchar2
                         ,P200_ENV_ID        in varchar2
                         ,P200_BU_ID         in varchar2
                         ,P200_WAVE_ID       in varchar2
                         ,P200_MILESTONE     in varchar2
                         ,GLOB_PRJ_NAME      in varchar2
                         ,P200_SCLU_ID       in varchar2
                         ,P200_IN_SCOPE      in varchar2
                         ,P200_TCLU_ID       in varchar2
                         ,P200_MA_CODE       in varchar2
                         ,P200_DATABASE_NAME in varchar2
                         ,P200_MKP_ID        in varchar2
                         ,P200_OGG_PROCESS   in varchar2
                         ,P200_BU_GROUP      in varchar2
                         ,P200_OGG_ID        in number
                         ) return varchar2;
/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p318_clu_info
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function p318_clu_info(p_mig_id in number,p_app_id in number,p_session in number) return CLOB  ;
/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p318_ma_info
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function p318_ma_info(p_mig_id in number,p_app_id in number,p_session in number) return CLOB  ;
/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p318_tgt_info
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function p318_tgt_info(p_mig_id in number,p_app_id in number,p_session in number) return CLOB  ;
/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p319_mini_runbook
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function p319_mini_runbook(p_mig_id in number,p_others in varchar2 default 'N',p_editable in varchar2 default 'N',p_app_id in number default null,p_session in number default null) return CLOB  ;


/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : showOnlineHelp
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function showOnlineHelp(p_topic in varchar2) return CLOB  ;
/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : showOnlineHelp
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function showOnlineHelp(p_section in varchar2,p_sub_section in varchar2) return CLOB  ;
/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p300_dbInfo
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function  p300_dbInfo(p_db_id in number,p_app_id in number,p_session in number) return varchar2 ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p3503_quick_plan_wbp
 *  Type                 : Procedure
 *
 *  Description
 *  -----------
 *
 *        Public procedure exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Output Parameters
 *  -----------------
 *
 *       - None
 *
 * ----------------------------------------------------------------------------
 *
 */
  procedure p3503_quick_plan_wbp(P_GLOB_PRJ_NAME in varchar2
                                ,P_P3503_GL_DATE in varchar2
                                ,P_P3503_DB_ID in varchar2
                                ,P_P3503_MIG_ID in varchar2
                                ,P_P3503_OVERNIGHT in out varchar2
                                ,P_P3503_DESIRED_ZDM_TYPE in varchar2
                                ) ;
/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p3109_getMessage
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function  p3109_getMessage(d in date,t in varchar2 default 'N', f in varchar2 default 'N',day_only in varchar2 default 'N') return varchar2 ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p20050_removeUser
 *  Type                 : Procedure
 *
 *  Description
 *  -----------
 *
 *        Public procedure exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Output Parameters
 *  -----------------
 *
 *       - None
 *
 * ----------------------------------------------------------------------------
 *
 */
  procedure p20050_removeUser(    user_name                       in varchar2);
/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p20050_createUser
 *  Type                 : Procedure
 *
 *  Description
 *  -----------
 *
 *        Public procedure exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Output Parameters
 *  -----------------
 *
 *       - None
 *
 * ----------------------------------------------------------------------------
 *
 */
  procedure p20050_createUser(
    user_name                       in varchar2,
    first_name                      in varchar2 default 'First Name',
    last_name                       in varchar2 default 'Last Name',
    email_address                   in varchar2 default 'user@acme.com',
    temp_web_password               in varchar2 default 'Wel_Come_@MF_00'
  )  ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : getTimelineToolTip
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function  getTimelineToolTip         ( p_mig_id                 in migration_attempts.mig_id%type
                                        ,p_golive_date            in date
                                      ) return varchar2 ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : batchedMigrationActivity
 *  Type                 : Procedure
 *
 *  Description
 *  -----------
 *
 *        Public procedure exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Output Parameters
 *  -----------------
 *
 *       - None
 *
 * ----------------------------------------------------------------------------
 *
 */
  procedure batchedMigrationActivity   ( p_migration_definition   in mf_mig_parameters.mig_def_t --v_migration_steps%rowtype
                                        ,p_label                  in varchar2
                                        ,p_unicity_code           in varchar2  default 'GLOBAL'
                                        ,p_waitForCompletion      in boolean   default true
                                        ,p_printOutput            in boolean   default false
                                       )  ;
/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : batchCommand
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function  batchCommand               ( p_shellBlock        in varchar2
                                        ,p_label             in varchar2  default 'Batch scipt'
                                        ,p_prj_name          in varchar2  default null
                                        ,p_script_name       in varchar2  default 'Any Script'
                                        ,p_script_parameters       in varchar2  default null
                                       ) return number ;
/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : printMatrix
 *  Type                 : Procedure
 *
 *  Description
 *  -----------
 *
 *        Public procedure exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Output Parameters
 *  -----------------
 *
 *       - None
 *
 * ----------------------------------------------------------------------------
 *
 */
  procedure printMatrix                ( p_rows_select        in varchar2                 -- Select to retrieve the values of the rows (first columns)
                                                                                          -- it must return EXACTLY 11 columns named col_id,col_val1 ... col_val10 , fill with NULLs
                                        ,p_cols_select        in varchar2                 -- Select to retrieve the values of the rows (first lines)
                                                                                          -- it must return EXACTLY 11 columns, fill with NULLs
                                        ,p_cells_select       in varchar2 default null    --     Select to retrieve the values of the cells ONE and only one value
                                        ,p_cells_line_select  in varchar2 default null    -- OR Select to retrieve the values of the  full line of cells, ORDER must be the same than in p_cols_select
                                        ,p_first_cell_format  in varchar2 default null    -- Format of the top most left cell(s)          (for text: length, for HTML code including %s)
                                        ,p_first_row_format   in varchar2 default null    -- Format of the first row(s) cells (header)    (for text: length, for HTML code including %s)
                                        ,p_first_col_format   in varchar2 default null    -- format of the first column(s) cells (header) (for text: length, for HTML code including %s)
                                        ,p_cell_format        in varchar2 default null    -- Format of the cell(s)                        (for text: length, for HTML code including %s)
                                        ,p_table_start        in varchar2 default null    -- Table start HTML
                                        ,p_table_end          in varchar2 default null    -- Table end HTML
                                        ,p_row_start          in varchar2 default null    -- Row start HTML
                                        ,p_row_end            in varchar2 default null    -- Row end HTML
                                        ,p_output_type        in varchar2 default 'TEXT'  -- OUtpout format
                                        ,p_nb_cols_on_left    in number   default 1       -- Number of userfull values in the previous select
                                        ,p_nb_rows_on_top     in number   default 1       -- Number of userfull values in the previous select
                                        ,p_start_cols_hdr     in varchar2 default null    -- '|' separated headers for the N first columns
                                        ,p_start_cols_width   in varchar2 default null   -- '|' separated widths for the N first columns (will replace width="" in the format)
                                        ,p_separator          in varchar2 default ';'     -- Field separator for csv output
                                        ) ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : runBatch_clientDetect
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function runBatch_clientDetect       ( p_wav_id                        in varchar2   -- ID of the Wave
                                        ,p_mig_code_prefix               in varchar2   -- Prefix of the migration attemps code
                                        ,p_interval_minutes              in number     -- Run interval in minutes
                                        ,p_duration_minutes              in number     -- Duration of the run in minutes
                                        ,p_error_message                 out varchar2  -- Error meddage
                                       ) return number ;                              -- Return : 0=All batches launched , 1=Some batches already running , 2= No batch launched
/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : update_who_does_what
 *  Type                 : Procedure
 *
 *  Description
 *  -----------
 *
 *        Public procedure exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Output Parameters
 *  -----------------
 *
 *       - None
 *
 * ----------------------------------------------------------------------------
 *
 */
  procedure update_who_does_what       ( p_page   in number
                                        ,p_db_id  in NUMBER
                                        ,p_mig_id in number default null  ) ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p5001_mergeFlowTestResults
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function  p5001_mergeFlowTestResults ( d        in date
                                        ,day_only in varchar2 default 'N' ) return varchar2 ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p5001_singleFlowTest
 *  Type                 : Procedure
 *
 *  Description
 *  -----------
 *
 *        Public procedure exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Output Parameters
 *  -----------------
 *
 *       - None
 *
 * ----------------------------------------------------------------------------
 *
 */
  procedure  p5001_singleFlowTest      ( p_db_id  in varchar2
                                        ,p_flow_type in varchar2          ) ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p3505_approvePlanningCR
 *  Type                 : Procedure
 *
 *  Description
 *  -----------
 *
 *        Public procedure exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Output Parameters
 *  -----------------
 *
 *       - None
 *
 * ----------------------------------------------------------------------------
 *
 */
  procedure  p3505_approvePlanningCR   ( p_pcr_id  in number ) ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p3505_rejectPlanningCR
 *  Type                 : Procedure
 *
 *  Description
 *  -----------
 *
 *        Public procedure exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Output Parameters
 *  -----------------
 *
 *       - None
 *
 * ----------------------------------------------------------------------------
 *
 */
  procedure  p3505_rejectPlanningCR    ( p_pcr_id  in number ) ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : p0000_default_logo
 *  Type                 : Function
 *
 *  Description
 *  -----------
 *
 *        Public function exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Return Value
 *  ------------
 *
 *       - See the routine signature and implementation.
 *
 * ----------------------------------------------------------------------------
 *
 */
  function p0000_default_logo return blob ;

/*
 *
 * ----------------------------------------------------------------------------
 *  Documentation marker : MF_DOC_GENERATED
 *  Routine              : remove_plan_wbp
 *  Type                 : Procedure
 *
 *  Description
 *  -----------
 *
 *        Public procedure exposed by MF_APEX_UTILS.
 *
 *        Review the routine signature for the exact parameter list and types.
 *
 *  Output Parameters
 *  -----------------
 *
 *       - None
 *
 * ----------------------------------------------------------------------------
 *
 */
  procedure remove_plan_wbp(P_MIG_ID in number) ;
end;
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "MFBNP"."MF_APEX_UTILS" as
/*
 *
 *  **************************************************************************
 *  Documentation marker : MF_DOC_GENERATED
 *  Package              : MF_APEX_UTILS
 *  File                 : mf_apex_utils.pkb
 *  Version              : 1.00.00
 *  Author               : ORACLE Consulting France (c)
 *  Creation date        : 28/08/24
 *
 *  Purpose
 *  -------
 *
 *        Package MF_APEX_UTILS routines.
 *
 *  Public procedures/functions
 *  ---------------------------
 *
 *       - p6100_showHelp
 *       - p323_getMessage
 *       - p101_getStatusMessage
 *       - p200_genWhere
 *       - p318_clu_info
 *       - p318_ma_info
 *       - p318_tgt_info
 *       - p319_mini_runbook
 *       - showOnlineHelp
 *       - p300_dbInfo
 *       - p3503_quick_plan_wbp
 *       - p3109_getMessage
 *       - p20050_removeUser
 *       - p20050_createUser
 *       - getTimelineToolTip
 *       - batchedMigrationActivity
 *       - batchCommand
 *       - printMatrix
 *       - runBatch_clientDetect
 *       - update_who_does_what
 *       - p5001_mergeFlowTestResults
 *       - p5001_singleFlowTest
 *       - p3505_approvePlanningCR
 *       - p3505_rejectPlanningCR
 *       - p0000_default_logo
 *       - remove_plan_wbp
 *
 *  Private procedures/functions
 *  ----------------------------
 *
 *       - p6100_helpPreRequisites
 *       - p101_size_message
 *       - prCluster
 *       - prline
 *       - prlineRB
 *       - setMilestone
 *       - p20050_triggerCreateUser
 *       - cleanCrashedBatches
 *       - pr
 *       - pr_start_table
 *       - pr_end_table
 *       - pr_start_row
 *       - pr_end_row
 *       - pr_end_message
 *
 *  **************************************************************************
 */

  amp number := 38 ; -- ASCII Code for ampersand

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function p6100_helpPreRequisites(p_page in varchar2,p_app_id in number,p_session in number) return clob is
    tmp clob ;
  begin
      tmp := tmp || '<BLOCKQUOTE><BLOCKQUOTE>' ;
      tmp := tmp || '<TABLE border=0>' ;

      tmp := tmp || '<TR>' ;
      tmp := tmp || '<TD width=100px><B>' || 'Name' || '</B></TD>';
      tmp := tmp || '<TD width=10px>' || chr(amp) || 'nbsp;' || '</TD>';
      tmp := tmp || '<TD width=100px><B>' || 'Severity' || '</B></TD>';
      tmp := tmp || '<TD width=10px>' || chr(amp) || 'nbsp;' || '</TD>';
      tmp := tmp || '<TD width=100px><B>' || 'Autofixable' || '</B></TD>';
      tmp := tmp || '<TD width=10px>' || chr(amp) || 'nbsp;' || '</TD>';
      tmp := tmp || '<TD width=700px><B>' || 'Description/Comments' || '</B></TD>';
      tmp := tmp || '</TR>' ;
      tmp := tmp || '</B>' ;
    for rec$p in (select
                    seq_num
                   ,name
                   ,description
                   ,severity
                   ,auto_fix
                   ,comments
                   ,pr_id
                from
                  PRE_REQUISITES
                where
                  migration_type = replace(P_PAGE,'PR-','')
                order BY
                  seq_num)
    LOOP
      tmp := tmp || '<TR>' ;
      tmp := tmp || '<TD><FONT color=blue size=+1><B>' || rec$p.name || '</B></FONT></TD>';
      tmp := tmp || '<TD>' || chr(amp) || 'nbsp;' || '</TD>';
      tmp := tmp || '<TD><FONT size=+1><B>' || rec$p.severity || '</B></TD>';
      tmp := tmp || '<TD>' || chr(amp) || 'nbsp;' || '</TD>';
      tmp := tmp || '<TD><FONT size=+1><B>' || rec$p.auto_fix || '</B></FONT></TD>';
      tmp := tmp || '<TD>' || chr(amp) || 'nbsp;' || '</TD>';
      tmp := tmp || '<TD><FONT color=green size=+1><I>' || rec$p.description || '</I></FONT></TD>';
      tmp := tmp || '</TR>' ;
      tmp := tmp || '<TR>' ;
      tmp := tmp || '<TD colspan=5>' || ' ' || '</TD>';
      if (not apex_authorization.is_authorized(p_authorization_name => 'Administration Rights'))
      THEN
        tmp := tmp || '<TD>' || chr(amp) || 'nbsp;' || '</TD>';
      else
        tmp := tmp || '<TD>';
        tmp := tmp || chr(amp) || 'nbsp;' ;
        tmp := tmp || chr(amp) || 'nbsp;' ;
        tmp := tmp || '<A HREF="' ;
        tmp := tmp ||APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':1531:' || p_SESSION || '::NO::P1531_PR_ID:' ||rec$p.pr_id ,p_checksum_type => 'SESSION') ;
        tmp := tmp || '"><span class="fa fa-pencil-square" style="color: blue;" title="Edit description"/></A>' ;
        tmp := tmp || chr(amp) || 'nbsp;' ;
        tmp := tmp || chr(amp) || 'nbsp;' ;
        tmp := tmp || '</TD>';
      end if ;
      tmp := tmp || '<TD>' || rec$p.comments || '</TD>';
      tmp := tmp || '</TR>' ;
    end loop ;
    tmp := tmp || '</TABLE>' ;
      tmp := tmp || '</BLOCKQUOTE></BLOCKQUOTE>' ;
    return(tmp) ;
  end ;

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function p6100_showHelp(p_page in varchar2,p_app_id in number , p_session in number) return clob is
    tmp clob ;
    main_desc varchar2(4000);
    l_title varchar2(50);
    l_url varchar2(2000) ;
    l_link varchar2(32767) ;
  begin
    tmp := tmp || '<SCRIPT>
function toggle(dv) {
  var x = document.getElementById(dv);
  if (x.style.display === "none") {
    x.style.display = "block";
  } else {
    x.style.display = "none";
  }
}
</SCRIPT>' ;
    begin
        select
            description
            ,title
        into
            main_desc
            ,l_title
        from
            mf_online_doc_pages
        where
            name = nvl(P_PAGE,'MAIN_DOC') ;
        if (l_title is not null)
        THEN
          tmp := tmp || '<span style="color: #0000ff;"><U><strong><font size=+2>' || l_title || '</font></strong></U></span><BR>' ;
        end if ;
        if (main_desc like '<%')
        then
        tmp := tmp ||  main_desc  ;
        else
        tmp := tmp || '<BR><p><B><I><span style="color: #008000;"><em>' || main_desc || '</em></span></I></B></p>' ;
        end if ;
        exception when no_data_found then main_desc := null ;
    end ;
    tmp := tmp || '<BLOCKQUOTE>';
    for s in (select name , description ,ods_id
                from mf_online_doc_sections
                where odp_id = (select odp_id from mf_online_doc_pages where name = nvl(P_PAGE,'MAIN_DOC'))
                order by seq_num)
    loop
        if (s.name like 'PR-%')
        THEN
            return (tmp || p6100_helpPreRequisites(s.name,p_app_id,p_session)) ;
        end if ;
        tmp := tmp || '<span style="color: #0000ff;"><strong><font size=+2>' || s.name || '</font></strong></span>' ;
        tmp := tmp || chr(amp) || 'nbsp;' ;
        tmp := tmp || '-';
        tmp := tmp || chr(amp) || 'nbsp;' ;
        tmp := tmp || '<A href="javascript:toggle(''sec_' || to_char(s.ods_id) ||''')">Show/Hide details</A><BR>' ;
        tmp := tmp || '<DIV id="sec_' || to_char(s.ods_id) || '">' ;
        if (s.description like '<%')
        then
        tmp := tmp || '<BLOCKQUOTE>' || s.description || '</BLOCKQUOTE>' ;
        else
        tmp := tmp || '<BLOCKQUOTE><p><span style="color: #008000;"><em>' || s.description || '</em></span></p></BLOCKQUOTE>' ;
        end if ;

        tmp := tmp || '<BLOCKQUOTE><BLOCKQUOTE><TABLE style="border-collapse:collapse;">' ;
        for d in (select
                    title
                    ,description
                    ,file_name
                    ,indent
                    ,odd_id
                from
                    mf_online_doc_documents
                where
                    ods_id = s.ods_id
                order by seq_num)
        loop
        if ( d.indent=0)
        then
          tmp := tmp || '<TR style="vertical-align: top; border-top: 2px solid #5C5C5C; ">' ;
          tmp := tmp || '<TD width=300px ><H5 style="margin-top:0;">' || d.title || '</H5></TD>' ;
        else
          tmp := tmp || '<TR >' ;
          tmp := tmp || '<TD width=300px style="vertical-align:top;" ><BLOCKQUOTE><i>' || d.title || '</i></BLOCKQUOTE></TD>' ;
        end if ;
        if (not apex_authorization.is_authorized(p_authorization_name => 'Administration Rights'))
        THEN
            tmp := tmp || '<TD>' || chr(amp) || 'nbsp;' || '</TD>';
        else
            tmp := tmp || '<TD>';
            tmp := tmp || chr(amp) || 'nbsp;' ;
            tmp := tmp || chr(amp) || 'nbsp;' ;
            tmp := tmp || '<A HREF="' ;
            tmp := tmp ||APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':6202:' || p_SESSION || '::NO::P6202_ODD_ID:' ||d.odd_id ,p_checksum_type => 'SESSION') ;
            tmp := tmp || '"><span class="fa fa-pencil-square" style="color: blue;" title="Edit document"/></A>' ;
            tmp := tmp || chr(amp) || 'nbsp;' ;
            tmp := tmp || chr(amp) || 'nbsp;' ;
            tmp := tmp || '</TD>';
        end if ;
        if (d.description like '<%')
        then
            tmp := tmp ||  '<TD width=800px>' ||  d.description  || '</TD>' ;
        else
            tmp := tmp || '<TD width=800px><p><span style="color: #008000;"><em>' || d.description || '</em></span></p></TD>' ;
        end if ;
        if (d.file_name not like '%.sh%')
        then
            if (d.file_name like 'http%')
            THEN
              tmp := tmp || '<TD width=300px><A HREF=''javascript:window.open("'||d.file_name||'")''>' || d.file_name || '</A></TD>'  ;
            else
              tmp := tmp || '<TD width=300px><A HREF=''javascript:window.open("https://s02vl9926799.fr.net.intra/mf_documentation/pdf/'||d.file_name||'")''>' || d.file_name || '</A></TD>'  ;
            end if ;
        elsif (d.file_name is not null)
        then
            l_url := 'f?p=' || P_APP_ID || ':3700:' || P_SESSION || '::NO::P3700_TITLE,P3700_COMMAND:' || d.file_name || ' Usage,'|| d.file_name || ' --help';

            -- Prepare URL
            l_link := APEX_UTIL.PREPARE_URL(
                                p_url => l_url,
                                p_checksum_type => 'SESSION'
                            );
            --raise_application_error(-20000,l_link) ;
            tmp := tmp || '<TD width=300px><A HREF="' || l_link || '">' || d.file_name || ' Usage </A></TD>'  ;
        tmp := tmp || '</TR>' ;
        end if ;
        end loop ;
        tmp := tmp || '</TABLE></BLOCKQUOTE></BLOCKQUOTE>' ;
        tmp := tmp || '</DIV>' ;
    end loop ;
    tmp := tmp || '</BLOCKQUOTE>';
    return tmp ;
  end ;


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function  p323_getMessage(p_mig_id in number) return varchar2 is
    tmp           varchar2(32767) ;
  begin
    for rec in (select
                   db.source_dbname
                  ,ma.target_dbname
                  ,gl.planned_go_live
                from
                  migration_attempts ma
                  join databases db on (db.db_id=ma.db_id)
                  left join v_go_live_dates gl on (gl.mig_id=ma.mig_id)
                WHERE
                  ma.mig_id = p_mig_id)
    loop
      tmp := '<HTML>';
      tmp := tmp || 'Hello<BR>' ;
      tmp := tmp || 'The following prerequisites are not met on the source for the migration of the <B>' ||
                    rec.source_dbname || '</B> to the target <B>' || rec.target_dbname || '</B>' ||
                    ' planned on <B><U>' || to_char (rec.planned_go_live,'dd/mm/yyyy hh24:mi') || '</U></B>.' ||
                    '<BR><BR>';
      tmp := tmp || '<B>Ignored pre-requisites (may required pre or post actions)</B><BR>' ;
      for pr in (select
                    migration_type
                   ,name
                   ,source_ignore_reason
                   ,description
                   ,db_id
                 from
                   v_prerequisite_checks
                 WHERE
                   mig_id = P_MIG_ID
                   and severity='ERROR'
                   and source_result='FALSE'
                   and source_ignored='Y'
                 order BY
                   migration_type,seq_num
                )
      LOOP
        tmp := tmp || '<LI><B>' || pr.name || '</B>: ' || pr.description || ' ('|| pr.migration_type || ')</LI>' ;
        tmp := tmp || '<BLOCKQUOTE><I>' || pr.source_ignore_reason || '</I></BLOCKQUOTE>' ;
        if (pr.name = 'DATABASE_LINK')
        then
            for l in (select db_link,username,host
                         from db_links
                         where result_test=1
                         and db_id=pr.db_id)
            LOOP
                tmp := tmp || '<LI><B>' || l.db_link || '</B>: ' || l.username || '@' || l.host || '</LI>';
            end loop ;
        end if ;
      end loop ;
      tmp := tmp || '<B>FAILED pre-requisites requiring answers from the application<BR></B>' ;
      for pr in (select
                    migration_type
                   ,name
                   ,source_ignore_reason
                   ,description
                   ,db_id
                 from
                   v_prerequisite_checks
                 WHERE
                   mig_id = P_MIG_ID
                   and severity='ERROR'
                   and source_result='FALSE'
                   and source_ignored='N'
                 order BY
                   migration_type,seq_num
                )
      LOOP
        tmp := tmp || '<LI><B>' || pr.name || '</B>: ' || pr.description || ' ('|| pr.migration_type || ')</LI>' ;
        tmp := tmp || '<BLOCKQUOTE><I>' || pr.source_ignore_reason || '</I></BLOCKQUOTE>' ;
        if (pr.name = 'DATABASE_LINK')
        then
            for l in (select db_link,username,host
                         from db_links
                         where result_test=1
                         and db_id=pr.db_id)
            LOOP
                tmp := tmp || '<LI><B>' || l.db_link || '</B>: ' || l.username || '@' || l.host || '</LI>';
            end loop ;
        end if ;
      end loop ;
        tmp := tmp || '</HTML>' ;
    end loop ;
    return(tmp) ;
  end ;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function p101_size_message (p_mig_id in number) return varchar2 is
    db_declared_size number ;
    db_actual_size number ;
  begin
    begin
        select
           db.size_gb
          ,to_number(replace(replace(oi.value,' ',''),',','.'))
        into
           db_declared_size
          ,db_actual_size
        FROM
          MIGRATION_ATTEMPTS ma
          join databases db on (ma.db_id=db.db_id)
          left join other_informations oi on (ma.db_id = oi.db_id and oi.name='SEGMENTS_SIZE_GB')
        WHERE
        ma.mig_id = p_mig_id ;
    exception when no_data_found then null ;
    end ;
    return('<BR> Size GB :<B>' || to_char(db_declared_size,'999G999G990D00') || '</B> (declared) <B>' || to_char(db_actual_size,'999G999G990D00') || '</B> (actual)' );
  end ;

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function p101_getStatusMessage (  p_mig_id            in number
                                   ,p_target_dbname     in varchar2
                                   ,p_zdm_type          in varchar2
                                   ,p_milestone         in varchar2
                                   ,p_target_replica    in varchar2
                                   ,p_job_name          in varchar2
                                   ,p_ogg_check_date    in date
                                   ,p_ogg_check_result  in varchar2
                                   ,p_ogg_check_minutes in number
                                   ,p_ogg_check_status  in number
                                   ,p_cancelled         in varchar2
                                   ,p_gl_time           in date
                                   ) return varchar2 as

res varchar2 (2000);
tmp varchar2 (2000);
tmp_ret number ;
tmp_dat date   ;
last_ope date  ;
begin
  begin
    select
      last_operation
    into
      last_ope
    from
      MIGRATION_ATTEMPTS
    where
      mig_id = p_mig_id ;
  exception
    when no_data_found then last_ope := null ;
  end ;

  if p_cancelled = 'Y'
  then
    return '<FONT color=black>Migration has been <B>CANCELLED</B><BR>Please REPLAN or remove from wave.</FONT>' ;
  end if ;

  res := 'No Check done' ;
  if nvl(p_target_dbname,'DUMMY') in ('DUMMY','TOCREATE')
  then
    res := 'ERROR : No target database' ;
  elsif p_milestone > mf_mig_parameters.get_seq('MLS_TARGET_OPENED')
  then
    res := 'DB live' ;
  elsif ( p_milestone = mf_mig_parameters.get_seq('MLS_MIGRATION_DONE') and sysdate < p_gl_time and p_zdm_type != 'ONLINE_LOGICAL')
  then
    res := 'WARNING: Migration (status=' || p_milestone || ') done in advance, <BR>If DRY-RUN, please remove before real migration.' ;
  elsif p_milestone between mf_mig_parameters.get_seq('MLS_MIG_READY') and mf_mig_parameters.get_seq('MLS_GOLIVE_START')
  then
    if p_zdm_type = 'ONLINE_LOGICAL'
    then
      res := case
           when p_target_replica is null then 'Not synchronized <BR>' || 'Last operation : ' || to_char(last_ope,'dd/mm/yyyy hh24:mi:ss')
           else
             case
             when p_job_name is null then
               case
               when (sysdate - p_ogg_check_date) < 0.5 then 'ERROR: ' || p_OGG_check_result|| '<BR>(' || p_ogg_check_minutes || ' min. ago)'
               else 'ERROR : NOT MONITORED'
               end
             else
               case
                when nvl(p_ogg_check_status,1) = 1 then 'ERROR : ' || p_OGG_check_result || '<BR>(' || p_ogg_check_minutes || ' min. ago)'
                when nvl(p_ogg_check_status,1) = 0 then
                  case
                  when p_ogg_check_minutes < 60 then 'OK : ' || 'Checked  ' || p_ogg_check_minutes || ' minutes ago'
                  when p_ogg_check_minutes < 60*24 then 'WARNING : ' || 'Checked  ' || p_ogg_check_minutes || ' minutes ago'
                  else 'ERROR: ' || 'Checked  ' || p_ogg_check_minutes || ' minutes ago'
                  end
                end
              end
            end ;
    else
      res := 'Ready' ;

      begin
        SELECT
          case
            when return_code is null then 'MIGRATION RUNNING : ' || status
            when return_code = 0 then 'Migration succeeded'
            else  'ERROR : Migration failed ==> <BR>' || error_message
          end
         ,return_code
         ,start_date
        into
          res,tmp_ret,tmp_dat
        from
          step_execs
        where
          mstep_id in (select mstep_id
                       from migration_steps
                       where mig_id=p_mig_id and global_step_code = '210-MIG_RUN')
        order by start_date desc
        fetch first 1 rows only;
        if ( tmp_ret = 0 )
        then
          begin
            SELECT
               case
                 when return_code is null then 'MIGRATION RUNNING : (tt)' || status
                 when return_code = 0 then 'Technical tests succeeded on ' || to_char(end_date,'dd/mm hh24:mi')
                 else  'ERROR : technical tests failed ==> <BR>' || error_message
               end
              ,return_code
              ,start_date
            into
              res,tmp_ret,tmp_dat
            from
              step_execs
            where
              mstep_id in (select mstep_id
                           from migration_steps
                           where mig_id=p_mig_id and global_step_code = '300-POST_TT')
              and start_date > tmp_dat
            order by start_date desc
            fetch first 1 rows only;
          exception
            when no_data_found
            then
              res:= 'WARNING : Migration done, but no technical testing done' ;
          end ;
        end if ;
      exception
        when no_data_found then res := 'Milestone is ' || p_milestone || '<BR>' ||
                                       ' (Never migrated)' ; res := null ;
      end ;

      if (res is null )
      then
        tmp := null ;
        begin
            SELECT
            listagg(script_name || ' ' || parameters,' ') within group (order by seq_num)
            into
            tmp
            from
            v_migration_step_last_execs
            where
            mstep_id in (
                            select
                            mstep_id
                            FROM
                            migration_steps
                            --v_migration_step_last_execs
                            WHERE
                                mig_id = p_mig_id
                            and seq_num < (select seq_num
                                            from migration_steps
                                            where mig_id = p_mig_id
                                            and migration_steps.GLOBAL_STEP_CODE = '200-MIG_EVAL')
                            and step_type = 'U'
            )
            and return_code != 0 ;
            res := '[' || tmp || ']';
            if ( tmp is not null )
            then
            res := 'ERROR: Milestone is ' || p_milestone || ' but : <BR>' ||
                    ' Steps : <B>' || tmp || '</B> have failed.' ;
            else
            res := 'Milestone is ' || p_milestone || ' Pre-migration activities successful.' ;
            end if ;
        exception
            when no_data_found
            then
            res := 'WARNING: Milestone is ' || p_milestone || ' nothing has been run.' ;
        end ;
      end if ;
    end if ;
  elsif p_milestone <= mf_mig_parameters.get_seq('MLS_START')
  then
    if trunc(p_gl_time - sysdate) <= 7
    THEN
      res := 'ERROR: ' ;
    elsif trunc(p_gl_time - sysdate) <= 14
    then
      res := 'WARNING: ' ;
    end if;
    res := res || 'No activity done yet (' || trunc(p_gl_time - sysdate) || ' day before GL)' ;
  elsif p_milestone = mf_mig_parameters.get_seq('MLS_TARGET_OPENED')
  then
    res := 'WARNING: If migration in progress, update runbook' ;
  else
    res := 'Unmanaged status , update p101_getStatusMessage()' ;
  end if ;
  res := res || p101_size_message (p_mig_id) ;
  return res ;
end ;

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Build and return the SQL WHERE clause used by page 200 filters from
   *    the provided APEX item values.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation and escaping before
   *         changing the dynamic SQL construction.
   *       - Concatenating item values into SQL text may expose the caller to
   *         malformed predicates if values are not controlled by the UI.
   *
   * ----------------------------------------------------------------------------
   *
   */

  function p200_genWhere (P200_EXTERNAL_CALL in out varchar2
                         ,P200_ENV_ID        in varchar2
                         ,P200_BU_ID         in varchar2
                         ,P200_WAVE_ID       in varchar2
                         ,P200_MILESTONE     in varchar2
                         ,GLOB_PRJ_NAME      in varchar2
                         ,P200_SCLU_ID       in varchar2
                         ,P200_IN_SCOPE      in varchar2
                         ,P200_TCLU_ID       in varchar2
                         ,P200_MA_CODE       in varchar2
                         ,P200_DATABASE_NAME in varchar2
                         ,P200_MKP_ID        in varchar2
                         ,P200_OGG_PROCESS   in varchar2
                         ,P200_BU_GROUP      in varchar2
                         ,p200_OGG_ID        in number
                         ) return varchar2 is
    p200_where varchar2(32767) ;
    begin
    if (P200_EXTERNAL_CALL != 'Y')
    then
      p200_where := 'where 1=1' ;
      if (P200_OGG_ID is not null)
      then
        p200_where := P200_WHERE || chr(10) ||
                       ' and (   db_id in (select  ma1.db_id
                                          from    migration_attempts ma1
                                          where   ma1.ogg_id=' || P200_OGG_ID || '))' ;
      end if ;
      if (P200_ENV_ID is not null)
      then
        p200_where := P200_WHERE || chr(10) ||
                      ' and env_id = ' || P200_ENV_ID ;
      end if ;
      if (P200_BU_GROUP is not null)
      then
        p200_where := p200_where || chr(10) ||
                       ' and bu_id in (select  bu_id
                                       from    business_units
                                       where   group_bu = ''' || P200_BU_GROUP || ''')' ;
      end if ;
      if (P200_BU_ID is not null)
      then
        p200_where := p200_where || chr(10) ||
                       ' and bu_id = ' || P200_BU_ID ;
      end if ;
      if (P200_WAVE_ID is not null)
      then
        p200_where := p200_where || chr(10) ||
                       ' and db_id in (select  dw2.db_id
                                       from    db_in_waves dw2
                                       where   dw2.wav_id = ' || P200_WAVE_ID || ')' ;
      end if ;
      if (P200_MILESTONE is not null)
      then
        p200_where := p200_where || chr(10) ||
                       ' and db_id in (select db_id
                                       from   V_DATABASE_MIGRATION_STATUSES
                                       where  prj_name = ''' || GLOB_PRJ_NAME || '''' || '
                                       and    seq_num = ''' || P200_MILESTONE || ''')' ;
      end if ;
      if (P200_SCLU_ID is not null)
      then
        p200_where := p200_where || chr(10) ||
                       ' and sclu_id = ' || P200_SCLU_ID ;
      end if ;
      if (P200_IN_SCOPE is not null)
      then
        p200_where := p200_where || chr(10) ||
                       ' and in_scope = ''' || P200_IN_SCOPE || '''' ;
      end if ;
      if (P200_TCLU_ID is not null)
      then
        p200_where := p200_where || chr(10) ||
                       ' and db_id in (select  ma1.db_id
                                       from    migration_attempts ma1
                                       where   ma1.tclu_id = ''' || P200_TCLU_ID || ''')' ;
      end if ;
      if (P200_MA_CODE is not null)
      then
        p200_where := p200_where || chr(10) ||
                       ' and db_id in (select  ma1.db_id
                                       from    migration_attempts ma1
                                       where   ma1.code like ''%' || P200_MA_CODE || '%'')' ;
      end if ;
      if (P200_DATABASE_NAME is not null)
      then
       p200_where := p200_where || chr(10) ||
                       ' and (   db_id in (select  ma1.db_id
                                          from    migration_attempts ma1
                                          where   ma1.target_dbname like ''' || P200_DATABASE_NAME || '%''
                                          or     ma1.target_container_service like ''' || P200_DATABASE_NAME || '%'')
                              or db_id in (select db_id from db_services where name like ''' || P200_DATABASE_NAME || '%'')
                              or source_oracle_sid like ''' || P200_DATABASE_NAME || '%'')' ;
      end if ;
      if (P200_MKP_ID is not null)
      then
        p200_where := p200_where || chr(10) ||
                       ' and (   db_id in (select  ma1.db_id
                                          from    migration_attempts ma1
                                          where   ma1.clt_cdb_subscription like ''' || P200_MKP_ID || '%''
                                          or      ma1.clt_cdb_demand       like ''' || P200_MKP_ID || '%''
                                          or      ma1.clt_pdb_subscription like ''' || P200_MKP_ID || '%''
                                          or      ma1.clt_pdb_demand       like ''' || P200_MKP_ID || '%''))' ;
      end if ;
      if (P200_OGG_PROCESS is not null)
      then
        p200_where := p200_where || chr(10) ||
                       ' and (   db_id in (select  ma1.db_id
                                          from    migration_attempts  ma1
                                          where   ma1.source_extract  like ''' || P200_OGG_PROCESS || '%''
                                          or      ma1.target_replica  like ''' || P200_OGG_PROCESS || '%''
                                          or      ma1.target_extract  like ''' || P200_OGG_PROCESS || '%''
                                          or      ma1.source_replica  like ''' || P200_OGG_PROCESS || '%''))' ;
      end if ;
    end if ;
    P200_EXTERNAL_CALL := 'N';
    return(p200_WHERE) ;
  end ;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function p318_clu_info(p_mig_id in number,p_app_id in number,p_session in number) return CLOB  is


    tmp   clob ;
    /*
     *
     * ----------------------------------------------------------------------------
     *  Algorithm
     *  ---------
     *
     *        Compute and return the routine result using the package state, input parameters, SQL statements,
     *    and external API calls implemented below.
     *
     *  Possible Issues
     *  ---------------
     *
     *       - Generated documentation: review input validation, exception handling,
     *         and assumptions about data cardinality before changing the code.
     *       - SQL queries and external package calls may propagate runtime errors
     *         unless they are explicitly handled in the implementation.
     *
     * ----------------------------------------------------------------------------
     *
     */
    function prCluster(p_tclu_id in number) return clob is
      tmp   clob ;
      lnk   varchar2(2000);
      l_url varchar2(2000);
    BEGIN
        for rec in (select name,real_name from target_clusters where tclu_id = p_tclu_id)
        LOOP
          tmp := tmp || '<p><em><span style="color: #0000ff;"><strong>'|| rec.real_name ||'</strong></span></em></p>';
          tmp := tmp || '<BLOCKQUOTE><LI>' ;
          l_url := '<A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                                  ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                                  '$MF_HOME/utils/mfToolsClusterInfo.sh -C ' || rec.name || ' -S ASM_SPACE,ASM Space'
                                                      ,p_checksum_type => 'SESSION') || '">' ||
                   'ASM</A>' ||
                   '';
          tmp := tmp || l_url ;

          tmp := tmp || chr(amp) || 'nbsp;' || '-' ||chr(amp) || 'nbsp;';
          l_url := '<A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                                  ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                                  '$MF_HOME/utils/mfToolsClusterInfo.sh -C ' || rec.name || ' -S CPU_RAM,CPU/RAM'
                                                      ,p_checksum_type => 'SESSION') || '">' ||
                   'CPU/RAM</A>' ||
                   '';
          tmp := tmp || l_url ;

          tmp := tmp || chr(amp) || 'nbsp;' || '-' ||chr(amp) || 'nbsp;';
          l_url := '<A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                                  ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                                  '$MF_HOME/utils/mfToolsClusterInfo.sh -C ' || rec.name || ' -S DB_LIST,Databases'
                                                      ,p_checksum_type => 'SESSION') || '">' ||
                   'Databases</A>' ||
                   '';
          tmp := tmp || l_url ;

          tmp := tmp || chr(amp) || 'nbsp;' || '-' ||chr(amp) || 'nbsp;';
          l_url := '<A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                                  ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                                  '$MF_HOME/utils/mfToolsClusterInfo.sh -C ' || rec.name || ' -S ASM_MAP,ASM Usage Map'
                                                      ,p_checksum_type => 'SESSION') || '">' ||
                   'ASM Map</A>' ||
                   '';
          tmp := tmp || l_url ;

          tmp := tmp || '</LI></BLOCKQUOTE>' ;

        end loop ;
        return(tmp);
    end ;
  BEGIN
    for rec in (select
                   ma.tclu_id
                  ,tc.real_name
                  ,tc.peer_tclu_id
                from migration_attempts ma
                join target_clusters tc on tc.tclu_id=ma.tclu_id
                where
                  ma.mig_id=p_mig_id)
    loop
        tmp := tmp || prCluster(rec.tclu_id) ;
        if (rec.peer_tclu_id is not null)
        THEN
            tmp := tmp || prCluster(rec.peer_tclu_id) ;
        end if ;
    end loop ;

    return tmp ;
  end ;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function p318_ma_info(p_mig_id in number,p_app_id in number,p_session in number) return CLOB  is
    tmp   clob ;
    lnk   varchar2(2000);
    l_url varchar2(2000);
  BEGIN
    tmp := tmp || '<BLOCKQUOTE>' ;
    l_url := 'f?p=' || p_APP_ID || ':319:' || p_SESSION || '::NO::P319_MIG_ID,P319_OTHERS,P319_EDITABLE:' || p_mig_id || ',N,N' ;
    lnk  := '<A href="' ||
               APEX_UTIL.PREPARE_URL(p_url =>l_url
                                    ,p_checksum_type => 'SESSION') || '">' || 'Mini runbook (commented lines only) - This attempt only' || '</A>' ;
    tmp := tmp || '<LI>' || lnk || '</LI>' ;

    l_url := 'f?p=' || p_APP_ID || ':319:' || p_SESSION || '::NO::P319_MIG_ID,P319_OTHERS,P319_EDITABLE:' || p_mig_id || ',Y,N' ;
    lnk  := '<A href="' ||
               APEX_UTIL.PREPARE_URL(p_url =>l_url
                                    ,p_checksum_type => 'SESSION') || '">' || 'Mini runbook (commented lines only) - Other DBs for this application' || '</A>' ;
    tmp := tmp || '<LI>' || lnk || '</LI>' ;

    l_url := 'f?p=' || p_APP_ID || ':322:' || p_SESSION || '::NO::P322_MIG_ID:' || p_mig_id  ;
    lnk  := '<A href="' ||
               APEX_UTIL.PREPARE_URL(p_url =>l_url
                                    ,p_checksum_type => 'SESSION') || '">' || 'LAG History graph' || '</A>' ;
    tmp := tmp || '<LI>' || lnk || '</LI>' ;

    tmp := tmp || '</BLOCKQUOTE>' ;
    return(tmp) ;
  end ;

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function p318_tgt_info(p_mig_id in number,p_app_id in number,p_session in number) return CLOB  is
    tmp clob ;
    l_url varchar2(2000);
  BEGIN
    for rec in (select code,target_dbname,target_container_service from migration_attempts where mig_id = p_mig_id)
    loop
      tmp := tmp || '<p><em><span style="color: #0000ff;"><strong>'|| rec.target_dbname || ' (' || rec.target_container_service  ||')</strong></span></em></p>';
    tmp := tmp || '<BLOCKQUOTE>' ;
    l_url := '<LI><A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                            ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                            '$MF_BIN/mfDbActions.sh -m ' || rec.code || ',Database status'
                                                ,p_checksum_type => 'SESSION') || '">' ||
            'DB Status</A> - ' || '<A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                            ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                            '$MF_BIN/mfDbActions.sh -m ' || rec.code || ' -A PRIM_DB -a fix_pass,Database status'
                                                ,p_checksum_type => 'SESSION') || '">' ||
            'Fix password issues</A>' ||
            '</LI>' ||
            '';
    tmp := tmp || l_url ;
    l_url := '<LI><A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                            ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                            '$MF_BIN/mfOGGSlowReplication.sh -m ' || rec.code || ',Slow statements'
                                                ,p_checksum_type => 'SESSION') || '">' ||
            'Analyze replication slowness</A></LI>' ||
            '';
    tmp := tmp || l_url ;
    tmp := tmp || '<LI> Blackout (local emctl) : ' ;
    l_url := '<A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                            ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                            '$MF_BIN/mfEmBlackout.sh -m ' || rec.code || ' -A STATUS ,Blackout status for ' || rec.code
                                                ,p_checksum_type => 'SESSION') || '">' ||
            'Status</A>' ||
            '';
    tmp := tmp || l_url ;

          tmp := tmp || chr(amp) || 'nbsp;' || '-' ||chr(amp) || 'nbsp;';
    l_url := '<A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                            ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                            '$MF_BIN/mfEmBlackout.sh -m ' || rec.code || ' -A START ,Start local emctl Blackout'
                                                ,p_checksum_type => 'SESSION') || '">' ||
            'Start</A>' ||
            '';
    tmp := tmp || l_url ;

          tmp := tmp || chr(amp) || 'nbsp;' || '-' ||chr(amp) || 'nbsp;';
    l_url := '<A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                            ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                            '$MF_BIN/mfEmBlackout.sh -m ' || rec.code || ' -A STOP ,Stop Blackout'
                                                ,p_checksum_type => 'SESSION') || '">' ||
            'Stop</A>' ||
            '';
    tmp := tmp || l_url ;

    tmp := tmp || '</LI>' ;
    tmp := tmp || '<LI> Blackout (OEM REST) : ' ;
    l_url := '<A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                            ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                            '$MF_BIN/mfEmBlackout.sh -m ' || rec.code || ' -r -A STATUS ,OEM REST Blackout status for ' || rec.code
                                                ,p_checksum_type => 'SESSION') || '">' ||
            'Status</A>' ||
            '';
    tmp := tmp || l_url ;

          tmp := tmp || chr(amp) || 'nbsp;' || '-' ||chr(amp) || 'nbsp;';
    l_url := '<A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                            ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                            '$MF_BIN/mfEmBlackout.sh -m ' || rec.code || ' -r -A START ,Start OEM REST Blackout for 12 hours'
                                                ,p_checksum_type => 'SESSION') || '">' ||
            'Start (12h)</A>' ||
            '';
    tmp := tmp || l_url ;

          tmp := tmp || chr(amp) || 'nbsp;' || '-' ||chr(amp) || 'nbsp;';
    l_url := '<A href="' || APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':3700:' || p_session || '::NO:'||
                                                            ':P3700_COMMAND,P3700_TITLE' ||  ':' ||
                                                            '$MF_BIN/mfEmBlackout.sh -m ' || rec.code || ' -r -A STOP ,Stop OEM REST Blackout'
                                                ,p_checksum_type => 'SESSION') || '">' ||
            'Stop</A>' ||
            '';
    tmp := tmp || l_url ;

    tmp := tmp || '</LI>' ;
    tmp := tmp || '</BLOCKQUOTE>' ;
    end loop ;
    return (tmp) ;
  end ;


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function p319_mini_runbook(p_mig_id in number,p_others in varchar2 default 'N',p_editable in varchar2 default 'N',p_app_id in number default null,p_session in number default null)  return CLOB  is


    tmp clob ;


    /*
     *
     * ----------------------------------------------------------------------------
     *  Algorithm
     *  ---------
     *
     *        Compute and return the routine result using the package state, input parameters, SQL statements,
     *    and external API calls implemented below.
     *
     *  Possible Issues
     *  ---------------
     *
     *       - Generated documentation: review input validation, exception handling,
     *         and assumptions about data cardinality before changing the code.
     *       - SQL queries and external package calls may propagate runtime errors
     *         unless they are explicitly handled in the implementation.
     *
     * ----------------------------------------------------------------------------
     *
     */
    function prline(l in varchar2,v in varchar2) return clob is
    begin
      return(to_clob('<TR><TD style="vertical-align: text-top" width="30%""><B>'||l||'</TD><TD>'|| v || '</TD></TR>' ));
    end ;
    /*
     *
     * ----------------------------------------------------------------------------
     *  Algorithm
     *  ---------
     *
     *        Compute and return the routine result using the package state, input parameters, SQL statements,
     *    and external API calls implemented below.
     *
     *  Possible Issues
     *  ---------------
     *
     *       - Generated documentation: review input validation, exception handling,
     *         and assumptions about data cardinality before changing the code.
     *       - SQL queries and external package calls may propagate runtime errors
     *         unless they are explicitly handled in the implementation.
     *
     * ----------------------------------------------------------------------------
     *
     */
    function prlineRB(l in varchar2,v in varchar2,p_rbl_id in number) return clob is
      l_url varchar2(2000);
    begin

    if ( p_editable = 'Y' )
    then
      l_url := chr(amp) || 'nbsp;<A HREF="' ;
      l_url := l_url ||APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| p_app_id || ':403:' || p_SESSION || '::NO::P403_RBL_ID:' ||p_rbl_id ,p_checksum_type => 'SESSION') ;
      l_url := l_url || '"><span class="fa fa-pencil-square" style="color: blue;"/></A>' ;
    end if ;


      return(to_clob('<B>'||l || l_url ||'</B><BR><BLOCKQUOTE>'|| v || '</BLOCKQUOTE>' ));
    end ;

  BEGIN
    tmp := tmp || '<p><em><span style="color: #0000ff;"><strong>Databases Information :</strong></span></em></p><BR>' ;
    tmp := tmp || '<TABLE border=0>';
    for rec in (
            select
               ma.code
              ,ma.target_dbname
              ,ma.target_container_service
              ,db.source_oracle_sid
              ,db.env_name
            from
               migration_attempts ma
               join v_databases db on (ma.db_id=db.db_id)
            where
              ma.mig_id=p_mig_id
               )
    loop
      tmp := tmp || prline('Migration CODE','<B>' || rec.code|| '</B>') ;
      tmp := tmp || prline('Source Database',rec.source_oracle_sid) ;
      tmp := tmp || prline('Environment',rec.env_name) ;
      tmp := tmp || prline('Target',rec.target_dbname || ' (' || rec.target_container_service || ')') ;
    end loop ;
    tmp := tmp || '</TABLE><BR>';
    tmp := tmp || '<p><em><span style="color: #0000ff;"><strong>Commented lines :</strong></span></em></p><BR>' ;
    for rec in (
            select
               label
              ,operator_comment
              ,global_line_code
              ,rbl_id
            from
              runbook_lines
            where
              mig_id = p_mig_id
              and (   (p_editable='Y' and (operator_comment is not null or global_line_code in('GEN_COMMENTS','SRC_PREREQ_ANALYSIS','PREPARE_MIGRATION','MIGRATE','TECH_TESTS','SWITCHOVER','CONCLUSION')))
                   or (p_editable='N' and operator_comment is not null)
                  )
              and (nvl(run_by,'N/A') != 'MFAUTOANALYZE')
            order by
              seq_num
           )
    LOOP
        tmp:=tmp||prlineRB(rec.label,replace(rec.operator_comment,chr(10),'<BR>'),rec.rbl_id) ;
    end loop ;
    tmp := tmp || '<HR>' ;
    if ( p_others = 'Y')
    THEN
        tmp := tmp || '<I><FONT color="#8D6F64">' ;
        for rec in (
                        SELECT
                        ma.mig_id
                        ,da.app_id
                        ,db.env_name
                        FROM
                        migration_attempts ma
                        join db_apps da on (da.db_id = ma.db_id)
                        join v_databases db on(ma.db_id = db.db_id)
                        WHERE
                        da.db_id in (select
                                        da2.db_id
                                    from
                                        DB_APPS da2
                                    where
                                        da2.app_id in (select
                                                        da1.app_id
                                                        FROM
                                                        migration_attempts ma1
                                                        join db_apps da1 on (da1.db_id = ma1.db_id)
                                                        WHERE
                                                        ma1.mig_id=p_mig_id)
                        )
                        and current_attempt='Y'
                        and mig_id != p_mig_id
                        order BY
                        decode (db.env_name,'Production',5
                                            ,'Pre-production',10
                                            ,'Qualification',15
                                            ,'Integration',25
                                            ,'Development',30
                                            ,40)
                    )
        LOOP
            tmp := tmp || p319_mini_runbook(rec.mig_id,'N',p_editable=>'N') ;
        end loop;
        tmp := tmp || '</FONT></I>' ;
    end if ;
    return tmp ;

  end ;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
function showOnlineHelp(p_topic in varchar2) return CLOB is
  url varchar2(500) ;
  url_name varchar2(500);
  help_text clob ;
begin
  select
    external_url
    ,inline_help
  into
     url_name
    ,help_text
  from
    mf_online_help
  WHERE
    hlp_id = p_topic;

  if ( url_name is not null)
  THEN
    if ( url_name like '%.pdf' )
    then
      /* TODO : make server url as a variable in MF */
      url := '<A HREF=''javascript:window.open("https://s02vl9926799.fr.net.intra/mf_documentation/pdf/' || url_name || '")''>' || url_name || '</A>';
      -- url := '<A HREF=''javascript:window.open("/mf_documentation/pdf/' || url_name || '")''>' || url_name || '</A>';
    else
      url := '<A HREF=''' || url || ''' target="_blank">' || url_name || '</A>';
    end if;
    help_text := help_text || '
<h4>
  <span style="color: #0000ff;"> Additional resources : </span>
</h4>
<ul>
  <li>
      <span style="color: #0000ff;">
        '|| url ||'
      </span></li>
</ul>    ' ;
  end if;
  return(help_text)  ;
end ;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
function showOnlineHelp(p_section in varchar2,p_sub_section in varchar2) return CLOB  is
  tmp number ;
begin
    select
      hlp_id
    into
      tmp
    from
      mf_online_help
    where
      section=p_section and sub_section = p_sub_section ;
    return(showOnlineHelp(to_char(tmp))) ;
exception
  when no_data_found then
  insert into MF_ONLINE_HELP (section,sub_section,inline_help) values (p_section,p_sub_section,'<h4><span style="color: #0000ff;">Page : </span><span style="color: #0000ff;"><span style="color: #008000;"><em>Please define help text</em></span></span></h4>
<h4><span style="color: #0000ff;">Description :</span></h4>
<p style="padding-left: 30px;"><span style="color: #008000;"><em>TO DO (colors RGB - Blue: 0,0,255, Green: 128,0,0)</em></span></p>
<h4><span style="color: #0000ff;">Sections and usage :</span></h4>
<ul>
<li><span style="color: #008000;"><em><strong><span style="text-decoration: underline;">Section 1 </span></strong>: Description.</em></span></li>
</ul>
<p> </p>
<ul>
<li><span style="color: #008000;"><em><strong><span style="text-decoration: underline;">Section 2 </span></strong>: Description</em></span></li>
</ul>
<h4><span style="color: #0000ff;">Other information :</span></h4>
<ul>
<li><span style="color: #008000;"><em>Information 1.</em></span></li>
</ul>') returning HLP_id into tmp ;
  return(showOnlineHelp(to_char(tmp))) ;
end ;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
function  p300_dbInfo(p_db_id in number,p_app_id in number,p_session in number) return varchar2 is
  ret varchar2(32767) ;
  tmp varchar2(500) ;
  tmp2 varchar2(500) ;
  td varchar2(100) := '<TD style="vertical-align: top; padding-right: 5px; padding-right: 10px;" >';
  tr varchar2(100) := '<TR style="vertical-align: top;" >';
  l_url           VARCHAR2(32767);
begin

   ret:='<font size=-1>' ;
   ret:= ret || '<TABLE class="t-Report-report" border=1>';
   ret:= ret || tr ;

   -- -----------------------------------------------------------------------------------------
   --
   -- Line 1 / Column 1
   --
   ret:= ret || td ;
   begin
    SELECT b.NAME
    into tmp
    FROM DATABASES d
    JOIN BUSINESS_UNITS b ON d.BU_ID = b.BU_ID
    WHERE d.DB_ID = P_DB_ID   ;
   exception when no_data_found then tmp := null ;
  end ;
  ret := ret || '<B>BU : </B>' || tmp ;
  ret:= ret || '</TD>';

   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 1 / Column 2
   --
  ret:= ret || td ;

  begin
    select e.NAME
    into tmp
    FROM DATABASES d
    JOIN ENVIRONMENTS e ON d.ENV_ID = e.ENV_ID
    WHERE d.DB_ID = P_DB_ID;
   exception when no_data_found then tmp := null ;
  end ;
  ret := ret || '<B>Env : </B>' || tmp ;

  begin
    select a.NAME
          ,'f?p=' || p_APP_ID || ':1503:' || p_SESSION || '::NO::P1503_APP_ID:' || a.app_id
    into tmp
         ,l_url
    FROM db_apps d
    JOIN APPLICATIONS a ON d.APP_ID = a.APP_ID
    WHERE d.DB_ID = P_DB_ID;
   exception when no_data_found then tmp := null ;
  end ;

  tmp  := '<A target="appDetails" href="' ||
             APEX_UTIL.PREPARE_URL(p_url => l_url
                                  ,p_checksum_type => 'SESSION') || '">' || tmp || '</A>' ;

  ret := ret || '(' || tmp || ')' ;
  ret:= ret || '</TD>';
   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 1 / Column 3
   --
  ret:= ret || td ;
  begin
    select
      '<B>GL</B>: ' || to_char(target_date,'dd/mm/yyyy hh24:mi:ss') || ' - ' || ct.first_name || ' ' || ct.last_name || case when rldba.mor_id is not null then ' (DBA:' || ctdba.trigram || ')' else '' end
    into tmp
    from
      migration_planned_operations po
      join migration_attempts ma on (ma.mig_id = po.mig_id and current_attempt='Y')
      left join mig_roles rl on (rl.mig_id = ma.mig_id and rl.ROL_ID = (select ROL_ID from ROLES where name = 'OPER'))
      left join mig_roles rldba on (rldba.mig_id = ma.mig_id and rldba.ROL_ID = (select ROL_ID from ROLES where name = 'DBA'))
      left join contacts ct on (ct.cnt_id = rl.cnt_id)
      left join contacts ctdba on (ctdba.cnt_id = rldba.cnt_id)
    where
      ma.db_id = P_DB_ID
      and po.mls_id = mf_mig_parameters.get_id('MLS_ID_GOLIVE_START',po.prj_name)
      and po.current_plan='Y'
      and rownum=1;
   exception when no_data_found then tmp := null ;
  end ;

  ret := ret || tmp || '</TD>' ;
   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 1 / Column 4
   --
  ret:= ret || td ;
  begin
    select dw.wave_NAME
          ,'f?p=' || p_APP_ID || ':1600:' || p_SESSION || '::NO::P1600_WAVE_ID:' || dw.wave_id
    into tmp
         ,l_url
    FROM v_db_in_waves dw
    WHERE dw.DB_ID = P_DB_ID
    and   wave_type='Migration';
   exception when no_data_found then tmp := null ;
  end ;

  ret := ret || '<B>Wave : </B>' || tmp ;

  tmp  :=  '<A target="appDetails" href="' ||
             APEX_UTIL.PREPARE_URL(p_url => l_url
                                  ,p_checksum_type => 'SESSION') || '">' || tmp || '</A>' ;

  ret := ret || chr(amp) || 'nbsp;(' || tmp || ')' ;

  ret := ret || '</TD>' ;
  ret := ret || '</TR>';


   -- -----------------------------------------------------------------------------------------
   --
   -- Line 2 / Column 1
   --
  ret:= ret || tr ;
  ret:= ret || td ;
  begin
    select s.NAME,s.sclu_id
          ,'f?p=' || p_APP_ID || ':1000:' || p_SESSION || '::NO::P1000_SCLU_ID:' || s.sclu_id
    into tmp,tmp2,l_url
    FROM DATABASES d
    JOIN SOURCE_CLUSTERS s ON d.SCLU_ID = s.SCLU_ID
    WHERE d.DB_ID = P_DB_ID;
   exception when no_data_found then tmp := null ;
  end ;
  tmp  := tmp ||' (<A target="dbDetails" href="' ||
             APEX_UTIL.PREPARE_URL(p_url => l_url
                                  ,p_checksum_type => 'SESSION') || '">' || tmp2 || '</A>)' ;
  ret := ret || '<B>Src Srv : </B>' || tmp ;
  ret:= ret || '</TD>';
   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 2 / Column 2
   --
   ret:= ret || td ;

  begin
    SELECT SOURCE_DBNAME , ' (' || db_id || ')'
          ,'f?p=' || p_APP_ID || ':201:' || p_SESSION || '::NO::P201_DB_ID:' || db_id
    into tmp2,tmp
        ,l_url
    FROM DATABASES
    WHERE DB_ID = P_DB_ID ;
   exception when no_data_found then tmp := null ;
  end ;
  tmp  := '<A target="dbDetails" href="' ||
             APEX_UTIL.PREPARE_URL(p_url => l_url
                                  ,p_checksum_type => 'SESSION') || '">' || tmp || '</A>' ;


  ret := ret || '<B>Name : </B>' || tmp2 || ' ' || tmp ;
  tmp  := '';
  tmp2 := '';
  ret := ret || '</TD>';
   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 2 / Column 3
   --
  ret:= ret || td ;

  begin
    SELECT target_dbname || ' (' || regexp_replace(target_container_service,'M1$','') || ')'
    into   tmp
    FROM   migration_attempts
    WHERE  DB_ID = P_DB_ID
    and    current_attempt ='Y';
   exception when no_data_found then tmp := null ;
  end ;
  ret := ret || '<B>Tgt : </B>' || tmp ;
  ret:= ret || '</TD>';
   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 2 / Column 4
   --
  ret:= ret || td ;

  begin
    SELECT tc.real_name
           ,tc.tclu_id
           ,'f?p=' || p_APP_ID || ':1010:' || p_SESSION || '::NO::P1010_TCLU_ID:' || tc.tclu_id
    into    tmp
           ,tmp2
           ,l_url
    FROM   migration_attempts ma
    JOIN   target_clusters    tc on (tc.tclu_id = ma.tclu_id)
    WHERE  DB_ID = P_DB_ID
    and    current_attempt ='Y';
   exception when no_data_found then tmp := null ;
  end ;

  tmp2  := '<A target="tgtDetails" href="' ||
             APEX_UTIL.PREPARE_URL(p_url => l_url
                                  ,p_checksum_type => 'SESSION') || '">' || tmp2 || '</A>' ;

  ret := ret || '<B>Tgt Clu: </B>' || tmp || ' (' || tmp2 || ')';

  ret:= ret || '</TD>';
  ret:= ret || '</TR>';
  ret:= ret || tr ;

   -- -----------------------------------------------------------------------------------------
   --
   -- Line 3 / Column 1
   --
  ret:= ret || td ;

  begin
    SELECT db.VERSION || ' ('|| oi.value || ')'
    into tmp
    FROM DATABASES db
    left join other_informations oi on (db.db_id=oi.db_id and name='VERSION')
    WHERE db.DB_ID = P_DB_ID ;
   exception when no_data_found then tmp := null ;
  end ;
  ret := ret || '<B>DB Vers : </B>' || tmp ;

  ret:= ret || '</TD>';
   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 3 / Column 2
   --
  ret:= ret || td ;
  begin
    SELECT VALUE
    into tmp
    FROM OTHER_INFORMATIONS
    WHERE DB_ID = P_DB_ID
    and   name='LOG_MODE';
   exception when no_data_found then tmp := null ;
  end ;
  ret := ret || '<B>AL : ' ;
  if (tmp = 'ARCHIVELOG' )
  then
    ret := ret || '<FONT color="green">';
  else
    ret := ret || '<FONT color="red">';
  end if ;
  ret:= ret || tmp;
  ret:= ret || '</B>';
  ret:= ret || '</TD>';
   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 3 / Column 3
   --
  ret:= ret || td ;
  begin
    SELECT 'Out of scope : ' || nvl(scope_exclusion_reason,'No reason given')
    into tmp
    FROM databases
    WHERE DB_ID = P_DB_ID
    and   in_scope='N';
   exception when no_data_found then tmp := null ;
  end ;
  if tmp is null
  then
    tmp:= '<FONT color=green>In scope</font>' ;
  else
    tmp:= '<FONT color=Red>'|| tmp || '</font>' ;
  end if ;
  ret := ret || tmp ;
  ret:= ret || '</TD>';
   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 3 / Column 4
   --
  ret:= ret || td ;
  ret:= ret || chr(amp)||'nbsp';
  ret:= ret || '</TD>';
  ret:= ret || '</TR>';
   -- -----------------------------------------------------------------------------------------
   --
   -- Line 4 / Column 1
   --

  ret:= ret || tr ;
  ret:= ret || td ;
  begin
    SELECT size_gb
    into tmp
    FROM DATABASES
    WHERE DB_ID = P_DB_ID ;
   exception when no_data_found then tmp := null ;
  end ;
  ret := ret || '<B>Sz GB : </B>' || tmp ;

  begin
    select to_char(to_number (replace(value,',','.')),'999G999D99')
    into   tmp
    from   OTHER_INFORMATIONS
    where  DB_ID = P_DB_ID
    and    name='SEGMENTS_SIZE_GB' ;
   exception when no_data_found then tmp := null ;
  end ;
  ret := ret || ' (' || tmp || ')' ;
  ret:= ret || '</TD>';
   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 4 / Column 2
   --
  ret:= ret || td ;
  begin
    SELECT source_value
    into tmp
    FROM db_nls_parameters
    WHERE DB_ID = P_DB_ID
    and   parameter='NLS_CHARACTERSET'
    and   rownum=1;
   exception when no_data_found then tmp := null ;
  end ;
  ret := ret || '<B>CS : </B>' || tmp ;

  ret:= ret || chr(amp)||'nbsp</TD>';
   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 4 / Column 3
   --
  ret:= ret || td ;

    begin
    select
      case when db.env_name in ('Production', 'Pre-production') then
          case when po.target_date is not null then
               BCR.PREPA_CHG_NUMBER
          else
              'Not planned'
          end
      else
          'NONPROD'
      end CHG,
      case when db.env_name in ('Production', 'Pre-production') then
          case when po.target_date is not null
                  then 'prepa'
            else '' end
      else '' end step
    into tmp,tmp2
    from migration_attempts MA
      inner join v_databases db on (db.db_id = ma.db_id)
      left join migration_planned_operations po      on (po.mig_id = ma.mig_id
                                                     and po.mls_id = mf_mig_parameters.get_id('MLS_ID_GOLIVE_START','BNP')
                                                     and po.CURRENT_PLAN = 'Y')
      left join CHANGES_REF               BCR     on  bcr.db_id = ma.db_id
    where
      MA.DB_ID = P_DB_ID
      and    MA.current_attempt = 'Y' ;
    exception when no_data_found then tmp := null ;
  end ;

  if tmp2 is not null then
    tmp2 := '(' || tmp2 || ')';
  end if;
  if substr(tmp,1,3) = 'CHG' THEN
    tmp2  := '<a target="_blank" href="https://bnpp.service-now.com/change_request.do?sys_id='||regexp_substr(tmp, '\S+')||'">' || tmp || '</a> '||tmp2;
  else
    tmp2  := tmp ||' '|| tmp2;
  end if;

  ret := ret || '<B>CHG: </B>' || tmp2;

  ret:= ret || chr(amp)||'nbsp';
  ret:= ret || '</TD>';

   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 4 / Column 4
   --
  ret:= ret || td ;


  -- begin
  --   SELECT st.seq_num || '-' || st.name
  --   into   tmp
  --   FROM   migration_attempts ma
  --   join   v_database_migration_statuses st on (st.mig_id = ma.mig_id)
  --   WHERE  ma.DB_ID = P_DB_ID
  --   and    ma.current_attempt ='Y';
  --  exception when no_data_found then tmp := null ;
  -- end ;
  -- ret := ret || '<B><FONT color="blue">' || tmp || '</FONT></B>';

  begin
    select
      case when db.env_name in ('Production', 'Pre-production') then
          case when po.target_date is not null --then
              -- case when trunc(sysdate) <  po.TARGET_DATE
              --     then BCR.PREPA_CHG_NUMBER
              --     when sysdate >= trunc(po.TARGET_DATE)
                  then BCR.GL_CHG_NUMBER
              --end
          else
              'Not planned'
          end
      else
          'NONPROD'
      end CHG,
      case when db.env_name in ('Production', 'Pre-production') then
          case when po.target_date is not null --then
              -- case when trunc(sysdate) <  po.TARGET_DATE
              --     then 'prepa'
              --     when sysdate >= trunc(po.TARGET_DATE)
                  then 'switch'
              --end
            else '' end
      else '' end step
    into tmp,tmp2
    from migration_attempts MA
      inner join v_databases db on (db.db_id = ma.db_id)
      left join migration_planned_operations po      on (po.mig_id = ma.mig_id
                                                     and po.mls_id = mf_mig_parameters.get_id('MLS_ID_GOLIVE_START','BNP')
                                                     and po.CURRENT_PLAN = 'Y')
      left join CHANGES_REF               BCR     on  bcr.db_id = ma.db_id
    where
      MA.DB_ID = P_DB_ID
      and    MA.current_attempt = 'Y' ;
    exception when no_data_found then tmp := null ;
  end ;

  if tmp2 is not null then
    tmp2 := '(' || tmp2 || ')';
  end if;
  if substr(tmp,1,3) = 'CHG' THEN
    tmp2  := '<a target="_blank" href="https://bnpp.service-now.com/change_request.do?sys_id='||regexp_substr(tmp, '\S+')||'">' || tmp || '</a> '||tmp2;
  else
    tmp2  := tmp ||' '|| tmp2;
  end if;

  ret := ret || '<B>CHG: </B>' || tmp2;

  ret := ret || ' ' ;
  ret:= ret || '</TD></TR>';

-- -----------------------------------------------------------------------------------------
   --
   -- Line 5 / Column 1
   --

  ret:= ret || tr ;
  ret:= ret || td ;
  begin
    SELECT flow_state
    into tmp
    FROM FLOWS_REF
    WHERE DB_ID = P_DB_ID
    AND   FLOW_TYPE = 'SRC-TGT' ;
   exception when no_data_found then tmp := null ;
  end ;
  if substr(tmp,1,6) = 'OPENED' then
    ret := ret || '<B>Flow SRC &#8596 TGT: </B><FONT color=green>'|| tmp ||'</font>';
  else
    ret := ret || '<B>Flow SRC &#8596 TGT: </B><FONT color=red>'|| tmp ||'</font>';
  end if;

  begin
    select
        case
            when flow_request is not null then ' (<a target="_blank" href="https://marketplace.group.echonet/service-flow-management/requests?ref='||flow_request||'">'||flow_request||'</a>)'
            else ''
        end
    into   tmp
    from   FLOWS_REF
    where  DB_ID = P_DB_ID
    and    FLOW_TYPE = 'SRC-TGT' ;
   exception when no_data_found then tmp := null ;
  end ;
  ret := ret || tmp ;
  ret:= ret || '</TD>';
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 5 / Column 2
   --
  ret:= ret || td ;
  begin
    SELECT flow_state
    into tmp
    FROM FLOWS_REF
    WHERE DB_ID = P_DB_ID
    AND   FLOW_TYPE = 'MF-SRC' ;
   exception when no_data_found then tmp := null ;
  end ;

  if substr(tmp,1,6) = 'OPENED' then
    ret := ret || '<B>Flow MF &#8596 SRC: </B><FONT color=green>'|| tmp ||'</font>';
  else
    ret := ret || '<B>Flow MF &#8596 SRC: </B><FONT color=red>'|| tmp ||'</font>';
  end if;

  begin
    select
        case
            when flow_request is not null then ' (<a target="_blank" href="https://marketplace.group.echonet/service-flow-management/requests?ref='||flow_request||'">'||flow_request||'</a>)'
            else ''
        end
    into   tmp
    from   FLOWS_REF
    where  DB_ID = P_DB_ID
    and    FLOW_TYPE = 'MF-SRC' ;
   exception when no_data_found then tmp := null ;
  end ;
  ret := ret || tmp ;
  ret:= ret || '</TD>';
   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 5 / Column 3
   --
  ret:= ret || td ;
  ret:= ret || chr(amp)||'nbsp';
  ret:= ret || '</TD>';

   -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   --
   -- Line 5 / Column 4
   --
  ret:= ret || td ;
  ret:= ret || chr(amp)||'nbsp';
  ret := ret || '</TD></TR></TABLE></FONT>'  ;

  return(ret) ;
end ;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Execute the routine action using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
procedure p3503_quick_plan_wbp(P_GLOB_PRJ_NAME in varchar2
                              ,P_P3503_GL_DATE in varchar2
                              ,P_P3503_DB_ID in varchar2
                              ,P_P3503_MIG_ID in varchar2
                              ,P_P3503_OVERNIGHT in out varchar2
                              ,P_P3503_DESIRED_ZDM_TYPE in varchar2
                              ) is
  gl_date date  ;
  mig_date date ;
  term_date date ;
  in_wave_date date ;
  wave_start_date date ;
  wave_end_date date ;
  real_zdm_type varchar2(20) ;
  tmp number ;
  environment varchar2(100) ;
  block_reason varchar2(100) ;

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Execute the routine action using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  procedure setMilestone(p_mig_id in number,p_seq_num in number,p_dat in date) is
    tmp number ;
    l_mls_id number ;
    begin

--      mf_utils.trace(p_mig_id || ' ' || p_seq_num || ' --> ' || p_dat || ': Satrt') ;
      select mls_id
      into   l_mls_id
      from   milestones
      where  prj_name = P_GLOB_PRJ_NAME
      and    plan_type='MIGRATION'
      and    seq_num =p_seq_num ;

    --raise_application_error(-20000,'Mls_id: ' || l_mls_id) ;

      select count(*)
      into   tmp
      from   migration_planned_operations
      where  mig_id = p_mig_id
      and    mls_id = l_mls_id
      and    current_plan='Y';
    --raise_application_error(-20000,'tmp: ' || tmp) ;
      if (tmp = 0)
      then
        insert into migration_planned_operations
          (mig_id,mls_id,target_date,current_plan,prj_name)
        values
          (p_mig_id,l_mls_id,p_dat,'Y',P_GLOB_PRJ_NAME) ;
    --raise_application_error(-20000,'Insert: ' || sqlcode) ;
      else
    --  raise_application_error(-20000,'Update: ' || P_MIG_ID || ' mls: ' || l_mls_id || ' date:' || p_dat) ;
        update migration_planned_operations
        set    target_date = p_dat
        where  mig_id=P_MIG_ID
        and    mls_id = l_mls_id
        and    current_plan='Y';
    --  raise_application_error(-20000,'Update: ' || sqlcode|| ' ' || sql%rowcount) ;
      end if ;
  end ;


begin

  if (length(P_P3503_GL_DATE) = 16)
  then
    gl_date := to_date(P_P3503_GL_DATE,'dd/mm/yyyy hh24:mi') ;
  else
    gl_date := to_date(P_P3503_GL_DATE,'dd/mm/yyyy hh24:mi:ss') ;
  end if ;
  --
  --  Check GL date
  --   - relative to the date the database was added into the WAVE
  --   - in the wave timeframe
  --   - in the future
  --
  --

  -- Block public holidays
  select count(*) into tmp from pm_public_holiday where effective_date = trunc(gl_date);
  if (tmp > 0) then
    raise_application_error(-20000, gl_date||' is public holiday. Please choose another Go Live date.');
  end if ;

  -- Block freeze periods
  select count(*) into tmp  from pm_freezes where trunc(gl_date) between start_date and end_date;
  if (tmp > 0) then
    select nvl(comments, 'undefined') into block_reason from pm_freezes where trunc(gl_date) between start_date and end_date;
    raise_application_error(-20000, 'Cannot plan due to following operations : '||block_reason||' - Please choose another Go Live date.');
    -- apex_error.add_error(p_message          => 'Cannot plan due to following operations : '||block_reason||' - Please choose another Go Live date.',
    --                      p_display_location => apex_error.c_inline_in_notification);
  end if ;

  -- Block weekend for NON-PROD
  select env_name into environment from v_databases where db_id = P_P3503_DB_ID;
  if (to_char(gl_date,'DY','NLS_DATE_LANGUAGE=ENGLISH') in ('SAT','SUN') AND environment not in ('Pre-production','Production') )  then
    raise_application_error(-20000, gl_date||' is a weekend day. NON PROD cannot be migrated on Weekend. Please choose another Go Live date.');
  end if ;

  -- Can be bypassed by Adminsitrators
  if not apex_authorization.is_authorized(p_authorization_name => 'Administration Rights')
  then
    if (gl_date < sysdate)
    then
      raise_application_error(-20000,'Cannot plan a go-live in the past');
    end if ;
    begin
      select
         dw.create_date
        ,wa.target_start
        ,wa.target_end
      into
         in_wave_date
        ,wave_start_date
        ,wave_end_date
      from
        db_in_waves dw
        join waves wa on (wa.wav_id = dw.wav_id)
      where
            dw.db_id = P_P3503_DB_ID
        and wa.type = 'Migration' ;
    exception when no_data_found then raise_application_error(-20000,'Cannot plan a database which is not in a migration wave') ;
    end ;
    if ( sysdate > trunc(wave_start_date) )
    then
      raise_application_error(-20000,'BIUR_MIGRATION_PLANNED_OPERATIONS: Cannot plan a go-live when the wave has already started, contact an ADMINISTRATOR if this date is mandatory');
    end if ;
    if ( (wave_start_date - sysdate) < mf_utils.getParameter('MF_NOW_WAVESTART_DELAY',P_GLOB_PRJ_NAME) )
    then
      raise_application_error(-20000,'BIUR_MIGRATION_PLANNED_OPERATIONS: Cannot plan a go-live less than ' || mf_utils.getParameter('MF_NOW_WAVESTART_DELAY',P_GLOB_PRJ_NAME) || ' days before the start date of the related wave, contact an ADMINISTRATOR if this date is mandatory');
    end if ;
    if ( (gl_date - in_wave_date) < mf_utils.getParameter('MF_WAVE_GL_DELAY',P_GLOB_PRJ_NAME) )
    then
      raise_application_error(-20000,'Cannot plan a go-live less than ' || mf_utils.getParameter('MF_WAVE_GL_DELAY',P_GLOB_PRJ_NAME) || ' days after the database has been added in the migration wave, contact an ADMINISTRATOR if this date is mandatory');
    end if ;
    if ( (gl_date - sysdate) < mf_utils.getParameter('MF_NOW_GL_DELAY',P_GLOB_PRJ_NAME) )
    then
      --raise_application_error(-20000, 'QMA' || (gl_date - sysdate));
      raise_application_error(-20000,'Cannot plan a go-live less than ' || mf_utils.getParameter('MF_NOW_GL_DELAY',P_GLOB_PRJ_NAME) || ' days from now contact an ADMINISTRATOR if this date is mandatory');
    end if ;
    if (gl_date < wave_start_date or gl_date > trunc(wave_end_date)+1)
    then
      raise_application_error(-20000,   'Cannot plan a go-live outside the wave start and end dates , contact an ADMINISTRATOR if this date is mandatory. Go-live : '
                                     || to_char(gl_date,'dd/mm/yyyy hh24:mi:ss')
                                     || ' Wave : ' || to_char(wave_start_date,'dd/mm/yyyy')
                                     || ' --> ' || to_char(wave_end_date,'dd/mm/yyyy'));
    end if ;
  end if ;
 --
  --    Ctrl Type
  --
  if (P_P3503_DESIRED_ZDM_TYPE = 'ONLINE_LOGICAL')
  then
    select count(*)
    into   tmp
    from   other_informations
    where  db_id = P_P3503_DB_ID
    and    name = 'LOG_MODE'
    and    value = 'ARCHIVELOG' ;
    tmp := 1 ;
    if ( tmp = 0 )
    then
      raise_application_error(-20000,'This migration mode is not possible for this database') ;
    end if ;
    P_P3503_OVERNIGHT := 'N' ;
  end if ;
  --
  --  UPdate MA
  --
  update migration_attempts
  set    desired_zdm_type = decode(P_P3503_DESIRED_ZDM_TYPE,'DEFAULT',null,P_P3503_DESIRED_ZDM_TYPE)
        ,overnight_migration = P_P3503_OVERNIGHT
  where  mig_id = P_P3503_MIG_ID ;

  update migration_attempts
  set    target_dbname = 'TOCREATE'
        ,target_service = 'TOCREATE'
        ,target_dbuniquename = 'TOCREATE'
        ,target_container_service = 'TOCREATE'
  where  mig_id = P_P3503_MIG_ID
  and    not regexp_like (target_container_service,'^C.*M[0-9]$');

  --
  --  Set dates
  --
  -- QMA : quick fix 241 -> 242 | todo: implement a dynamic way to retrieve the right id for concerned milestones
  setMilestone(P_P3503_MIG_ID,mf_mig_parameters.get_seq('MLS_GOLIVE_START'),gl_date) ; -- Go for switch
  setMilestone(P_P3503_MIG_ID,mf_mig_parameters.get_seq('MLS_GOLIVE_END'),gl_date) ; -- Validation = Switch

  term_date := trunc(gl_date) + 32 ;
  if (TRUNC(term_date) - TRUNC(term_date, 'IW') + 1) = 6 then term_date := term_date + 2 ; end if ;
  if (TRUNC(term_date) - TRUNC(term_date, 'IW') + 1) = 7 then term_date := term_date + 1 ; end if ;
  term_date := term_date + (9/24) ;
  setMilestone(P_P3503_MIG_ID,mf_mig_parameters.get_seq('MLS_TERMINATED'),term_date) ; -- Termination = Switch + 32 (or next monday)

  if (P_P3503_DESIRED_ZDM_TYPE = 'DEFAULT')
  then
    begin
      select decode (value,'ARCHIVELOG','ONLINE_LOGICAL','OFFLINE_LOGICAL')
      into   real_zdm_type
      from   other_informations
      where  db_id = P_P3503_DB_ID
      and    name = 'LOG_MODE' ;
    exception when others then real_zdm_type := null ;
    end ;
  else
    real_zdm_type := P_P3503_DESIRED_ZDM_TYPE ;
  end if ;

  if (real_zdm_type is not null )
  then
    if ( real_zdm_type = 'OFFLINE_LOGICAL')
    then
      if ( P_P3503_OVERNIGHT = 'N' )
      then
        --
        --  Same DAY
        --
        mig_date := gl_date ;
      else
        --
        --  Previous day 18:00 or previous friday ==> The migration must be scheduled
        --
         mig_date := trunc(gl_date-1) ;
        if (TRUNC(mig_date) - TRUNC(mig_date, 'IW') + 1) = 7 then mig_date := mig_date - 2  ; end if ;
        if (TRUNC(mig_date) - TRUNC(mig_date, 'IW') + 1) = 6 then mig_date := mig_date - 1 ; end if ;
        mig_date := mig_date + (18/24) ;
      end if ;
    else
      --
      -- Five days before 18:00 or previous friday
      --
         mig_date := trunc(gl_date-5) ;
        if (TRUNC(mig_date) - TRUNC(mig_date, 'IW') + 1) = 7 then mig_date := mig_date - 2  ; end if ;
        if (TRUNC(mig_date) - TRUNC(mig_date, 'IW') + 1) = 6 then mig_date := mig_date - 1 ; end if ;
        mig_date := mig_date + (18/24) ;
      end if ;
    setMilestone(P_P3503_MIG_ID,mf_mig_parameters.get_seq('MLS_MIG_GO'),mig_date) ;
  end if ;
end ;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function  p3109_getMessage(d in date,t in varchar2 default 'N', f in varchar2 default 'N',day_only in varchar2 default 'N') return varchar2 is
    tmp           varchar2(32767) ;
    bu            varchar2(50);
    select_date   date ;
    next_week     number := 4 ;
    l_start_date  date ;
    day_num       number ;
    total number := 0;
    sub_total number := 0;
    l_days number := 6 ;
    /*
     *
     * ----------------------------------------------------------------------------
     *  Algorithm
     *  ---------
     *
     *        Compute and return the routine result using the package state, input parameters, SQL statements,
     *    and external API calls implemented below.
     *
     *  Possible Issues
     *  ---------------
     *
     *       - Generated documentation: review input validation, exception handling,
     *         and assumptions about data cardinality before changing the code.
     *       - SQL queries and external package calls may propagate runtime errors
     *         unless they are explicitly handled in the implementation.
     *
     * ----------------------------------------------------------------------------
     *
     */
    function prLine(
                   dat  in varchar2
                  ,db   in varchar2
                  ,flx  in varchar2
                  ,mls  in varchar2
                  ,tdb  in varchar2
                  ,zty  in varchar2
                  ,sub  in varchar2
                  ,ope  in varchar2) return varchar2 is
    begin
      return('<TR>' ||
            '<TD>' || dat || '</TD>' ||
            '<TD>' || db  || '</TD>' ||
            case f when 'Y' then '<TD>' || flx || '</TD>' else null end ||
            '<TD>' || mls || '</TD>' ||
            '<TD>' || tdb || '</TD>' ||
            '<TD>' || zty || '</TD>' ||
            '<TD>' || sub || '</TD>' ||
            '<TD>' || ope || '</TD>' ||
            '</TR>') ;
    end ;
  begin
    select_date := trunc(d) ;
    day_num := case substr(to_char(select_date,'DY','NLS_DATE_LANGUAGE=FRENCH'),1,3)
                 when 'LUN' then 1
                 when 'MAR' then 2
                 when 'MER' then 3
                 when 'JEU' then 4
                 when 'VEN' then 5
                 when 'SAM' then 6
                 when 'DIM' then 7
               end ;
    if ( day_only = 'N' )
    then
      if ( day_num >= next_week)
      then
        l_start_date := select_date + 7 - day_num +1 ; --next monday
      else
        l_start_date := select_date - day_num + 1 ; --previous monday
      end if ;
    else
      l_start_date := trunc(select_date) ;
      l_days := 1 ;
    end if ;
    tmp := '<HTML>';
--    tmp := tmp || day_num || ' ' || to_char(select_date,'DY','NLS_DATE_LANGUAGE=FRENCH') || '<BR>' ;
    tmp := tmp || 'Bonjour<BR>' ;
    if ( day_only = 'N' )
    then
       tmp := tmp || 'Les bases suivantes sont programmees pour une bascule dans la semaine du : <B>' || to_char(l_start_date,'DD/mm/YYYY') || '</B> au <B>' || to_char(l_start_date+6,'DD/mm/YYYY') ||'</B>.' ;
    else
       tmp := tmp || 'Les bases suivantes sont programmees pour une bascule le : <B>' || to_char(l_start_date,'DD/mm/YYYY') ||'</B>.' ;
    end if ;
    if ( t = 'Y')
    then
      tmp := tmp || '<BR>' ;
      tmp := tmp || 'Nous vous rapellons certaines choses afin que la bascule se passe au mieux<BR>' ;
      tmp := tmp || '<LI><B>Merci de vous assurer que les flux entre l''application et l''ExaCC sont bien ouverts avant la migration.</B></LI>' ;
      tmp := tmp || '<LI>A partir de l''heure de la migration, l''application ne <B>doit PLUS intervenir sur sa base</B> et ne <B>surtout pas dÃ©verrouiller les utilisateurs</B> par elle-mÃªme.</LI>' ;
      tmp := tmp || '<LI>L''heure indiquee est l''heure theorique de <B>demarrage de la bascule</B>.Vous pouvez stopper l''application sans attendre notre GO</LI>' ;
      tmp := tmp || '<LI>Pour les migrations OFFLINE (Overnight), la copie de la base est faite de nuit, elle est programmee a une heure tardive. Le relancement de l''application se fait apres verification de la migration.</LI>' ;
      tmp := tmp || '<LI>Assurez-vous que la personne en charge des operations ait bien la <B>chaine de connexion</B></LI>' ;
      tmp := tmp || '<LI>Au moment de la bascule, les users sur la source sont <B>verrouilles</B>, il ne faut pas les deverrouiller</LI>' ;
      tmp := tmp || '<LI>Pour les migrations OFFLINE (Live), il faut compter le temps de copie de la base</LI>' ;
    end if ;
    for mig in (
              select
                 po.target_date
                ,db.bu_name
                ,db.source_dbname || ' (' || listagg(lower(dw.wave_name),',') over (partition by po.target_date
                                                                                                ,db.bu_name
                                                                                                ,db.source_dbname) || ')'
                                  || case db.in_scope
                                     when 'N' then '<B><FONT color="red">OUT OF SCOPE</font></B>'
                                     else ''
                                     end  source_dbname
                ,db.source_oracle_sid
                ,st.seq_num || '-' || st.DESCRIPTION milestone
                ,ma.TARGET_DBNAME
                ,ma.zdm_type || case zdm_type
                                  when 'OFFLINE_LOGICAL' then
                                    case overnight_migration
                                      when 'Y' then '<BR>(Overnight - <BR>Stop application a 18:00)'
                                      else '<BR>(Live - Stop au moment de la bascule )'
                                    end
                                  else ''
                                end zdm_type
                ,ma.CLT_PDB_SUBSCRIPTION
                ,co.FIRST_NAME || ' ' || co.LAST_NAME operator
                ,case f
                   when 'Y' then case
                     when sn.snod_id is not null then
--                           cast (mf_utils.runAnyCommand('echo -n ''' || db.source_dbname || '(' || db.env_name ||')'|| '@' || sc.scan_ip ||':' || sc.scan_port || '  --/--  ''' ||
                           cast (mf_utils.runAnyCommand('ssh -o strictHostKeyChecking=no opc@' ||tn.fqdn || ' timeout 2 curl -s http://'|| sc.scan_ip || ':' || sc.scan_port ||
                                          ' ; if [ $? -eq 0 -o $? -eq 52 ] ; then echo ''<font color="green">Ouvert</font>'' ; else echo ''<font color="green"><B>Ferme</B></font>'' ; fi',po.prj_name) as varchar2(4000))
                     else 'Cible non definie'
                   end
                   else 'Non teste'
                 end check_result
              from
                MIGRATION_PLANNED_OPERATIONS       po
                join migration_attempts            ma on (po.mig_id = ma.mig_id)
                join v_database_migration_statuses st on (st.db_id  = ma.db_id)
                join v_databases                   db on (db.db_id  = ma.db_id)
                join source_clusters               sc on (db.sclu_id = sc.sclu_id)
                join source_nodes                  sn on (sn.sclu_id = sc.sclu_id)
                left join v_db_in_waves            dw on (ma.db_id = dw.db_id and wave_type = 'Migration')
                left join mig_roles                     mr on (mr.mig_id = ma.mig_id)
                left join contacts                      co on (co.cnt_id = mr.cnt_id)
                left join target_clusters          tc on (tc.tclu_id = ma.tclu_id )
                left join target_nodes             tn on (tn.tclu_id = tc.tclu_id and tn.ord_num=1)
              WHERE
                    po.mls_id = mf_mig_parameters.get_id('MLS_ID_GOLIVE_START',po.prj_name)
                and po.current_plan = 'Y'
                and ma.current_attempt='Y'
                and trunc(po.target_date) >= l_start_date and trunc(po.target_date)  < trunc(l_start_date + l_days)
                and  db.in_scope='Y'
--                and rownum=1
--                and po.target_date between sysdate and sysdate + 7
              order by
                 db.bu_name
                ,po.target_date
                ,db.source_dbname)
    loop
      total := total + 1 ;
      sub_total := sub_total + 1 ;
      if (nvl(bu,'$$') != mig.bu_name)
      then
        if bu is not null
        then
          tmp := tmp || '</TABLE>' ;
          tmp := tmp || 'Number of databases for ' || bu || ' : ' || (sub_total -1) ;
          sub_total := 1 ;
        end if ;
        tmp := tmp || '<H3>Business Unit : ' || mig.bu_name || '</H3>' ;
        tmp := tmp || '<TABLE border=1>' ;
        tmp := tmp || prLIne ('Switch date','Source DBNAME','Flux','Milestone','Cible','Type de migration','Souscription PDB','Operateur') ;
        bu := mig.bu_name ;
      end if ;
      tmp := tmp || prLIne (to_char(mig.target_date,'dd/mm HH24:mi'),mig.source_dbname,mig.check_result,mig.milestone,mig.target_dbname,mig.zdm_type,mig.clt_pdb_subscription,mig.operator) ;
    end loop ;
    tmp := tmp || '</TABLE>' ;
    tmp := tmp || 'Number of databases for ' || bu || ' : ' || (sub_total) ;
    if ( day_only = 'N' )
    then
      tmp := tmp || '<BR><BR><B>Total number of databases for the week</B> : ' || total ;
    else
      tmp := tmp || '<BR><BR><B>Total number of databases for the day</B> : ' || total ;
    end if ;
    tmp := tmp || '</HTML>' ;
    return(tmp) ;
  end ;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Execute the routine action using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  procedure p20050_triggerCreateUser
  is
  l_job_name varchar2(100);
  begin
   --DBMS create job type PL/SQL ; action: apex_util.create_user

    l_job_name := DBMS_SCHEDULER.generate_job_name;

    /*l_script := startOfShell (p_project)  ;
    l_script := l_script || '{ ' || p_shellBlock || '; } 2>'||chr(amp)||'1'  ;
    if ( p_printOutput )
    then
      message('----- Script ---------------------------------------------------------------',p_ts=>false) ;
      message(l_script,p_ts=>false) ;
      message('----- Script END -----------------------------------------------------------',p_ts=>false) ;
    end if ;
    */
    /*DBMS_SCHEDULER.create_job(
      job_name            => l_job_name,
      job_type            => 'PL/SQL',
      job_action          => ,
      repeat_interval     => 'freq=secondly; bysecond=5',
  		end_date            => NULL,
  		enabled             => FALSE,
  		auto_drop           => TRUE,
  		comments            => ''
    );
    */
  	dbms_scheduler.run_job(job_name  =>  l_job_name,
										use_current_session  =>  FALSE);
  end;



/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */



  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Execute the routine action using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  procedure p20050_removeUser(    user_name                       in varchar2) is
  l_workspace_id number;
  BEGIN null ;
    mf_utils.message('Create user (start)',p_ts=>false) ;
    /*--------------------------------------------------------------------
	  	Get the workspace id
  	--------------------------------------------------------------------*/
    l_workspace_id := apex_util.find_security_group_id (p_workspace => 'MFBNP');
    mf_utils.message('Workspace : MFBNP' || ' ID: ' || l_workspace_id,p_ts=>false) ;

    /*--------------------------------------------------------------------
		  One final check to make sure the username is unique
	  --------------------------------------------------------------------*/
  	if APEX_UTIL.IS_USERNAME_UNIQUE(user_name) != TRUE
    then
      /*--------------------------------------------------------------------
  		  Set the SGID based on the workspace
  	   --------------------------------------------------------------------*/
  	  apex_util.set_security_group_id(p_security_group_id => l_workspace_id);

      mf_utils.message('Call Apex_util','p_ts=>false') ;
      apex_util.remove_user (
  	      			p_user_name						          =>	user_name
                );
    else
      mf_utils.message('USER does not exist',p_ts=>false) ;
    end if ;
  end;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Execute the routine action using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  procedure p20050_createUser(
    user_name                       in varchar2,
    first_name                      in varchar2 default 'First Name',
    last_name                       in varchar2 default 'Last Name',
    email_address                   in varchar2 default 'user@acme.com',
    temp_web_password               in varchar2 default 'Wel_Come_@MF_00'
    ) is
    l_workspace_id number;

  begin

  mf_utils.message('Create user (start)',p_ts=>false) ;
  /*--------------------------------------------------------------------
		Get the workspace id
	--------------------------------------------------------------------*/
  l_workspace_id := apex_util.find_security_group_id (p_workspace => 'MFBNP');
  mf_utils.message('Workspace : MFBNP' || ' ID: ' || l_workspace_id,p_ts=>false) ;

  /*--------------------------------------------------------------------
		One final check to make sure the username is unique
	--------------------------------------------------------------------*/
	if APEX_UTIL.IS_USERNAME_UNIQUE(user_name) = TRUE
  then
    /*--------------------------------------------------------------------
  		Set the SGID based on the workspace
  	--------------------------------------------------------------------*/
  	apex_util.set_security_group_id(p_security_group_id => l_workspace_id);

   mf_utils.message('Call Apex_util','p_ts=>false') ;
  apex_util.create_user (
  				p_user_name						          =>	user_name,
  				p_first_name					          =>	first_name,
  				p_last_name						          =>	last_name,
  				p_email_address			            =>	email_address,
  				p_web_password				          =>	temp_web_password,
          p_developer_privs               => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL'
              );
    else
      mf_utils.message('USER already exist',p_ts=>false) ;
    end if;
  end;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function  getTimelineToolTip         ( p_mig_id                 in migration_attempts.mig_id%type
                                        ,p_golive_date            in date
                                      ) return varchar2 is
    tmp varchar2(4000) ;
    days number := trunc(p_golive_date) - trunc(sysdate) ;
    err boolean := false ;
  BEGIN
    for attData in (select
                       ma.target_container_service
                      ,ma.target_dbname
                      ,ma.under_synch
                      ,ma.zdm_type
                      ,db.source_dbname
                      ,db.env_name
                      ,db.group_bu
                      ,st.seq_num
                      ,ap.clt_realm_npr
                      ,ap.clt_realm_prd
                    from
                      MIGRATION_ATTEMPTS ma
                      join v_databases db on (db.db_id = ma.db_id)
                      join v_database_migration_statuses st on (ma.mig_id = st.mig_id)
                      join DB_APPS da on (da.db_id = ma.db_id)
                      join applications ap on (ap.app_id = da.app_id)
                    WHERE
                      ma.mig_id = p_mig_id
                   )
    loop
      tmp := attData.group_bu || ': ' || attData.source_dbname || ' --> ' || attData.target_dbname || ' ('|| attData.env_name||')'  ;
      if ( attData.seq_num < 250 )
      then
        if (days >0 )
        then
          tmp := tmp || ' / ' ||to_char(abs(days)) || ' Days before go-live' ;
        else
          tmp := tmp || ' / ' ||to_char(abs(days)) || ' Days PAST go-live' ;
        end if ;
      end if ;
      if ( days <= 14 )
      then
        if (attData.env_name = 'Production' and attData.clt_realm_prd is null)
        then
          err := true ; tmp := tmp || ' / ' || 'PRODUCTION realm not defined'  ;
        end if ;
        if (attData.env_name != 'Production' and attData.clt_realm_npr is null)
        then
          err := true ; tmp := tmp || ' / ' || 'NON PRODUCTION realm not defined'  ;
        end if ;
      end if ;
      if ( days <= 10 )
      then
        if (   not regexp_like(attData.target_container_service,'C[0-9A-F]*M[123]')
            or attData.target_container_service = 'TOCREATE'
            or attData.target_dbname = 'TOCREATE')
        THEN
          err := true ; tmp := tmp || ' / ' || 'Target database not created via the MARKETPLACE'  ;
        end if ;
      end if ;
      if ( days <= 5 )
      then
        if (attData.seq_num < 220)
        then
          err := true ; tmp := tmp || ' / ' || 'Not ''ready to migrate'' (' || attData.seq_num || ')' ;
        end if ;
        if ( attData.zdm_type = 'ONLINE_LOGICAL')
        THEN
          if (attData.under_synch = 'NO')
          THEN
            err := true ; tmp := tmp || ' / ' || 'DB not synched by OGG'' (' || attData.seq_num || ')' ;
          end if ;
        end if ;
      end if ;
      if ( days <= 3 )
      then
        if ( attData.zdm_type = 'ONLINE_LOGICAL')
        THEN
          if (attData.seq_num < 240)
          then
            err := true ; tmp := tmp || ' / ' || 'Technical tests not done or runbook not updated (' || attData.seq_num || ')' ;
          end if ;
        end if ;
      end if ;
      if ( days < 0 )
      then
        if (attData.seq_num < 260)
        then
          err := true ; tmp := tmp || ' / ' || 'NOT Migrated yet (' || attData.seq_num || ')' ;
        end if ;
      end if ;
    end loop ;
    if (err)
    then
      tmp := tmp || ' (ERROR)' ;
    end if ;
    return (tmp) ;
  end ;
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Execute the routine action using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  procedure cleanCrashedBatches is
  begin
    merge into batch_executions be
    using (
            select
               b.bat_id
              ,j.job_name
              ,b.progress
              ,nvl(j.mess,'Crashed and purged') mess
            from
              (   select
                    job_name
                    ,regexp_replace(job_name,'^MF\$BATCH\$MIGID_([0-9]+)_BATID_([0-9]+)$','\2') bat_id
                    ,nvl(errors,output) mess
                  from
                    user_scheduler_job_run_details
                  where
                        status = 'FAILED'
                    and regexp_like(job_name,'^MF\$BATCH\$MIGID_([0-9]+)_BATID_([0-9]+)$')  ) j
              right join batch_executions b on (b.bat_id = j.bat_id )
            where
              b.progress != 'COMPLETED'
              and not exists (select 1 from user_scheduler_jobs
                              where regexp_like(job_name,'^MF\$BATCH\$MIGID_([0-9]+)_BATID_([0-9]+)$')
                              and   regexp_replace(job_name,'^MF\$BATCH\$MIGID_([0-9]+)_BATID_([0-9]+)$','\2') = b.bat_id)
         ) res
    on (res.bat_id = be.bat_id)
    when matched then
      update set
         progress='COMPLETED'
        ,return_code=1
        ,error_message = substr('Job ' || res.job_name || ' failed : ' || mess,1,200)
        ,end_date = start_date ;
  end ;

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function  batchCommand               ( p_shellBlock        in varchar2
                                        ,p_label             in varchar2  default 'Batch scipt'
                                        ,p_prj_name          in varchar2  default null
                                        ,p_script_name       in varchar2  default 'Any Script'
                                        ,p_script_parameters       in varchar2  default null
                                       ) return number is
--/* Test actions ***************************************************
--set SERVEROUTPUT on format wrapped size unlimited
--declare
--  fake_step v_migration_steps%rowtype ;
--begin
--  mf_apex_utils.batchedMigrationActivity(fake_step,'Test Batch',false) ;
--end ;
--/
--select * from batch_executions order by bat_id desc;
--******************************************************************* */
    l_bat_id number ;
    l_shell_command varchar2(32767) ;
    rc number ;
    l_batch_running number ;
  begin
    if ( p_prj_name is null)
    then
      raise_application_error(-20000,'batchCommand : PRJ_NAME is null, cannot continue' ) ;
    end if ;
    mf_utils.message('',p_ts => false ) ;
    mf_utils.message('Launching a batched GLOBAL action : ' || p_label) ;
    mf_utils.message('',p_ts => false ) ;

    cleanCrashedBatches ;
    --
    --   Test that this step is not already running
    --
    select   count(*)
    into     l_batch_running
    from     batch_executions
    where    script_name = p_script_name
    and      parameters  = p_script_parameters
    and      progress != 'COMPLETED'
    and      set_code = 'GLOBAL';
    if (l_batch_running>0 )
    then
      raise_application_error(-20000,'batchCommand : Some not COMPLETED executions of this batch (same script, parameters and set_code) have been found' ) ;
    end if ;
    --
    --   Create execution Lline
    --
    insert into batch_executions (prj_name                            , start_date      ,progress               ,description
                                 ,script_name
                                 ,parameters                          ,set_code)
    values                       (p_prj_name                          , sysdate          ,'LAUNCHING'            ,p_label
                                 ,regexp_replace(p_script_name,'^.*/','')
                                 ,p_script_parameters                 ,'GLOBAL')
    returning bat_id into l_bat_id;

    l_shell_command := l_shell_command   || chr(10) || 'export MFAUTO_BAT_ID=' || l_bat_id ;
    l_shell_command := l_shell_command   || chr(10) || p_shellBlock ;

    --
    --   Run the script, with a known job name
    --
    mf_utils.runCommand (l_shell_command
                        ,p_prj_name
                        ,p_printOutput => false
                        ,p_waitForCompletion => false
                        ,p_job_name => 'MF$BATCH$MIGID_00000_BATID_' || l_bat_id) ;

    update batch_executions set job_name='MF$BATCH$MIGID_00000_BATID_' || l_bat_id where bat_id=l_bat_id ;
    update batch_executions set progress='JOB_STARTED' where bat_id = l_bat_id ;
    commit ;
     return(0);
  end ;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Execute the routine action using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  procedure batchedMigrationActivity   ( p_migration_definition   in mf_mig_parameters.mig_def_t --in v_migration_steps%rowtype
                                        ,p_label                  in varchar2
                                        ,p_unicity_code           in varchar2  default 'GLOBAL'
                                        ,p_waitForCompletion      in boolean   default true
                                        ,p_printOutput            in boolean   default false
                                  )  AS
    l_shell_command varchar2(32767) := '' ;
    l_line          varchar2(4000) ;
--    l_mig           migration_attempts%rowtype ;
    l_mig           mf_mig_parameters.mig_t ;
--    l_db            databases%rowtype ;
    l_db           mf_mig_parameters.db_t ;
    l_batch_running number ;
    l_bat_id        number ;
--    l_migration_definition v_migration_steps%rowtype := p_migration_definition ;
    l_migration_definition mf_mig_parameters.mig_def_t := p_migration_definition ;

--/* Test actions ***************************************************
--set SERVEROUTPUT on format wrapped size unlimited
--declare
--  fake_step v_migration_steps%rowtype ;
--begin
--  fake_step.mig_id       := 1365               ; -- Existing MIG_ID 20967
--  fake_step.db_id        := 20967              ; -- Corresponding DB_ID
--  fake_step.script_name  := 'mfTestBatch.sh'   ; -- Script
--  fake_step.parameters   := '-i 1 - t 1'       ; -- Parameters
--  mf_apex_utils.batchedMigrationActivity(fake_step,'Test Batch',false) ;
--end ;
--/
--select * from batch_executions order by bat_id desc;
--******************************************************************* */
  BEGIN
    begin
      select --*
          PRJ_NAME
          ,MIG_ID
          ,CODE
          ,DATE_CREATED
          ,FIRST_OPERATION
          ,LAST_OPERATION
          ,STATUS
          ,DATE_CLOSED
          ,ZDM_TYPE
          ,ZDM_TRANSFERT_MODE
          ,TARGET_ADMIN_USER
          ,TARGET_DBNAME
          ,TARGET_DBUNIQUENAME
          ,TARGET_SERVICE
          ,TARGET_CONTAINER_ADMIN_USER
          ,TARGET_CONTAINER_SERVICE
          ,IS_TARGET_PDB
          ,UNDER_SYNCH
          ,SOURCE_EXTRACT
          ,TARGET_REPLICA
          ,TARGET_EXTRACT
          ,SOURCE_REPLICA
          ,DB_ID
          ,TCLU_ID
          ,ZDM_ID
          ,OGG_ID
          ,NAS_ID
          ,CUSTOMER_ID
          ,CREATE_DATE
          ,CREATED_BY
          ,UPDATE_DATE
          ,UPDATED_BY
          ,INITIAL_MTP_ID
          ,INITIAL_RBT_ID
          ,TECH_UUID
          ,CURRENT_ATTEMPT
          ,DESIRED_ZDM_TYPE
          ,OVERNIGHT_MIGRATION
          ,CLT_CDB_SUBSCRIPTION
          ,CLT_PDB_SUBSCRIPTION
          ,CLT_PROVISIONING_COMMENT
          ,CLT_CDB_DEMAND
          ,CLT_PDB_DEMAND
          ,SWITCH_OP_SCN
          ,LAST_SWITCH_OP
          ,MLS_ID
          ,TARGET_DB_TYPE
      into   l_mig
      from   migration_attempts
      where
        mig_id = l_migration_definition.mig_id ;
    exception when no_data_found then raise_application_error(-20000,'batchedMigrationActivity : Migration attempt #' || l_migration_definition.mig_id || ' not found' ) ;
    end ;


    if ( l_mig.status = 'ON-HOLD' )
    then
      raise_application_error(-20000,'batchedMigrationActivity : Migration attempt #' || l_migration_definition.mig_id || ' is ON-HOLD please release it before running any step' ) ;
    end if ;

    if ( l_mig.status != 'OPENED' )
    then
      raise_application_error(-20000,'batchedMigrationActivity : Migration attempt #' || l_migration_definition.mig_id || ' is ' || l_mig.status || ' no operations are possible' ) ;
    end if ;

     cleanCrashedBatches ;

    begin
      select --*
      PRJ_NAME
     ,DB_ID
     ,SOURCE_ADMIN_USER
     ,SOURCE_DBNAME
     ,SOURCE_DB_UNIQUENAME
     ,SOURCE_ORACLE_SID
     ,SOURCE_SERVICE
     ,IS_NON_CDB
     ,SOURCE_CONTAINER_ADMIN_USER
     ,SOURCE_CONTAINER_SERVICE
     ,ROLE
     ,IN_SCOPE
     ,SCOPE_EXCLUSION_REASON
     ,SIZE_GB
     ,SCLU_ID
     ,ENV_ID
     ,BU_ID
     ,VERSION
     ,CUSTOMER_ID
     ,CREATE_DATE
     ,CREATED_BY
     ,UPDATE_DATE
     ,UPDATED_BY
     ,TECH_UUID
     ,SCOPE_EXCLUSION_CODE
     ,CONFIDENTIALITY
     ,COMMENTS
     ,PROTOCOL
     ,PORT
     ,SCAN
      into   l_db
      from   databases
      where
        db_id = l_mig.db_id ;
    exception when no_data_found then raise_application_error(-20000,'batchedMigrationActivity : database #' || l_mig.db_id || ' not found' ) ;
    end ;


    --
    --   Get values from the existing attempt
    --
    l_migration_definition.prj_name            := l_mig.prj_name ;
    l_migration_definition.code                := l_mig.code ;
    l_migration_definition.zdm_type            := l_mig.zdm_type ;
    l_migration_definition.source_dbname       := l_db.source_dbname ;
    l_migration_definition.zdm_transfert_mode  := l_mig.zdm_transfert_mode ;


    --
    --   Test that this step is not already running
    --
    select   count(*)
    into     l_batch_running
    from     batch_executions
    where    script_name = l_migration_definition.script_name
    and      parameters  = l_migration_definition.parameters
    and      progress != 'COMPLETED'
    and      set_code = p_unicity_code;
    if (l_batch_running>0 )
    then
      raise_application_error(-20000,'batchedMigrationActivity : Some not COMPLETED executions of this batch (same script, parameters and set_code) have been found' ) ;
    end if ;


    if ( l_db.in_scope = 'N')
    then
        insert into batch_executions (prj_name        , start_date            ,end_date      , set_code
                                     ,return_code     , progress              ,description
                                     ,error_message
                                     ,script_name
                                     ,parameters)
        values                       (l_db.prj_name   ,sysdate                ,sysdate       ,p_unicity_code
                                     ,1               ,'COMPLETED'            ,p_label
                                     ,'OUT OF SCOPE : ' || l_db.scope_exclusion_reason
                                     ,regexp_replace(l_migration_definition.script_name,'^.*/','')
                                     ,l_migration_definition.parameters) ;
        return ;
    end if ;

    mf_utils.message('',p_ts => false ) ;
    mf_utils.message('Launching a batched migration action for database : ' || l_migration_definition.script_name) ;
    mf_utils.message('DB ID             : ' || l_migration_definition.db_id,'  -',p_ts=>false) ;
    mf_utils.message('',p_ts => false ) ;


    --
    --   Prepare the running anvironment of the script, based on a migration Step/Attempt
    --
    l_shell_command := mf_mig_actions.prepareMigrationScriptEnv(l_migration_definition) ;

    --
    --   Create execution Lline
    --
    insert into batch_executions (prj_name                            , start_date      ,progress               ,description
                                 ,script_name
                                 ,parameters                              ,set_code)
    values                       (l_db.prj_name                       , sysdate          ,'LAUNCHING'            ,p_label
                                 ,regexp_replace(l_migration_definition.script_name,'^.*/','')
                                 ,l_migration_definition.parameters       ,p_unicity_code)
    returning bat_id into l_bat_id;

--    insert into step_execs
--      (prj_name                ,start_date    , status     ,mstep_id
--      ,step_guid)
--    values
--      (l_mig_step.prj_name     ,sysdate       ,'LAUNCHING' ,l_mig_step.mstep_id
--      ,l_mig_step.step_guid)
--    returning sce_id into l_sce_id ;
    --
    --   Special variables to instruct the script to update the table
    --
    l_shell_command := l_shell_command   || chr(10) || 'export MFAUTO_BAT_ID=' || l_bat_id ;
    l_shell_command := l_shell_command   || chr(10) || 'export MFAUTO_IGNORE_ENV_FILE=YES' ;
    --
    --   Scripts launched here works exactly like migration scripts, but they do not store variables in the
    -- ENV file
    --
    l_shell_command := l_shell_command   || chr(10) || 'export MFAUTO_DB_ID=' || p_migration_definition.db_id ;
    l_shell_command := l_shell_command   || chr(10) || 'export MFAUTO_MIGRATION_CODE=' || 'MFAUTO_' || p_migration_definition.code ;
    l_shell_command := l_shell_command   || chr(10) || 'export MFAUTO_MIG_ID=' || p_migration_definition.mig_id ;
    l_shell_command := l_shell_command   || chr(10) || p_migration_definition.script_name || ' -m MFAUTO_' || p_migration_definition.code || ' ' || p_migration_definition.parameters ;

    --
    --   Run the script, with a known job name
    --
    mf_utils.runCommand (l_shell_command
                        ,p_migration_definition.prj_name
                        ,p_waitForCompletion=>p_waitForCompletion
                        ,p_printOutput => p_printOutput
                        ,p_job_name => 'MF$BATCH$MIGID_' || p_migration_definition.mig_id ||  '_BATID_' || l_bat_id) ;

    update batch_executions set job_name='MF$BATCH$MIGID_' || p_migration_definition.mig_id ||  '_BATID_' || l_bat_id where bat_id=l_bat_id ;

    commit ;

    if ( not p_waitForCompletion )
    then
      --
      --  Set a "JOB_STARTED" status, all the scripts immediately change this statis.
      -- If JOB_STARTED remains, it generally means that the script has failed at the very beginings
      --
      --  Before runnig anything, we now run cleanCrashedJobs to clean JOB_STARTED lines where the corresponding
      -- job id FAILED
      --
      update batch_executions set progress='JOB_STARTED' where bat_id = l_bat_id ;
    else
      update batch_executions set progress='COMPLETED' where bat_id = l_bat_id and progress='LAUNCHING';
    end if ;
    commit ;
  END;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */





  procedure printMatrix                ( p_rows_select        in varchar2                 -- Select to retrieve the values of the rows (first columns)
                                                                                          -- it must return EXACTLY 11 columns named col_id,col_val1 ... col_val10 , fill with NULLs
                                        ,p_cols_select        in varchar2                 -- Select to retrieve the values of the rows (first lines)
                                                                                          -- it must return EXACTLY 10 columns, fill with NULLs
                                        ,p_cells_select       in varchar2 default null    --     Select to retrieve the values of the cells ONE and only one value
                                        ,p_cells_line_select  in varchar2 default null    -- OR Select to retrieve the values of the  full line of cells, ORDER must be the same than in p_cols_select
                                        ,p_first_cell_format  in varchar2 default null    -- Format of the top most left cell(s)          (for text: length, for HTML code including %s)
                                        ,p_first_row_format   in varchar2 default null    -- Format of the first row(s) cells (header)    (for text: length, for HTML code including %s)
                                        ,p_first_col_format   in varchar2 default null    -- format of the first column(s) cells (header) (for text: length, for HTML code including %s)
                                        ,p_cell_format        in varchar2 default null    -- Format of the cell(s)                        (for text: length, for HTML code including %s)
                                        ,p_table_start        in varchar2 default null    -- Table start HTML
                                        ,p_table_end          in varchar2 default null    -- Table end HTML
                                        ,p_row_start          in varchar2 default null    -- Row start HTML
                                        ,p_row_end            in varchar2 default null    -- Row end HTML
                                        ,p_output_type        in varchar2 default 'TEXT'  -- OUtpout format
                                        ,p_nb_cols_on_left    in number   default 1       -- Number of userfull values in the previous select
                                        ,p_nb_rows_on_top     in number   default 1       -- Number of userfull values in the previous select
                                        ,p_start_cols_hdr     in varchar2 default null    -- '|' separated headers for the N first columns
                                        ,p_start_cols_width   in varchar2 default null   -- '|' separated widths for the N first columns (will replace width="" in the format)
                                        ,p_separator          in varchar2 default ';'     -- Field separator for csv output
                                        ) is
/* *************************** TEST Statement
set serveroutput on format wrapped
set LINESIZE 200
begin
  mf_apex_utils.printMatrix(
       'select level col_id, ''Row''||level val, null, null, null, null, null, null, null, null , null from dual connect by level <= 10'
      ,'select level row_id, ''Col''||level val, null, null, null, null, null, null, null, null , null  from dual connect by level <= 2'
      ,null
      ,'select ''C'' || level from dual connect by level <=2'
      ,p_first_cell_format=>10
      ,p_first_row_format=>10
      ,p_first_col_format=>10
      ,p_cell_format=>10
      ,p_start_cols_hdr=>'R'
                          ) ;
end ;
******************************************************************************************/

        l_first_cell_format varchar2(32767) ;
        l_first_row_format  varchar2(32767) ;
        l_first_col_format  varchar2(32767) ;
        l_cell_format       varchar2(32767) ;
        l_table_start       varchar2(32767) ;
        l_table_end         varchar2(32767) ;
        l_row_start         varchar2(32767) ;
        l_row_end           varchar2(32767) ;
        l_max_rows          number        ;
        l_separator         varchar2(10)  ;
        l_tmp_cell_format   varchar2(32767) ;

        i                   number        ;
        j                   number        ;
        curr_col            number        ;
        tmp                 varchar2(32767) ;

        type values_t is varray(10) of varchar2(32767) ; -- To store the 10 values MAX
        type row_header_t is record (
           row_id    varchar2(50)
          ,vals      values_t) ;
        row_header row_header_t ;
        rows$cursor   sys_refcursor ;
        line$cursor   sys_refcursor ;

        type col_header_t is record (
         col_id      varchar2(50)
        ,vals values_t );
        res           varchar2(32767) ;
        type col_headers_t is varray(500) of col_header_t ;
        col_header    col_header_t ;
        col_headers   col_headers_t ;
        cols$cursor  sys_refcursor ;

        cell_stmt     varchar2(32767) ;
        cell_val      varchar2(32767) ;


        /*
         *
         * ----------------------------------------------------------------------------
         *  Algorithm
         *  ---------
         *
         *        Execute the routine action using the package state, input parameters, SQL statements,
         *    and external API calls implemented below.
         *
         *  Possible Issues
         *  ---------------
         *
         *       - Generated documentation: review input validation, exception handling,
         *         and assumptions about data cardinality before changing the code.
         *       - SQL queries and external package calls may propagate runtime errors
         *         unless they are explicitly handled in the implementation.
         *
         * ----------------------------------------------------------------------------
         *
         */
        procedure pr (val in varchar2
                    ,fmt in varchar2 default null
                    ,typ in varchar2 default 'TEXT'
                    ,print_sep boolean default true) is
        tmp varchar2(32767) ;
        begin
        if (p_output_type in ('HTML','CSV') )
        then
          if (fmt = 'NL' )
          then
            if ( p_output_type = 'CSV' )
            then
              dbms_output.put_line('') ;
            end if ;
          else
            tmp:=replace(fmt,'%s',val) ;
            if ( p_output_type = 'HTML' )
            then
              htp.p(tmp) ;
              --dbms_output.put( tmp );
            else
              if ( print_sep )
              then
                dbms_output.put( l_separator );
              end if ;
              dbms_output.put( tmp );
            end if ;
          end if ;
        else
            if (fmt = 'NL' )
            then
            dbms_output.put_line ('') ;
            else
            dbms_output.put(rpad(val,to_number(fmt))) ;
            end if ;
        end if ;
        end ;
        /*
         *
         * ----------------------------------------------------------------------------
         *  Algorithm
         *  ---------
         *
         *        Execute the routine action using the package state, input parameters, SQL statements,
         *    and external API calls implemented below.
         *
         *  Possible Issues
         *  ---------------
         *
         *       - Generated documentation: review input validation, exception handling,
         *         and assumptions about data cardinality before changing the code.
         *       - SQL queries and external package calls may propagate runtime errors
         *         unless they are explicitly handled in the implementation.
         *
         * ----------------------------------------------------------------------------
         *
         */
        procedure pr_start_table as begin if (p_output_type in ('TEXT','CSV') ) then return ; else pr(l_table_start ,'%s' , p_output_type) ; end if ; end ;
        /*
         *
         * ----------------------------------------------------------------------------
         *  Algorithm
         *  ---------
         *
         *        Execute the routine action using the package state, input parameters, SQL statements,
         *    and external API calls implemented below.
         *
         *  Possible Issues
         *  ---------------
         *
         *       - Generated documentation: review input validation, exception handling,
         *         and assumptions about data cardinality before changing the code.
         *       - SQL queries and external package calls may propagate runtime errors
         *         unless they are explicitly handled in the implementation.
         *
         * ----------------------------------------------------------------------------
         *
         */
        procedure pr_end_table   as begin if (p_output_type in ('TEXT','CSV') ) then return ; else pr(l_table_end   ,'%s' , p_output_type) ; end if ; end ;
        /*
         *
         * ----------------------------------------------------------------------------
         *  Algorithm
         *  ---------
         *
         *        Execute the routine action using the package state, input parameters, SQL statements,
         *    and external API calls implemented below.
         *
         *  Possible Issues
         *  ---------------
         *
         *       - Generated documentation: review input validation, exception handling,
         *         and assumptions about data cardinality before changing the code.
         *       - SQL queries and external package calls may propagate runtime errors
         *         unless they are explicitly handled in the implementation.
         *
         * ----------------------------------------------------------------------------
         *
         */
        procedure pr_start_row   as begin if (p_output_type in ('TEXT','CSV') ) then return ; else pr(l_row_start   ,'%s' , p_output_type) ; end if ; end ;
        /*
         *
         * ----------------------------------------------------------------------------
         *  Algorithm
         *  ---------
         *
         *        Execute the routine action using the package state, input parameters, SQL statements,
         *    and external API calls implemented below.
         *
         *  Possible Issues
         *  ---------------
         *
         *       - Generated documentation: review input validation, exception handling,
         *         and assumptions about data cardinality before changing the code.
         *       - SQL queries and external package calls may propagate runtime errors
         *         unless they are explicitly handled in the implementation.
         *
         * ----------------------------------------------------------------------------
         *
         */
        procedure pr_end_row     as begin if (p_output_type in ('TEXT','CSV') ) then return ; else pr(l_row_end     ,'%s' , p_output_type) ; end if ; end ;
        /*
         *
         * ----------------------------------------------------------------------------
         *  Algorithm
         *  ---------
         *
         *        Execute the routine action using the package state, input parameters, SQL statements,
         *    and external API calls implemented below.
         *
         *  Possible Issues
         *  ---------------
         *
         *       - Generated documentation: review input validation, exception handling,
         *         and assumptions about data cardinality before changing the code.
         *       - SQL queries and external package calls may propagate runtime errors
         *         unless they are explicitly handled in the implementation.
         *
         * ----------------------------------------------------------------------------
         *
         */
        procedure pr_end_message (m in VARCHAR2
                                ,e in VARCHAR2) as
        BEGIN
            if (p_output_type = 'HTML')
            then
                if ( e = 'ERROR' )
                then
                    pr(m,'<BR><B><FONT color="red">%s</FONT></B>') ;
                else
                    pr(m,'<BR><FONT color="green">%s</FONT>') ;
                end if ;
            else
                if ( e = 'ERROR' )
                then
                    pr('ERROR : ' || m,200) ;
                else
                    pr(m,200) ;
                end if ;
            end if ;
        end ;
    begin
      if (p_cells_select is null and p_cells_line_select is null)
      then
        raise_application_error(-20000,'printMatrix :You must specify one select for cells or one select for cell lines') ;
      end if ;
      if (p_cells_select is not null and p_cells_line_select is not null)
      then
        raise_application_error(-20000,'printMatrix :You must specify only one od cell/cell line selects') ;
      end if ;
      --
      --  Define default values which depends on the output type
      --
      if (p_output_type = 'HTML')
      then
        if p_first_cell_format is null then l_first_cell_format := '<TD width="250px" style="padding-top: 10px;padding-bottom: 10px;">%s</TD>';
        else                                l_first_cell_format := p_first_cell_format ;
        end if ;
        if p_first_row_format  is null then l_first_row_format  := '<TD width="50px" style="writing-mode: vertical-rl;transform: rotate(180deg);padding-top: 10px;padding-bottom: 10px;"><I>%s</I></TD>';
        else                                l_first_row_format  := p_first_row_format ;
        end if ;
        if p_first_col_format  is null then l_first_col_format  := '<TD width="250px" style="padding-left:10px; padding-top: 10px;padding-bottom: 10px;"><B>%s</B></TD>';
        else                                l_first_col_format := p_first_col_format ;
        end if ;
    --      if p_first_cell_format is null then l_first_cell_format := '<TD style="padding-top: 5px;padding-bottom: 5px;">'||chr(amp)||'nbsp;</TD>';
    --      else                                l_first_cell_format := l_first_cell_format ; end if ;
        if p_cell_format       is null then l_cell_format       := '<TD width="50px" style="padding-top: 10px;padding-bottom: 10px;"><CENTER><I>%s</I></CENTER></TD>';
        else                                l_cell_format       := p_cell_format ;
        end if ;
        if p_table_start       is null then l_table_start       := '<TABLE class="t-Report-report" border=1>';
        else                                l_table_start       := p_table_start ;
        end if ;
        if p_table_end         is null then l_table_end         := '</TABLE>';
        else                                l_table_end         := p_table_end ;
        end if ;
        if p_row_start         is null then l_row_start         := '<TR>';
        else                                l_row_start         := p_row_start ;
        end if ;
        if p_row_end           is null then l_row_end           := '</TR>';
        else                                l_row_end           := p_row_end ;
        end if ;
        l_max_rows := 200  ;
        l_separator := '';
      end if ;

      if (p_output_type = 'TEXT')
      then
        if p_first_cell_format is null then l_first_cell_format := '20';
        else                                l_first_cell_format := p_first_cell_format ;
        end if ;
        if p_first_row_format  is null then l_first_row_format  := '20';
        else                                l_first_row_format  := p_first_row_format ;
        end if ;
        if p_first_col_format  is null then l_first_col_format  := '20';
        else                                l_first_cell_format := p_first_cell_format ;
        end if ;
    --      if p_first_cell_format is null then l_first_cell_format := '<TD style="padding-top: 5px;padding-bottom: 5px;">'||chr(amp)||'nbsp;</TD>';
    --      else                                l_first_cell_format := l_first_cell_format ; end if ;
        if p_cell_format       is null then l_cell_format       := '20';
        else                                l_cell_format       := p_cell_format ;
        end if ;
        if p_table_start       is null then l_table_start       := '';
        else                                l_table_start       := p_table_start ;
        end if ;
        if p_table_end         is null then l_table_end         := '';
        else                                l_table_end         := p_table_end ;
        end if ;
        if p_row_start         is null then l_row_start         := '';
        else                                l_row_start         := p_row_start ;
        end if ;
        if p_row_end           is null then l_row_end           := '';
        else                                l_row_end           := p_row_end ;
        end if ;
        l_max_rows := 1000000 ;
        l_separator := '';
      end if ;

      if (p_output_type = 'CSV')
      then
        if p_first_cell_format is null then l_first_cell_format := '"%s"';
        else                                l_first_cell_format := p_first_cell_format ;
        end if ;
        if p_first_row_format  is null then l_first_row_format  := '"%s"';
        else                                l_first_row_format  := p_first_row_format ;
        end if ;
        if p_first_col_format  is null then l_first_col_format  := '"%s"';
        else                                l_first_cell_format := p_first_cell_format ;
        end if ;
    --      if p_first_cell_format is null then l_first_cell_format := '<TD style="padding-top: 5px;padding-bottom: 5px;">'||chr(amp)||'nbsp;</TD>';
    --      else                                l_first_cell_format := l_first_cell_format ; end if ;
        if p_cell_format       is null then l_cell_format       := '"%s"';
        else                                l_cell_format       := p_cell_format ;
        end if ;
        if p_table_start       is null then l_table_start       := '';
        else                                l_table_start       := p_table_start ;
        end if ;
        if p_table_end         is null then l_table_end         := '';
        else                                l_table_end         := p_table_end ;
        end if ;
        if p_row_start         is null then l_row_start         := '';
        else                                l_row_start         := p_row_start ;
        end if ;
        if p_row_end           is null then l_row_end           := '';
        else                                l_row_end           := p_row_end ;
        end if ;
        l_max_rows := 1000000 ;
        l_separator := p_separator ;
      end if ;

      --
      -- Get headers
      --
--      mf_utils.message('Get Headers') ;
--      mf_utils.message(p_cols_select,'  ',p_ts=>false) ;
--      mf_utils.message('Format  : ' || l_first_row_format,'  ',p_ts=>false) ;

      row_header.vals := values_t('1','2','3','4','5','6','7','8','9','10') ;
      col_header.vals := values_t('1','2','3','4','5','6','7','8','9','10') ;

      col_headers:=col_headers_t() ;
      i := 1;
      --
      --  Load the table (can't do this with bulk collect in these conditions)
      --
      open cols$cursor for p_cols_select ;
      loop
        fetch cols$cursor into col_header.col_id
                              ,col_header.vals(1),col_header.vals(2),col_header.vals(3),col_header.vals(4),col_header.vals(5)
                              ,col_header.vals(6),col_header.vals(7),col_header.vals(8),col_header.vals(9),col_header.vals(10) ;
      exit when cols$cursor%notfound ;
        col_headers.extend ;
        col_headers(i) := col_header ;
        i := i + 1 ;
      end loop ;

      --
      --  Print headers
      --
--      mf_utils.message('Print Headers') ;
      pr_start_table ;

      --
      --  Print N header lines
      --
      for j in 1 .. p_nb_rows_on_top
      loop
        curr_col := 0 ;
        pr_start_row ;

        --
        --  Empty cells on top right corner
        --
        for i in 1 .. p_nb_cols_on_left
        loop
          curr_col := curr_col + 1 ;
          tmp := null ;
          if ( j = p_nb_rows_on_top)
          then
            tmp := REGEXP_SUBSTR(p_start_cols_hdr, '[^\|]+', 1, i) ;
          end if ;
          tmp := nvl(tmp,' ') ;
          --
          --  Apply column width if needed
          --
          if ( p_start_cols_width is null )
          then
            l_tmp_cell_format := l_first_cell_format ;
          else
            l_tmp_cell_format := regexp_replace(l_first_cell_format,'width="[^"]*"','width="'||nvl(REGEXP_SUBSTR(p_start_cols_width, '[^\|]+', 1, i),'50px') || '"') ;
          end if;
--          htp.p(l_tmp_cell_format) ;
          pr(tmp,l_tmp_cell_format,print_sep => (curr_col>1)) ;
        end loop ;

        --
        -- Column headers
        --
        for i in 1 .. col_headers.count
        loop
          curr_col := curr_col + 1 ;
          pr(col_headers(i).vals(j),l_first_row_format,print_sep => (curr_col>1)) ;
        end loop ;
        pr_end_row ;
        pr('','NL') ;
    end loop ;
--        mf_utils.message('Print rows Headers') ;
--        mf_utils.message(p_rows_select,'  ',p_ts=>false) ;
--        mf_utils.message(p_cells_select,'  ',p_ts=>false) ;
--      mf_utils.message('Columns : ' || row_header.vals.count,'  ',p_ts=>false) ;


--      mf_utils.message('Print Rows') ;
      open rows$cursor for p_rows_select ;
      i := 0 ;
      loop
        res := '' ;
        begin
          fetch rows$cursor into row_header.row_id
                              ,row_header.vals(1),row_header.vals(2),row_header.vals(3),row_header.vals(4),row_header.vals(5)
                              ,row_header.vals(6),row_header.vals(7),row_header.vals(8),row_header.vals(9),row_header.vals(10) ;
        EXCEPTION
          when others then row_header.vals(1):=to_char(sqlcode)  ;
        end ;
      exit when rows$cursor%notfound  or  i > l_max_rows;
        pr_start_row ;
        curr_col := 0 ;
        i := i + 1 ;
        --
        --   Print the fixed columns on the left side of the table
        --
        for i in 1 .. p_nb_cols_on_left
        loop
          curr_col := curr_col + 1 ;
          --
          --  Apply column width if needed
          --
          if ( p_start_cols_width is null )
          then
            l_tmp_cell_format := l_first_col_format ;
          else
            l_tmp_cell_format := regexp_replace(l_first_col_format,'width="[^"]*"','width="'||nvl(REGEXP_SUBSTR(p_start_cols_width, '[^\|]+', 1, i),'50px') || '"') ;
          end if;
          pr(row_header.vals(i),l_tmp_cell_format,print_sep => (curr_col>1)) ;
        end loop ;
        --
        --   Print the cells
        --
        if (p_cells_select is not null)
        then
          --
          --    Fetch CELLS one by one in the line
          --
          for i in 1 .. col_headers.count
          loop
            cell_stmt := replace ( p_cells_select , '#COL_ID#', col_headers(i).col_id );
            cell_stmt := replace ( cell_stmt      , '#ROW_ID#', row_header.row_id );
      --        dbms_output.put_line('') ;
      --        dbms_output.put_line(cell_stmt) ;
            begin
              execute immediate cell_stmt into cell_val ;
            exception when no_data_found then cell_val:='';
            end ;
            curr_col := curr_col + 1 ;
            pr(cell_val,l_cell_format,print_sep => (curr_col>1)) ;
          end loop ;
        else
          --
          --   Fetch The FULL line (one SELECT for the line)
          --
          cell_stmt := replace ( p_cells_line_select      , '#ROW_ID#', row_header.row_id );
          open line$cursor for cell_stmt ;
          loop
            fetch line$cursor into cell_val ;
            curr_col := curr_col + 1 ;
          exit when line$cursor%notfound ;
            pr(cell_val,l_cell_format,print_sep => (curr_col>1)) ;
          end loop ;
        end if;
        pr('','NL') ;
        pr_end_row ;
      end loop;
      pr_end_table ;
      if ( i > l_max_rows )
      then
        pr_end_message('There are more than ' || l_max_rows || ' rows output is incomplete, please refine your criterias','ERROR') ;
        else
        pr_end_message(i || ' records selected','OK') ;
      end if ;
  end ;
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function runBatch_clientDetect (p_wav_id                        in varchar2   -- ID of the Wave
                                 ,p_mig_code_prefix               in varchar2   -- Prefix of the migration attemps code
                                 ,p_interval_minutes              in number     -- Run interval in minutes
                                 ,p_duration_minutes              in number     -- Duration of the run in minutes
                                 ,p_error_message                 out varchar2  -- Error meddage
                                 ) return number is                             -- Return : 0=All batches launched , 1=Some batches already running , 2= No batch launched
-- /* Test actions ***************************************************
--set serveroutput on format wrapped
--declare
--  n number ;
--  mess varchar2(200) ;
--begin
--  n := mf_apex_utils.runBatch_clientDetect(122,'L0-W1%',1,5,mess) ;
--end ;
--/
--select count(*) from user_scheduler_jobs where state='RUNNING' ;
--
--select * from batch_executions order by bat_id desc;
--******************************************************************* */
--   l_wave waves%rowtype ;
   l_wave mf_mig_parameters.wav_t ;
   nb number ;
--   fake_step v_migration_steps%rowtype ;
   fake_step mf_mig_parameters.mig_def_t ;
   launched number := 0 ;
   not_launched number := 0 ;
   job_queue_processes number ;
   running_jobs number ;
 begin
    begin
      select --*
      PRJ_NAME
     ,WAV_ID
     ,NAME
     ,TARGET_START
     ,TARGET_END
     ,EFFECTIVE_START
     ,EFFECTIVE_END
     ,COMMENTS
     ,CREATE_DATE
     ,CREATED_BY
     ,UPDATE_DATE
     ,UPDATED_BY
     ,TYPE
     ,CODE
      into   l_wave
      from   waves
      where wav_id = p_wav_id ;
    exception
      when no_data_found then raise_application_error(-20000,'runBatch_clientDetect : No wave with id #' || p_wav_id || ' exists' ) ;
    end ;


    select count(*)
    into   nb
    from   migration_attempts
    where db_id  in (select db_id from v_db_in_waves where wave_id=p_wav_id)
    and   code like p_mig_code_prefix || '%' ;
    if ( nb = 0 )
    then
      raise_application_error(-20000,'runBatch_clientDetect : No attempt with name like ' || p_mig_code_prefix || '% exists' ) ;
    end if ;


    select value
    into   job_queue_processes
    from   v$parameter
    where  name = 'job_queue_processes' ;

    select count(*)
    into   running_jobs
    from   user_scheduler_jobs
    where  state='RUNNING' ;


    mf_utils.message('',p_ts => false ) ;
    mf_utils.message('Client version detection : ' ) ;
    mf_utils.message('WAVE                        : ' || l_wave.name,'  -',p_ts=>false) ;
    mf_utils.message('PREFIX                      : ' || p_mig_code_prefix,'  -',p_ts=>false) ;
    mf_utils.message('job_queue_processes         : ' || job_queue_processes,'  -',p_ts=>false) ;
    mf_utils.message('running jobs                : ' || running_jobs,'  -',p_ts=>false) ;
    mf_utils.message('',p_ts => false ) ;


    if ( (nb + running_jobs) > (job_queue_processes*.75) )
    then
      raise_application_error(-20000,'runBatch_clientDetect : JOBS NEEDED (' || nb || ') + JOBS RUNNING (' || running_jobs || ') > 75% of JOB_QUEUE_PROCESSES (' || job_queue_processes || ') consider using a smaller wave' ) ;
    end if ;

    nb := 0 ;
    for ma$rec in (select *
                   from   migration_attempts
                   where db_id  in (select db_id from v_db_in_waves where wave_id=p_wav_id)
                   and   code like p_mig_code_prefix || '%' )
    loop
      nb := nb + 1 ;
      begin
        mf_utils.message('Start for          : ' || ma$rec.code,'    -',p_ts=>false) ;
        fake_step.mig_id       := ma$rec.mig_id      ;
        fake_step.db_id        := ma$rec.db_id       ;
        fake_step.code         := ma$rec.code        ;
        fake_step.script_name  := '$MF_HOME/bin/mfGetClientsVersionInfo.sh'   ; -- Script
        fake_step.parameters   := '-i ' || p_interval_minutes || ' -t ' ||  p_duration_minutes ; -- Parameters
        mf_apex_utils.batchedMigrationActivity(fake_step
                                              ,'SQL*Net Client Version Detection'
                                              ,ma$rec.code
                                              ,false) ;
        launched := launched + 1 ;
      exception
        when others then
          mf_utils.message(sqlerrm,'         ERROR : ',p_ts=>false) ;
          not_launched := not_launched + 1 ;
      end ;
    end loop ;
    mf_utils.message('Attempts count                : ' || nb,'   -',p_ts=>false) ;
    mf_utils.message('Batches launched              : ' || launched,'   -',p_ts=>false) ;
    mf_utils.message('        Not launched          : ' || not_launched,'   -',p_ts=>false) ;

    if ( launched = 0 )
    then
      p_error_message := 'No jobs were started' ;
      mf_utils.message('Return 2                      : ' || p_error_message,' -',p_ts=>false) ;
      return 2 ;
    elsif (launched < nb )
    then
      p_error_message := launched || ' jobs launched out of ' || nb || ' (Success)';
      mf_utils.message('Return 1                      : ' || p_error_message,' -',p_ts=>false) ;
      return 1 ;
    else
      p_error_message := 'All (' || launched || ' jobs launched (Success)';
      mf_utils.message('Return 0                      : ' || p_error_message,' -',p_ts=>false) ;
      return 0 ;
    end if ;
  end ;
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Execute the routine action using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  procedure update_who_does_what       ( p_page   in number
                                        ,p_db_id  in NUMBER
                                        ,p_mig_id in number default null ) as
  begin
   --
   --  Update WHO_DOES_WHAT
   --
   merge into MF_WHO_DOES_WHAT wd
   using (
    select
       db.prj_name
      ,db.db_id
      ,ma.mig_id
      ,nvl(APEX_CUSTOM_AUTH.get_username,user) user_name
    from
      databases db
      left join migration_attempts ma on (db.db_id = ma.db_id and current_attempt='Y')
    where
      db.db_id = p_db_id) st
   on ( wd.prj_name = st.prj_name and wd.db_id= st.db_id and wd.mig_id = nvl(st.mig_id,0)  and st.user_name = wd.user_name)
   when matched then
     update set page_number=p_page , date_visited=sysdate
   when not matched then
     insert (prj_name,user_name,page_number,db_id,mig_id,date_visited,favorite)
     values (st.prj_name,nvl(APEX_CUSTOM_AUTH.get_username,user),p_page,st.db_id,nvl(st.mig_id,0),sysdate,'N');
  commit ;
  end ;

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function  p5001_mergeFlowTestResults(d in date,day_only in varchar2 default 'N') return varchar2 is
    tmp           varchar2(32767) ;
    bu            varchar2(50);
    select_date   date ;
    next_week     number := 4 ;
    l_start_date  date ;
    day_num       number ;
    total number := 0;
    sub_total number := 0;
    l_days number := 6 ;

  begin
    tmp         := 'OK';
    select_date := trunc(d) ;
    day_num := case substr(to_char(select_date,'DY','NLS_DATE_LANGUAGE=FRENCH'),1,3)
                 when 'LUN' then 1
                 when 'MAR' then 2
                 when 'MER' then 3
                 when 'JEU' then 4
                 when 'VEN' then 5
                 when 'SAM' then 6
                 when 'DIM' then 7
               end ;
    if ( day_only = 'N' )
    then
      if ( day_num >= next_week)
      then
        l_start_date := select_date + 7 - day_num +1 ; --next monday
      else
        l_start_date := select_date - day_num + 1 ; --previous monday
      end if ;
    else
      l_start_date := trunc(select_date) ;
      l_days := 1 ;
    end if ;

    merge into FLOWS_REF BFR
     using (
       select
         po.prj_name
        ,db.db_id
        ,case
           when tn.tnod_id is not null then
             --cast (mf_utils.runAnyCommand('echo -n ''' || db.source_dbname || '(' || db.env_name ||')'|| '@' || sc.scan_ip ||':' || sc.scan_port || '  --/--  ''' ||
             cast (mf_utils.runAnyCommand('ssh -o strictHostKeyChecking=no opc@' ||tn.fqdn || ' timeout 2 curl -s http://'|| nvl(db.scan,sc.scan_ip )|| ':' || nvl(db.port,sc.scan_port) ||
                            ' ; if [ $? -eq 0 -o $? -eq 52 ] ; then echo ''OPENED'' ; else echo ''CLOSED'' ; fi',po.prj_name) as varchar2(4000))
           else 'Cible non definie'
         end check_result
      from
        MIGRATION_PLANNED_OPERATIONS       po
        join migration_attempts            ma on (po.mig_id = ma.mig_id)
        join v_database_migration_statuses st on (st.db_id  = ma.db_id)
        join v_databases                   db on (db.db_id  = ma.db_id)
        join source_clusters               sc on (db.sclu_id = sc.sclu_id)
        join source_nodes                  sn on (sn.sclu_id = sc.sclu_id)
        left join v_db_in_waves            dw on (ma.db_id = dw.db_id and wave_type = 'Migration')
        left join mig_roles                mr on (mr.mig_id = ma.mig_id)
        left join contacts                 co on (co.cnt_id = mr.cnt_id)
        left join target_clusters          tc on (tc.tclu_id = ma.tclu_id )
        left join target_nodes             tn on (tn.tclu_id = tc.tclu_id and tn.ord_num=1)
      WHERE
            po.mls_id = mf_mig_parameters.get_id('MLS_ID_GOLIVE_START',po.prj_name)
        and po.current_plan = 'Y'
        and ma.current_attempt='Y'
        and trunc(po.target_date) >= l_start_date and trunc(po.target_date) < trunc(l_start_date + l_days)
        and  db.in_scope='Y') st
     on ( BFR.prj_name = st.prj_name and BFR.db_id = st.db_id )
     when matched then
       update set flow_state= replace(replace(st.check_result ,CHR(13),''),CHR(10),''), last_check_date=sysdate
     when not matched then
       insert (prj_name,db_id,flow_state,last_check_date)
       values (st.prj_name,st.db_id,replace(replace(st.check_result ,CHR(13),''),CHR(10),''),sysdate);
    commit ;

    return(tmp) ;
  end ;
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */


  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Execute the routine action using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  procedure  p5001_singleFlowTest(p_db_id in varchar2, p_flow_type in varchar2) is
    tmp           varchar2(32767) ;
    bu            varchar2(50);
    total number := 0;
    sub_total number := 0;
    l_days number := 6 ;
    l_db_id number := p_db_id;
  begin
    tmp         := 'OK';
    if ( p_flow_type = 'SRC-TGT' )
    then
      merge into FLOWS_REF BFR
       using (
         select
           ma.prj_name
          ,db.db_id
          --timeout 2 curl http://${h}:22 >/dev/null
          ,case
             when tn.tnod_id is not null then
               --cast (mf_utils.runAnyCommand('echo -n ''' || db.source_dbname || '(' || db.env_name ||')'|| '@' || sc.scan_ip ||':' || sc.scan_port || '  --/--  ''' ||
               cast (mf_utils.runAnyCommand('ssh -o strictHostKeyChecking=no opc@' ||tn.fqdn || ' timeout 2 curl -s http://'|| nvl(db.scan,sc.scan_ip) || ':' || nvl(db.port,sc.scan_port) ||
                              ' ; if [ $? -eq 0 -o $? -eq 52 ] ; then echo ''OPENED'' ; else echo ''CLOSED'' ; fi',ma.prj_name) as varchar2(4000))
             when tn.tnod_id is null then
               cast (mf_utils.runAnyCommand('ssh -o strictHostKeyChecking=no opc@' || (select default_node.fqdn
                     from TARGET_NODES     default_node
                     join target_clusters  default_cluster on (default_cluster.tclu_id = default_node.tclu_id)
                     where
                        1=1
                        and default_node.ord_num = 1
                        and default_cluster.BU_NAME=db.group_bu
                        and default_cluster.env_name = (select case when name in ('PREPROD', 'PROD') then 'PROD' else 'NPR' end from environments where env_id=db.env_id)
                        and default_cluster.prj_name = ma.prj_name
                        and rownum = 1) || ' timeout 2 curl -s http://'|| sc.scan_ip || ':' || sc.scan_port ||
                              ' ; if [ $? -eq 0 -o $? -eq 52 ] ; then echo ''OPENED'' ; else echo ''CLOSED'' ; fi',ma.prj_name) as varchar2(4000))
             else 'Target DB not created'
           end check_result
        from
          migration_attempts            ma
          join v_databases                   db on (db.db_id  = ma.db_id)
          join source_clusters               sc on (db.sclu_id = sc.sclu_id)
          join source_nodes                  sn on (sn.sclu_id = sc.sclu_id)
          left join target_clusters          tc on (tc.tclu_id = ma.tclu_id )
          left join target_nodes             tn on (tn.tclu_id = tc.tclu_id and tn.ord_num=1)
        WHERE
          ma.db_id = l_db_id
          and ma.current_attempt='Y'
          and  db.in_scope='Y') st
       on ( BFR.prj_name = st.prj_name and BFR.db_id = st.db_id and BFR.flow_type='SRC-TGT')
       when matched then
         update set flow_state=replace(replace(st.check_result ,CHR(13),''),CHR(10),'') , last_check_date=sysdate
       when not matched then
         insert (prj_name,db_id,flow_state,flow_type,last_check_date)
         values (st.prj_name,st.db_id,replace(replace(st.check_result ,CHR(13),''),CHR(10),''),'SRC-TGT',sysdate);
    end if ;

    if ( p_flow_type = 'MF-SRC' )
    then
      merge into FLOWS_REF BFR
       using (
         select
           db.prj_name
          ,db.db_id
          --timeout 2 curl http://${h}:22 >/dev/null
          ,
          -- case
          --    when tn.tnod_id is not null then
               --cast (mf_utils.runAnyCommand('echo -n ''' || db.source_dbname || '(' || db.env_name ||')'|| '@' || sc.scan_ip ||':' || sc.scan_port || '  --/--  ''' ||
               cast (mf_utils.runAnyCommand('timeout 2 curl -s http://'|| nvl(db.scan,sc.scan_ip) || ':' || nvl(db.port,sc.scan_port )||
                              ' ; if [ $? -eq 0 -o $? -eq 52 ] ; then echo ''OPENED'' ; else echo ''CLOSED'' ; fi',db.prj_name) as varchar2(4000))
          --    else 'Target DB not created'
          --  end
           check_result
        from
          v_databases                        db
          join source_clusters               sc on (db.sclu_id = sc.sclu_id)
          -- join source_nodes                  sn on (sn.sclu_id = sc.sclu_id)
        WHERE
          db.db_id = l_db_id
          and  db.in_scope='Y') st
       on ( BFR.prj_name = st.prj_name and BFR.db_id = st.db_id and BFR.flow_type='MF-SRC')
       when matched then
         update set flow_state=replace(replace(st.check_result ,CHR(13),''),CHR(10),'') , last_check_date=sysdate
       when not matched then
         insert (prj_name,db_id,flow_state,flow_type,last_check_date)
         values (st.prj_name,st.db_id,replace(replace(st.check_result ,CHR(13),''),CHR(10),''),'MF-SRC',sysdate);
    end if ;
    commit ;
  end ;

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Execute the routine action using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  procedure p3505_approvePlanningCR (p_pcr_id in number) is
  begin
    update MIGRATION_PLAN_CHANGE_REQUEST set status = 'APPROVED', applied_by = (select nvl(APEX_CUSTOM_AUTH.get_username,user) from dual) where PCR_ID = p_pcr_id;
    if sql%rowcount = 0 then
      raise_application_error(-20001, 'Row not found or already updated.');
    end if;
  end;

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Execute the routine action using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  procedure p3505_rejectPlanningCR (p_pcr_id in number) is
  begin
    update MIGRATION_PLAN_CHANGE_REQUEST set status = 'REJECTED', applied_by = (select nvl(APEX_CUSTOM_AUTH.get_username,user) from dual), applied_at = mf_utils.getAuditDate where PCR_ID = p_pcr_id;
    if sql%rowcount = 0 then
      raise_application_error(-20001, 'Row not found or already updated.');
    end if;
  end;

  /*
   *
   * ----------------------------------------------------------------------------
   *  Algorithm
   *  ---------
   *
   *        Compute and return the routine result using the package state, input parameters, SQL statements,
   *    and external API calls implemented below.
   *
   *  Possible Issues
   *  ---------------
   *
   *       - Generated documentation: review input validation, exception handling,
   *         and assumptions about data cardinality before changing the code.
   *       - SQL queries and external package calls may propagate runtime errors
   *         unless they are explicitly handled in the implementation.
   *
   * ----------------------------------------------------------------------------
   *
   */
  function p0000_default_logo return blob is
    lob_out blob ;
  begin
    DBMS_LOB.CREATETEMPORARY(lob_out,TRUE, DBMS_LOB.SESSION);
    dbms_lob.append(lob_out, hextoraw('FFD8FFE000104A46494600010101007800780000FFE100224578696600004D4D002A00000008000101120003000000010001000000000000FFDB0043000201010201010202020202020202030503030303030604040305070607070706070708090B0908080A0807070A0D0A0A0B0C0C0C0C07090E0F0D0C0E0B0C0C0CFFDB004301020202030303060303060C0807080C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0CFFC0001108007D00C803012200021101031101FFC4001F0000010501010101010100000000000000000102030405060708090A0BFFC400B5100002010303020403050504040000017D01020300041105122131410613516107227114328191A1082342B1C11552D1F02433627282090A161718191A25262728292A3435363738393A434445464748494A535455565758595A636465666768696A737475767778797A838485868788898A92939495969798999AA2A3A4A5A6A7A8A9AAB2B3B4B5B6B7B8B9BAC2C3C4C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE1E2E3E4E5E6E7E8E9EAF1F2F3F4F5F6F7F8F9FAFFC4001F0100030101010101010101010000000000000102030405060708090A0BFFC400B511000201020404030407050404000102770001020311040521310612415107617113'));
    dbms_lob.append(lob_out, hextoraw('22328108144291A1B1C109233352F0156272D10A162434E125F11718191A262728292A35363738393A434445464748494A535455565758595A636465666768696A737475767778797A82838485868788898A92939495969798999AA2A3A4A5A6A7A8A9AAB2B3B4B5B6B7B8B9BAC2C3C4C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE2E3E4E5E6E7E8E9EAF2F3F4F5F6F7F8F9FAFFDA000C03010002110311003F00FDFCA28A2800A28A2800A28A2800A28A2800A28A2800A28A65C5C47696F24B2C891C51A977773B551472493D80F5A00793815F07FEDC9FF05EEF863FB30EA179E1EF05C3FF000B33C5D6A5A2956C6E047A55848320ACB7386DEC0F55883770594D7C6BFF00057CFF0082D16A7FB416B9A9FC35F84FAB5C69BF0FED5DAD753D66D6431CFE2561C3246E394B4EA38E65EA7E4383E07FF04FAFF82517C47FDBFAF5750D2A38FC31E04B798C573E23BF88985C83864B68F833B8E8704229E0B03C1F89CCB892B55ADF54CAD734BF9B7FBBA5BCDE9F99FD75C07E02E5597656B89FC44ABEC68D93549B71767B7B46BDEE6974A70F7FBBBDE2B5BE3DFF00C16FBF68AF8E57736CF1AFFC213A6B9252CBC3300B21183D3F7E774E7EBE60FA0AF00BFF008F1F127E21DEB4D73E34F1F6BD719F9A47D62F2E9B3F5DE6BF797F661FF82237C02FD9BACADA6B8F0AC5E3CD7A200C9A9F8942DE65'));
    dbms_lob.append(lob_out, hextoraw('8774B723C8419E9F2161FDE3D6BEAAF0F78534BF08D82DAE93A6E9FA5DAC630B0DA5BA431A8F655005611E17C7E23DFC657D7B6B2FD525F23D8C47D22B833237F56E17C96328474E66A14AFE7A42727EB269F747F2E7A47ED0BF133E1B5FACD63E3AF881A05CE721A3D6AF2D589FFBEC66BE8AFD9F7FE0BA9FB437C0DBB816F7C536FE3ED263237D9F88EDC4EEEBDF1709B6607DD9987B1AFDFEF14F82345F1C69ED69AD68FA5EB16B20C3437D691DC46C3D0AB822BE47FDA93FE0853F01FF00689B1B9B8D23413F0E3C41202D1EA1E1D02183776F32D0FEE597D4284639FBC294B86730C37BF83AF77DB58FEAD3F98F0FF484E08CF9FD578A7268C212D3992855B79DF96138FAC6EFB22BFEC25FF05C5F859FB616A167E1DD6B77C3BF1C5D111C5A76A770AD677F27F76DEE70AACC4F44708E4F00357DA95FCD8FEDE9FF0004C9F891FB01788957C4D671EB3E14BD97CBD3FC49A7A31B2B863C88E407E6826C0FB8DC1C1DACD826BEC4FF008239FF00C16A750F0B6B7A47C27F8C5ABC97DA2DDB259E81E25BD9774DA739C2A5B5D487EF424E15256394380C4A60A75657C495635BEA7992E596D7DBEFE9AF46B4FCCF9EF113C04CBB1195BE28F0FEAFB7C359C9D34F99A4B7707F13E5FB54E5EFAD756FDD3F62A8A28AFB43F93428A28A0028A28A0028A28A0028A28A0028A28A002B95F8CBF1'));
    dbms_lob.append(lob_out, hextoraw('BBC27FB3D7802F3C53E36D7F4DF0DE81638F36F2F65D8BB8F4451CB3B9C708A0B1EC0D64FED3FF00B4A785FF00648F823AE78F3C5D75F67D27458B708D3066BD99B88E0894FDE91DB000E8392480091FCEBFEDABFB7178FBFE0A0BF193FB6BC4935C1B5F3CC1A0F87AD0B496DA623B61238907324CDC06931B9CF03002A8F033CCFA9E022A29734DECBF57E5F9FE27ED7E0FF8338DE35C44ABD493A383A6ED3A96D5BDF9217D1CADAB6F48A69BBB693FBFBF6A7FF8397CC17F73A6FC1BF05C3710C64A2EB9E252CAB2F6DD1DA46C1B1DC192407A65057C83E37FF82DC7ED37E36BD695BE254DA3C64FCB0697A559DBC69F8F945CFE2C6BE8EFD85FFE0DD1D7BE2569167E24F8D5AB5F78474FB90B2C5E1CD3767F69BA1E47DA2560C9013FDC556619E4A118AFD02F875FF0477FD9B3E1AE9B1DBDAFC29F0EEA8C830D3EB024D4A690FA933330CFD001ED5F3D4F039E6397B5AB53D9A7D2EE3F82D7EF773F70C6717F83BC1D2FA865F8058DA91D253E58D5575BFEF2ABB5FF00EBDC797B1F8DBE0BFF0082DA7ED37E0BBD5997E26DC6AD18EB0EA7A5D9DCC6FF008F94187E0C2BBAFDA3FF00E0BD5F14FF00697FD97354F877A8E8BA1683A86B8CB6FA96B9A3CB2C2D756583E65B8858B6C321DA1983E0A6F5DA3766BF56BE217FC11F3F66DF891A6C96F75F09FC35A6B38C2CFA42BE9B3467D434'));
    dbms_lob.append(lob_out, hextoraw('0CBCFD722BE28FDA23FE0D9496E7C511DC7C29F8816F6BA44EFF00BEB1F13C6F24B68BEB1CD0A7EF3FDD7453C7DF359E2329CEE8D371A755CE2F46B99B767FE2FD1DCEDC87C4EF07F36C6D3AF8DCBA384AB4E4A5193A518C79A3AABBA37BDBB4E363E54FF82437FC134A6FDBF7E32CD79AF2DC5AFC35F08491BEB53464C6DA94A798EC6261C82C06E761CAA7A33A9AFE81FC23E11D2FC03E18D3F45D134FB3D2748D2E04B6B3B3B588450DB44A30A88A38000EC2BCDBF621FD92345FD88BF66ED07E1F68B2FDB3FB355A7BFBF68846FA9DDC8774B3B2E4E32701464ED4545C9C66BD6ABEA321CA2381C3A4D7BF2D64FF004F45FF0004FE77F19BC4FC4718E773A94E4FEA949B8D18EA95B6736BF9A7BBBEA95A3D028A28AF70FC7C28A28A00C5F88FF0E341F8BDE06D53C33E26D2ACF5BD075A81ADAF6CAEA3DF14F19EC476238208C1520104100D7F3BFF00F054FF00F8277EA1FF0004FBF8FADA5DB9BAD43C0BE24125DF873509BE6631823CCB595BA1962DCA09FE25646E09207F4755F36FFC158BF649B7FDB0BF627F1668715AACDE22D0E06D7740936E5D2F2DD59846BFF5D63DF11FFAE99EC2BE7F88B298E330CE515EFC55D79F97CFF33F6EF02FC4EC470A67D4E8D69BFAA57928D48B7A2BE8AA2ECE2F77D6375BDADE2BFF000411FDBF6E3F69FF0080973F0FFC517CD75E34F8731471'));
    dbms_lob.append(lob_out, hextoraw('C77133EE9B53D30FCB0CAC4F2CF111E539EE3CA2492C6BEFCAFE6AFF00E0963FB484BFB307EDD7F0F7C49E7B41A5EA17E9A26AC09C2B59DD911316F64631C9F58857F4A959F0B6632C560F966EF2869EABA3FD3E47A1F48CE04A5C3BC52EB60E3CB4314BDA452DA32BDA715E57F792D92924B60A28A2BE90FC0428A28A0028A2ABEAFABDAE81A55CDF5F5D5BD958D9C4D3DC5C5C48238A08D412CEECC405500124938005038C5B765B962B94F8B3F1D7C17F01B403AA78D3C55E1FF0AE9F83B66D4EFA3B61263B28620B1F65C9AFCB9FF82887FC1C3973FDA17FE11F8062148616682E3C61770093CD3D0FD8A1718DBE92CA0E7F8531863F9B9A5E81F13FF6D4F8AB335ADAF8CBE26F8C2F0EF9A4026D46E5413D5D8E44683DCAA8F6AF91CC38B28D39FB2C247DA4BBF4F9757F2D3CCFE9EE07FA32E6998615669C4B5D60A85AF6697B4B7795DA8D35FE26DAEB147EE0FC43FF0082FEFECD7E05BC782D7C4DAE789DE3382747D16778F3ECF288D4FD4122B93B3FF8391BF67DB9B8D9269BF12ADD73FEB24D1612A3FEF9B827F4AF84BE167FC1BC3FB43FC40B38AE35687C1FE0B8E450DE5EABAA99A7507D52D92500FB16AEE351FF008365BE2FC166CD6BE3DF87371301911B9BC8C13E9BBC93FCAB87FB4F8827EF468A4BD2DF9BB9F612F0F7C12C23FABD7CD653977555497DF0A7CA79E7FC16'));
    dbms_lob.append(lob_out, hextoraw('93FE0A65A67EDE3F107C37A3F81EF3506F879E19B6174AB736ED6CF7BA8CA08791E36C1C471E1173DDA52386AFA77FE0DF0FF8270D843E1787E3D78CB4F8EEB50BD91E2F07DB5C26E5B38949492FB07FE5A3B0648CFF000AAB30CEF047CC769FF06F77ED1D37C44B1D16EB49F0D41A4DD4A12E35E87598A5B5B48F203398CED9D880721447927D3AD7ED7F8964B1FD913F64CD41F43D3FED1A7FC35F0AC8D6364A31E7259DA9289C7F7BCB009F726964F97E22BE3678FCC60D72EAAEACAFE49F48A5A79D9EE5F8A9C6991E51C2583E09E04C4C6A46B3719384D4A5C8DEAA728D9295594BDEDBDD524D28B47A3D15F0CFECCBFB0ACDFB5D7C0AF0CFC4EF89FF00167E2A6B5E28F1DD845AD491E85E289F49D2F4C8E751225B5BC1010AAB1AB0524E4920D66FED69FB396A1FF04DBF84371F193E1AFC4AF88F2CFE0FBBB59755D03C4BE229B57D37C456925C470BDB949B2525C499474390471CE08FA978EAAA9FB7953F72D7DF5B6F7B5ADB74B9FCE30E0CCBAA661FD8D471DCD8A73F6697B292A6EA5F95454F9B9ACE5A293A6975692D4FBE28AFCC783C25E03F1B7C5BFDA33C6BF17BE227C56F0CF87BC2BE3C5D32D64D23C43A9DBDA69D0CB6B148AB2456E1C46BB988DC40504819048CEC7EC9FE3AF0E5BFEDD7E03D2FF679F88BF12FE23782F50B1BF7F1F45AF5F5F6A1A5E9D0AC5FE89324'));
    dbms_lob.append(lob_out, hextoraw('B7480A4E66F9404CE471D33594736BCD2715ABB2F79736FCB7E5B6D7577AEC7A35FC3371C354AB4EB4DBA74FDA4A4E8C9514FD92ABC9EDB99A52716A314D2E69B8C74BA67E90515F02FED5DE2EF177EDFDFB42788BC03F0DBE204FF0F7C31F06E179AEB5FB5BEFB2FF006C78A36E6DAC7391BE0B7C665C64066C104ECA3C77FF00052BF137C4BFD81347BCF0F5C59F847E2C6ADE2FB0F86BE219250922F857529A431CF74179528554BC64E57F7839254D6B2CDA9A72BA7657B3FE6B6E97A3D35DF5E88E0A5E1A66156961A54E71F6951C14E0EE9D15515E9CAA68F4945393E54DC7DD8B5CD248FBEA8AF942CBFE0919E1296CE36D5BE277C78D63546506EAFA4F1D5E44D7527F13EC421572727006074AC6D0B4093E0DFF00C1543E18F80747D63C43278674EF8517EE2DAFB559EEFED52AEA0A3CF98BB1F326393F3B73CE06060568F155A167560926D2F8AFBBB76FD4F3A9F0DE5989F691CBB172A92A709CDDE9722B422E4ECF9DBD6D6578AEEFB1F64515C0FED53F182E3F67EFD9B3C75E37B4B35BFBBF0AE8777A9416ED9DB2C91C4CCA1B1CEDDC0671DB35F99BF0CFC49A3FC57F03E9BE26F89707EDC1E30F17EBD6E97F7B7DE1DB2BCB1D141906F09651C122A7D9D4101580F980CF19C09C6660A84D534AEDABEAECADF73FC8E8E15E05AD9C60EA63E5370A719287BB1E7939357764E5'));
    dbms_lob.append(lob_out, hextoraw('049256BB725BA493D6DFAE1411915F35FEC55F05BC37ABFC18D2751D121F8D3E1CB5835F9355587C717F37F6BDE3A2F9404AB2BBB0B7C02150EDCF2D8F9B71FA52BB285494E0A6D5AFE77FD11F2D9C6069E0F153C3539B972B69DE2A2F476D529497E2CFE5B7F6BDF012FC1BFDAB3E267872CFF731F877C51A8DB5AECE3CB44B9731E3E8BB7F2AFE9ABE08F8BE4F883F05FC23AF487749AE68B67A831F532C0921FF00D0ABF9B0FF008288788EDFC59FB72FC66D42D58496F3F8BB5311B0E8C16774CFE3B6BFA3BFD95F4797C3BFB30FC38D3E652B358F85F4CB7901EA192D2253FA8AF89E11F7717898476BAFCE56FC0FEBAFA4F375786F21C4623F8AE2EFDF5A749CBF1B1DE514515F787F1885145140057E1DFF00C16DFF00E0AB777FB4878E352F84FE02D49A1F877A0DC18356BCB793FE465BA8DBE61B875B58D8614749194B1C8095F7BFFC171FF6D0B8FD92FF00639BAD3B44BC6B5F177C4491F43D3648DB6C96B015CDD5C2F7056321011CABCC87B57E487FC1287F60D6FDBCFF006A2B3D0EFD268FC15E1B8D754F11CD192A5ADC3623B656ECD330DB9072116461CAD7C571363EAD5AB1CAF0BF14BE2F9ECBD2DABF2F2B9FD6DF47DE09CB30196D7F10F88D2F6387BFB24D5F58FC534BACB9AD0A6BF9EFD5459EA5FF0004A9FF0082326B3FB6DADB78DFC6D2DF786FE18472FEE0C436'));
    dbms_lob.append(lob_out, hextoraw('5EF888A9C32C048FDDC20821A6C1C9055064165FDBAF823F007C17FB377816DFC37E05F0DE97E19D16DC0C5BD94214CADFDF91F9691CF777258F735D2787F40B1F0A68567A5E99676FA7E9BA74096D6B6D6F188E2B789142A2228E155540000E001572BDDCA725A181A7682BCFACBABF4ECBCBEFBB3F1AF133C58CE78CB1B2A98B9B861D3F72927EEC5746FF009A7DE4FCD2B2D028A28AF60FCB82AA6B82D64D2E686FA11716970861962309956456182A5403904641E3156E8A01369DD1F1CE93FF0004EDD53E141B8D37E15FC7AF8A5F0E7C1F24CF3DAF8762D321D4ED34C2EC5992DDAE212F1C5B8921327193C9AB9A6FFC13DA4F1AF8C345BEF8B5F18FE23FC5AD1FC3B791EA563A06A3A74563A63DD46731CB3C70443CFD8790AC719EB91907D5FF0068083E37CFE2F87FE15BCFE0B83475860694EAEAECECC25633A8DBCEE281021FBA332679DB5CA5EDCFED38BA36A5B6D3E1E9D4A4132588B7B8636F12B099A277322863223185081F23042DD4E070ACB70EB4B69DAEEDF75ED6F2B58FB1971F6792BC9D58F3BBDE7ECE92A8EEACDFB550F69CCFACB9B99F56749F04FF00671F0F7C1FF167C56D466BDBCD7EDBE2C6B8DACDFD8DEE94C6080342B0B418DA44885579DC39CE315C8FC22FD8D7FE19C2D7C6DA3FC39F887E26F0CF837C516F39D2F41974837B0F84EF251CDC5948E03AA8'));
    dbms_lob.append(lob_out, hextoraw('24B085F72038E98E7A2F8876FF00B425C6BB7CBE17B8F03DB5AB5C3FD8E4D411A48D22DB1ECDEAB872DFEB33823E7FF63159BA44FF00B4BAC91FF685BFC3D68E49E2925FB2CCFE645170258D032E0B0DF94663822162C14B855D7EA7474B2DAF6DEFAEFAF99E6FFAD199BF68A557995450524D45C5FB34941F2B4E378A49295AF6BABDA4EF93E13FF8269FC0DB0FD9FBC2BF0FBC49E135F1A59F85E49AF16FB55B39FED7797B3F3737323A004B4AD824648C2A0FE115CBEA1FF0496F83D0789F598F418753F0DF81FC55A32E95AFF856CED676B5BF9A290CB6B7D1C8D9782EA09082AEB9180411866CF68969FB5269B7C886EBE18EA962A61DCE565B7BA6DBE5F99FC2C9862CFDB2AB1F00961B6C78923FDA7A3F176ACDA6BFC309B414BA9FFB391BCF8EEE5B733C8D0EF241459044D146DC11FBA77EAE14672CB70AD24E9AD34DBA256B5F7B5B4F35A1DF4B8FB88E9CA728636A7BEDC9AE66E3CCE5CCE4A2FDD52E6F794924E32B4934D2671361FB127C4CD02CE3B2D33F6ACF8B90E9F6ABE5DB4775E1FB3BC99231C28799E0DD2103F88F26A4F889FB036B5E31F1D7837C61A7FC74F885A2F8E3C2DE1E97C3B73AF26856F3DC6AD14B399DD9D1A2F2D3E62000ABC2AA8CE4127A7D3EC3F6A89A2852F2F7E17C3242252D2C0B332DC3EE99E30CACBF2C7B5A08C953BB313B630C31A5A3DA7ED2'));
    dbms_lob.append(lob_out, hextoraw('92B6A4B7975F0E62867D3E45B1711CAD35ADE075DACF8F91E221A4C01860238F3B999F0BFB3A85B95A7FF814BA76D74F914B8F338551558CA9A96AAEA8D157524D494AD4FDE4D37752BAEBBEA73DE07FD91FC6F61E28B593C5DFB437C43F1CF864878F51D02F7C376705AEAD0B232B432B241BBCB6CFCC0609191919CD739A17FC13CB5EF85168747F86BFB437C58F03F8360766D3F416D320D521D2D4927CA864B884BAC4093B54938F53D6BD06DECFF694BDB2BA37575F0FEC6F6DE72F6C2D43CD6D7501F3DB6485D43ACA336E995F908466FE2C0DAF82BA77C7A4F880B2F8EB52F0337860C9211069D6D27DB045E4A888339217CCF33733E015C602E051FD9F43B3F5E695FEFBDEDE57B131E3ACE22DDA50B4AD78FB1A3C8DABD9B87B3E47257694B979926D5EDA1ADFB37F80F5AF833E16BEB3F157C47F167C4BD4AF2EBCE5BFD574B4B636D1ED004491C112A81905893924B76000AEF3E23EBB7DE19F877AF6A7A5D93EA5A9E9FA75C5D59DA28F9AEA6489992303D59801F8D6D515D51A6A30E48FF9FE67CF6231D3C4629E2ABA4DB69B4A2A317E5CB14925E891FC99EA7AB5D6B7AC5D5F5F319AFAEAE1EE2E8C83969598B3EE1EEC4E41AFD44FD957FE0E56D6B409ECF4AF8B7E09B0D434C40B11D5BC32BF67B88147196B5918A3E076474E9C29E95FA2FF001ABFE09ADF023F682BBBDB'));
    dbms_lob.append(lob_out, hextoraw('AF14FC2FF0ADDEA3A8333DC5FDB5AFD8AF2576EAE6680A396CF3924E4D7E7BFEDB9FF06DFCDA169379E20F81BADDD6A4D02995BC31AD4CA66900FE1B6BAC004FA24A39FF009E99E2BF3E59266B96B757073525D52DDDBBA7BFC9DFB1FDC353C5EF0DB8FE9D2CB38A70D2C3CA3750949FBB072B27CB520D38ECBE38A868B98FD3DFD9DFF69BF02FED5DF0F61F147807C4561E22D265C2C8D0B159AD1F19F2E689B0F138FEEB807BF2306BBCAFE60BF679FDA37E24FF00C13FBE3D49AC78766D43C37E24D267367ABE937D13C715DAA37CF6B7701C123AF5C329F99483835FD0A7EC1DFB6F785FF6F5F80D65E32F0EFF00A1DE46DF65D67499240D3E9176002D137F794E7723E006520F04328FA2C8F88218EFDD545CB5174E8FCD7EABA799F8478C1E0962B83E51CC705375F0351DA33D2F06F5519DB4775F0CD594BB2764FDA68A28AFA33F083F087FE0E2BF8D537C44FDBCE1F0BACDBAC3C01A1DBDA2C60E556E2E47DA656FA946814FFB82BEF6FF00837CBF67983E107EC1567E2796055D63E245FCDABCF211F3FD9A36682D90FF00B2151A41FF005D8D7E4AFF00C1597589759FF828E7C669E562CF1EBF24009FEEC51471AFE8A2BF7EBF60EF0F41E15FD893E11D85B285860F076958C772D691313F8924D7C1E42BDBE7188C44B78DD2FBECBF0563FB3BC66AAF26F0B724C970DA46B2A729'));
    dbms_lob.append(lob_out, hextoraw('5BADA9F3CBEFA9352F547AC57CC7FB51FF00C155FE1EFECE3F11FF00E103D2F4FF00137C4CF88F8F9BC33E12B137D756DD08F3D810B1F041DBF3300412A0104F6DFF00050DFDA16F3F656FD8B3E2278F34DDA355D0F4A61A7B30DCA97533AC10B907A8592456C770B8AF8CBE10FECED75FB257C29F0359DB78AE6D175AF186943C4FE2FD66C83B6B9AC6AB7305CCE05CDC09164FB1C3B70B1A73248AECC09CE7E9330C6558D4542868ED76F7B26ECACB4D5D9EFA24B667F3FF0004F0B65D88C24B36CDEF2873BA74E9A6E3CF38C54E6E524A5251829415A2B9A529A5CD149B3D622FF82D259FC39D56D57E2FFC13F8BDF08F45BE91628F5BD534A6B8D3E262401E6BA00CBD7A2AB1F6AFB1FC17E35D23E23784F4FD7B41D4ACB58D1756816E6CEF6D251341731B0C86565E0835F09F817F684F16786F47D53FE12AB18BC63E07BFD22CAF35AD135DBB96FEE4E9D712BC4B72AD3131BB3EF8C3C683CB00C5948CBB30D0FF00826FD937EC93FB747C5DFD9E34DBC9AEBC0274FB7F1E783A1964673A65BDCB2ACF6EA5B27609245C0FFA6658FCCEC6B1C2E3AB46A461565CD193B5DAB34ECDABDB469D9F44D3D19EC71270865B5B055F1197D1F615A8479DC63373A75209C233E5E6BCE1520E71934E528CE0DCA2D5ACFEF0AF9C7F6B7FF829FF00C3AFD937C656DE0F921F1078E3E215F20783C2BE'));
    dbms_lob.append(lob_out, hextoraw('17B237FA8804654C8010B1E472013B88390A4735E95FB5BFC6D3FB37FECC5E3CF1DA44B3CFE15D12EB50B78987CB2CC919F294FB193683EC6BE63FF8276FECDB27C0CFD8AF4FF893717924FF00173E2F4BA7EBBAFF0089A78A2B8BE717F770B2C2A64054208A5195E85D99BAED03B31988ABED161E8593B3936F5B25A68B4BB6F6BE9A36FB1F2FC2F91E5DF529E739BA73A6AA46953A71972FB4A925CCDCA76938D3846CE5CA9CA4E5151B6AD3AE3FE0B40FF0D2686EFE2AFC01F8CDF0CFC373B05FEDCBCD28DCDA5B67A19B68529D7A00CDE80D7D85F0D3E26F87FE3278174DF13785B57B1D7B40D62113D9DF59C8248A75E9C1EC410415382A41040208AF05F8F3F10BC57E1BF195F783E1B8F1278834B9B42BBBAD4F587B0D3DF4FD29C5B5C491417313DAED713088818738C80E1432EFF22FD907C2EBFB09FF00C151BC6BF03F4332C3F0D7E23787878EBC3BA6972D168B74B2F95710C59FBA8DB6438ECB1C43B127969E2ABD1AAA1565CF16F96ED24D37B6DA34F6DB476DF5B7BB8FE1ECA732CB6A6272FA2B0F88A74DD5508D4954854A51694BE35CF4E714F9D2726A504DDA3EEB97DE75F3CFED7FFF000531F871FB1E788ACFC33A8FF6D78B3C79A9A07B2F0AF86ECCDF6A93060769640408C1EDB8862390AC01AF56FDA13E2B47F02BE03F8CBC69344B3C7E14D12F356F29BA4A6185E4'));
    dbms_lob.append(lob_out, hextoraw('09F89503F1AF867FE09D3F0AB56F097C1CF07F8D45C594DF1ABF692377E24D6BC6BA8A24D2E8BA729494C76E8EAC0B185E3D919DB186625B7244919E8C762AAC671A143493576DABD95D2D16976DBB2BBB2D5BD8F1783F877035F095737CD53952849423052E4E79B8CA6F9A76938D3A708B94F962E72BC63157775DB5E7FC1676EBE1C2C7A87C4CFD9E7E367C3DF0B48406D72E74AFB45BDA83D1A6002941EB8C9F406BEBCF847F183C31F1E7E1FE9DE2AF07EB563E20F0FEAB1F996B7B68FBA390670411D5594E4156019482080462BE55F03FED51AA7C43D1BC67AA787FC7571E2C87C0F6526B177A16BADA3C96BE25D215AE619B0D676EB2DBCA7ECEECA1F7280F06F0566F978DFD98341B6FD887FE0A9D71F0E7C2B1C963F0BFE3BF861BC63A5E8B9C45A1EA50E4CCB12F44468D1C951C731A8E2315CB47195A9CE2E73E7849A5769269BD13D3469BD364D68F547D2E71C279762B0D5E386C3FD5B154612A9CB19CE709C6094A716AA2538548C25ED13BCA124A51F7648FD00AF05FDB0FFE0A37F0DFF62CB8B0D2FC4375A96B7E2FD60674DF0C6836A6FB56BD0720308C1011490402E467076EE2081EC3F11BC696FF000DFE1EEBDE22BB567B5D074EB8D466553CB2431B48C07E0A6BF323F642BBD6BC2DF036CFE39C9FD93AA7ED07FB486A97771A7EA5A91463A5D825C25BC765661C10'));
    dbms_lob.append(lob_out, hextoraw('B2485E144F9595165577578E028DD598E32A536A952D1B4DB6D5EC9596DA5DB6D24AEBBBD8F9DE07E16C263E15330CC6F2A50946118464A2EA549A9C92736A5C908C2139CE4A2E564A315795D7B85E7FC165F54F01DBAEADE3CFD9B7E397837C2279935A9B4AF3E3B543FC73261762F73C93F5AFAC3E05FC7BF087ED2DF0D6C3C5DE07D76CFC43E1FD441F2AE6DC9F9187DE8DD480D1C8BDD18061DC57C8FE32F14F8CBF672F8B567A4CBF1626F1478AB5E6F3A6F0FB7DA750B1D16158D031BD790B46B68CC577C816DE5067531232E223C87C08B8D37F64DFF829C781FF00E10BB56D07E1B7ED4BE1DB8D4A7F0E0F96DF46D6ED6332C86341F2A71F210A00CC8D8F95500E3A38CAF46A25565CD1BA4EE9269BD13D346AED26AC9ABA77DCFAACCF84728CC7033AB96D1F615634E5561CB29CA9D58D38B94E2D555CF1928467284E329427C9256578B7FA2F5E29FB617EDFFF000DFF00622D2AC1BC63A95D5C6B7AC9C695A06976FF006BD535339DBFBB841185DDC6E72AA4F0093C57B2EA37F1E95A7CF75336D86DA369643E8AA327F415F9D7FF0004E1D2DBE297807E237ED81E24D2E3F137C40F19EA7776FE178EE8074D074D866FB3430C3B8809F3060CC0A9291F51B9CB7A18EC4D48CA3468DB9A57777AA495AEEDD5EA925E7E47C4F08E4382C4D1AF9A669CCE8517082845A8CAA55AAE5C'));
    dbms_lob.append(lob_out, hextoraw('90E669A846D09CA72B36A31B25769AEE6E3FE0B23AF7866C975AF137ECC7F1E340F07F0F26AEDA4891A088FF00CB4922F976A81C9CB57D47FB387ED3BE07FDAD3E1A5BF8B3C03AFDAEBDA3DC1F2DDA3CA4D6B280098A68DB0D1C8323E56038208C8209F08B3F887E24F0E783B4DF195C78C75E875B8E48AF352D2EF558E9CB69246EE8A626C92B3C9E5C4B3C7B5639180C00191BCE3E22F816D3F603FF0082AC7C33F12782EDD747F06FED14D71A0789B44807976CBA946A2482ED231F2ABB348A0E3FE9B1EB21AE18E271141A9D4973C1B49DD24D733B26ADA357D1A6AFD6FA58FABC4F0FE4B9AC2A6170387FABE2630A93872CE73A753D945CE7092A8B9A32704E509465CB2768B8AE65221FF82E3FFC1326CBF697F84D7DF143C1FA6C71FC46F08DA19EED204C37882C231978DC0FBD344A0B46DD48531F395DBF99BFF048AFDB72E3F62BFDAF345BEBABC68FC19E2E922D1BC45116FDD88646C457247F7A1918367AEC6907F157F46846E1835FCD17FC14EFF678B7FD98FF006E9F88DE0FB1816DF474D43FB434D8D47CB15ADD22DC222FB279853FE015F3FC5185784AF4F32C3E8EFAFAF47F3574CFDC7E8EBC491E26C9B1BC019DBF694FD9B74EFAB506D465157FE4938CA1D9DEDA256FE9741C8A2BC2FF00E0999F1A2E3F681FD82BE1778A2F26F3F50BAD0E2B4BC909CB493DB16B6918'));
    dbms_lob.append(lob_out, hextoraw('FBB3C45BF1A2BEE68565569C6AC76924FEFD4FE3CCE32DAB9763EB65F5FE3A53941FAC64E2FF00147E1FFF00C168BC072F813FE0A61F14EDE452B1EA9776FAA427FBE93DAC4E48FF00816F1F857EDBFF00C12D3E24C5F15BFE09E5F08B568E4591A3F0E5B69D2907A4B6A3ECAE0FFC0A135F9F1FF07337ECDD369BE39F01FC58B3B726CF52B66F0D6A922AF11CD1979AD99BDDD1A75CFF00D3202BAAFF00836ABF6B8B7BBF0C78ABE0B6AB74A97B6333788741576FF5D0BED5BA857DD1C24981C912B9E8A6BE1B2C97D4F3CAB427A29DEDF3F797EABD4FEC2F1070EF8A7C1FCB738C27BD2C1A829A5BA508BA33D3D5464FFBBAEC7DF5FB7EFECEF71FB577EC6FF107C0362D1AEA5AFE96C2C0B9DAA6EA2659A004F60648D013D8135F11FECFBF1BB52FDAD7C3DE19B8B5F0E5D6A5E3EF867A1DBE87E2AF0BC9B23BA4BEB24BDB7659627747586632C477FDD05A452C19307F4F2BE29FF8294FEC6FF0BFC71E3CD0FC5D75E11F88963E3ABE49F1E27F87F29B4D46310A295594805247208C165DC238A53BB11ED3F4F9860AACEA2AF43576B34DDAE93BAB3B3B3577BAB3B9FCF5C13C5980C2E0E794E6B78D372738548C79B92528A8CD4A0A517284E318DDC64A51714D296A9F89F893E0CFC4EF87BF0E6EB55F1368F7567A2F87AD9249A3D53C982C64B38A669859CD73F680F140AEC5B20B6E63'));
    dbms_lob.append(lob_out, hextoraw('90AADB587AB7FC135EF2EFF6BCFDB3FE2CFED2B1E9F73A7782F52B183C17E0DFB445E5BDFDA5BB2B4F7014F4432C6B8F7675EA86BC97E017EC25E13FDA3FE3358E97F111BF692F88DA4E997192BE37F10634AB6DB009919E2450EE1C9DAB871B970C540702BF4E3C35E19D3BC19E1FB2D2748B1B3D2F4BD3A15B7B5B4B5856186DA351854445002A81C002B9B0797D675633AAB9631D52BDDB76695ECAC92BBD15EEECF4B6BEF714F1D659FD9F570B97CBDB57AC9C25515374E10A6E5094A318CA4E529CDC229C9A8F2C6F15CD74E3C6FED57F0517F68FFD9AFC73E036996DDBC57A2DD69D14CDF76195E322373ECAFB49F615F0FF00EC33F1AEDFE38F827C01F0E7C69E0DD4B5CF1D7C11D2B51F0AF89BC2BF6AB686F219236B38ED2F5229E7844D19861914BA16D8CC780AEACDFA01F153E26E93F06BE1DEADE28D724B88F49D16DCDCDCB4103CF26D181F2A282CC4920600EF5F1AFED31E14FD947F6EFF001DF86F50D47C4579A07C40D4FF0077A0F89341926D3354B845922851965D9B248F7CEA11A407859361011C8ECC7612ACA6ABD0B36959A7A26AE9EF67669AD34B6AD79AF97E0FE26C0E1F0B532ACD5CA34E52E785482BCA9D4E4941B7152839427195A569292718C95ECE32F69F06FC3CF137857F660BED3758D6741F01E83E4EA4648758B5371268B692CF70C9E6DC25E08F091B'));
    dbms_lob.append(lob_out, hextoraw('A1E1B0A06DDC71BABC37F62EF1137EDDFF00F052EF1B7C7DD2A1B8FF008569E06D0BFE104F0A5F49198D75A9BCDF36E6E630464A292E33DC4A9D08603C83C1FF00B36FECD9F17BE23693E1DF1B7ED1BF193E2E5BCB7104565A2EB9ABDD7F664F234E624476118C9DEBCE1D30191B38604FDD5FB387ED11F0B3558F45F027C3FB5B9D2AC6DADA68F49B18742B8B3B3FB3DBA42F2B44C6309B145CDB92D9E4DC47D4B5634B0D5EACE0EAC79611B3B5EEDB5B5EDA24B7D3776DAC7A598F1065397E1B151CBAB3C462312A517354FD9D3A709B4E7CBCCDCE739A8A8DE56518B96B294AEBBCF8F7F0AE0F8E7F043C61E0BBA93C983C57A35DE92D2E33E579F0B47BF1FECEECFE15F077EC1BF116EBE21FECF9A47C1BD523B5D27E3E7ECEF713E972F872FAE45AB78834EF2A4B774864231B25B5940590021248E1918796C33FA3B5F0A7EDB76BFB2CFED55F16E6D13C6575AF68DF13BC2D3C9696FACE856B7367AC5BB44D1A05495232255F326554DE186EDDB70326B6C7616A4E6ABD1B7324D34F4BA767BD9D9A6AE9D9ADD3DEEBC9E0FE24C161B0D532ACD39A34A728D48CE2B99D3A91528BBC1B8F3D39C24E338A9465F0CA2EEACED7843E176B9E2B821D26E6FB5AB1F0FD9682FA16BFA9EB5E1E97C3F1685A5B2D98BB85A49E79127B9961B086206D76DB46249E6DC4BA2B64FECC5E2B8FF6FEFF'));
    dbms_lob.append(lob_out, hextoraw('0082A6EADF183C371BC9F0AFE0EE812784741D5046521D6F5099899E4873F7A344775C8EDE51FE3E3C7AEFF673FD9E7C47E27B1D0FC7DFB457C7BF8ADA5ADAADEDB6817DA85E4F67709CB223F97164B95472143237CA7A1E2BF437F657F137C3FD43E1AAE89F0DB4CFEC5F0F7851D34E3A7AE972E9EB61218D26F2CA48AA4B94963763CE7CD049249AE5C3E0EBD49C5D58F2C534ED7BB6D6DE4927AEEDB7D9687D2E75C59946130B56396D6788AF5612A6A5ECFD9C29C2A5BDA357B4A739C5722F7611845B7EFC9B91DA78FF00C1D6DF113C07ADF87EF4B2D9EBB613E9F395EA239A368DB1F831AFCD9FD86B4793C4DE08D37F670F156BB69E07F8D7F01358B98B4B3796E1FF00B734B7B85B98EE2CF711FBC0C90BAB80DB56342C8EAEEB5F7FFED05FB4E7837F65EF0FE9FAA78D3529B4CB2D4EE5ED6078ACE6BA667586499B2B12B3002389D89C6062BE4AFDAA7E207EC99FB79DC69F6FE2A9F5CFF84A34A1FF0012CD6349D32F2CF57B1FB8556399622194C92A2AAB865F31F800926BAF30C1CEA4A356959C95D59E89A766D5D6CD349A7F2EA7CD705F1461B034AAE5D983946954946719C22A52A5520A5152E4934A71946728CE374DA6A49DE293F44D43F652F1FEA1A9F8F350BE6F873E164F17DCC3A94FA8DBDC5C5E369E2DE459CC522491C62582568D04BB1E0C8058E4F15E31FB39A6'));
    dbms_lob.append(lob_out, hextoraw('97FB64FF00C14ABC23A9781E59757F84FF00B2FF0087E7D1A1F1037CD0EBBAD5CC7E5486270007C21DE5978CA647CB2213E5317C21FD99FC61756FA4F8DFF6A7F8EDE32F0D1775B6D0F58D4EF12CEFD108CF3E47EF107AA953804F18AFB0BE147EDCBFB327ECF7F0BE4F0FF81F57D3747F0D784AD1AEA7B3D334ABA2B65175F364FDDEE632360076259D98724935C94F075AAD48BA91E48A69BD6EDB4EE968AC95F5EEF6D11F498EE2CCB32EC1D6860310F135EA4254E2D5374E9D38CE1ECE72BCE4E739BA57A715A4209B95E5267D497F651EA76335B4CBBE1B88DA2917FBCAC3047E46BF2EFF00641D1D7E12D978A3F659F146B577E11F885F0D758D4753F04DC6F31AF8AB47BC0EC520C82B2BB067263DAF9CED0A4A3EDFD04F8B1FB55F82FE09781FC3FE23F126A17161A3F89648E3B39FEC9248177C4D30320507CB1B57AB63920752057CD5FB627C45FD957F6C8D2E4D33E21B5F5C49E1BB8682D7C4567A7DD5BDC69320392D0DD227DC2CA40C868D990E0315C8ECCC3093A8E3568DB9A37567A269DAEAEB6D5269EB668F97E0BE26C2E0235B2FCC79950ACE12E68252953A90E6519A8C9A535CB39C2706D5E337669A44137C309BC4761A7E9568BF11AD6E62B85FB1DF5F69B32C364DE6C4F13287DEB02A3B3C9231330568D5F68206CE07C1E963FB61FF00C144FE18784FC0FA94DE27'));
    dbms_lob.append(lob_out, hextoraw('F007ECDB25EEBFE26F140632DBEA7AEDDB96586394921C897E6C824604A3276827CF750F829FB3AEA9A7DDE9BE24FDAD3E3C78A3C2BA7BCD0CBE1CB9D6AE592711A48E622A20CC88CB13052A30E70149240AFB0FF672FDA1BF67BF807F07B44D03E16C2D0787E6D41B4EB5B2D1F48BAB8B89EEBFD1C33CA36191DC9B9B7532484E4B819F970386182AF5A49558A84534DEB76ECD3495B44AE936EF776B58FAEC771665196E1EA4F2FC44B135E519C61EE38429FB48B84E6DC9F34A7C929463149462E4E5CCDA48FA7EBF067FE0E2F8608BFE0A2CAD0EDF324F0A69ED3E3FBFE65C819FF8085AFDCAF86BF11F48F8BBE04D2FC4DA05C4979A2EB500B9B2B8681E1FB4447EEC815C2B0561C8240C820F435FCEBFFC15CFE3CDB7ED09FF000508F891AE58CCB71A569B78BA259488728F1D9A081994F7569164607B8615C3C655631C1460F7725F827FD7CCFB5FA27E5F5AB71755C5417B94E8CAEFA5E528A4BE7AB5E8CFD72FF837FA477FF8264784433332AEA7AA84CF61F6D97A7E39A2BD33FE0941F08A7F823FF04EFF00855A1DDC260BD93465D4EE508C32C976EF74437B8F3803F4A2BDFCAE9B860E9425BA8C7F247E25E22E36962F8AB32C5517784EBD569F74E72B3F9EE771FB63FECC1A37ED8FFB3878A3E1EEB58861D72DB16B75B773585D21DF04EBEE9205240C65772F426BF9C68DFE'));
    dbms_lob.append(lob_out, hextoraw('217FC13FBF6A90DFBCF0EFC41F873AAF420B465D7F2F3209A36FA3C727BD7F50F5F18FFC15A7FE0941A5FEDF1E0D4F117870D9E8FF0014B41B731D8DDC9F241AC423245A5C11D3924A49CEC248395271E371264D3C5456270FFC487E2B7FBD3D51FAC7809E2B61B877115722CF75C062B495D5D424D72B6D7584E3EECFC927B269E6FECEDACFC29FF82C4695A5FC4A6D6BC41A6F88B46D32DF4AD7BC2B6BA908574E9A3964991C80BBD91A4762B2290B22A22B0CA328F48D17FE0963E03D026BE8EDF5CF19B69B7D1790F613DFC77112A1B38ED4E1A48D9C362357DE1B706690676BB29FC0FF000AF8BBE297EC03FB4235C5949AE7C3FF001F7866530DC412A6D62B9C98E58CE52685F00E0EE4618209E0D7EABFEC71FF00071DF823C75A759E93F1934B9BC17AE00B1BEB1A7C2F75A4DC9FEFB22EE9A0CFA62451C9DC3A56394F1452A91F638D7C935A5DE89FF93EE9FF00C03D6F13BE8E79965F5659A70A45E2B073F79460F9A704F549257F691FE5946EEDBAD399FD33AFFF00C12CFC13AFEB11DD378A3E225BC51CB3BA5AC5AD6D86059B974846CCC396C30284303D08AC093FE0903E10D8CABE3AF8892333CB219AE2EEDA79DDA4789C9676872D868C30FF006B6F61B4FBDFC2DFDA97E1AFC6DD3E3BAF08F8F3C23E228E51902C755865907B3206DCA7D8806BB8177130C892323D770AFA'));
    dbms_lob.append(lob_out, hextoraw('C8548CD7345DD791FCD18AC1E230D51D2C4425092DD4934D7C9EA57D63C3B63E23D0E6D3752B3B5D4F4FB98FCA9EDEEE259A29D7B875605581F423158B71F05FC1D776135ACDE13F0CCB6B732096685F4B81A395C640665DB82464E09E466BA2FB547FF3D23FFBE851F6A8FF00E7A47FF7D0AA39ECCE76F3E0C783F519AE24B8F09F866792E955266934B819A65500286257E60001807A62B674CF0D69DA295FB1E9F6569E582ABE4C0B1ED04282060770883FE00BE82ACFDAA3FF009E91FF00DF428FB547FF003D23FF00BE850166495CD5EFC19F07EA57F797571E13F0D5C5D6A05CDD4D26990349725F01B7B15CB6E0AB9CE7381E95D0FDAA3FF9E91FFDF428FB547FF3D23FFBE8501666441F0D3C376C6431F87F448CC931B872B6310DF29DD973F2F2C77373D7E63EA6B56CB4EB7D35196DEDE1B75721984681431002E4E3D801F40076A77DAA3FF9E91FFDF428FB547FF3D23FFBE85016643A9E8B67AD45E5DE5A5ADDA6D74DB344B20DAEA558608E8CA4823B82474ACB8FE1778661D2E4B15F0EE82B6535BB5A3DB8B08844F0B1DCD115DB8284F25718279C56D7DAA3FF009E91FF00DF428FB547FF003D23FF00BE85016663CDF0CBC37732C7249E1FD0E4921DBE5B358444A6D25860EDE30C4918E84E6A1BCF843E13D4136DC785FC3B3AE1C624D3616187DC1BAAFF0016F7CFAEF6F5'));
    dbms_lob.append(lob_out, hextoraw('35BDF6A8FF00E7A47FF7D0A3ED51FF00CF48FF00EFA1405999BAC780F43F1169F6769A868BA4DF5AE9ACAF690DC5A472C76ACAA554C6AC0852149008C601C554D37E11F853467DD67E18F0F5AB1D9CC3A74319F91362745FE14F947A0E0715BBF6A8FF00E7A47FF7D0A3ED51FF00CF48FF00EFA1405998327C20F094D64F6EFE17F0EB5BC912DBBC474D84A346AC5C211B7054312C07404E7AD49A5FC2CF0C689A89BCB2F0E6836776C1019E0D3E28E4210829F305CFCA4023D081547E237C7BF03FC20D2E4BDF1578C3C33E1CB5894B349A96A70DB0C0F4DEC33F41CD7C03FB6E7FC1C53E07F873A4DE68BF066D8F8E3C46CAD1AEB3750BC3A3D937F7D436D92E187A28543C1DE4715C38CCCF0D858F3579A5E5D5FA2DCFB1E14F0FF883892BAA194616752EF5959A847CE53768AFBEEFA26F43D73FE0B0FF00F0512D37F615FD9E65F0DF86EEADE2F88DE2DB46B3D12D2DC856D26DC828F7CCA3EE2A0C88C7F1498C0215F1F8E7FF0004D4FD8EEF3F6DEFDAE7C37E11F2269BC3F6B28D57C4771C9586C2260640CDFDE95B6C4BEF267A035C85959FC4EFDBF7F68EF2D3FB5FC79F10BC6171B9D9BE676C71B98F090C11AFFBA91A8EC057EFBFFC1323FE09DDA2FF00C13D7E060D1E3920D53C63AF14BAF11EAC8B817330076C31679104592141E492CC402D81F0F463573CC72AB356A30FEADE'));
    dbms_lob.append(lob_out, hextoraw('AFAF65F2BFF5E66B5B2DF07783A795E16AAA99A62D5DB5BA6D35CFDD429A6FD9DF594EEED67251FA3EDEDE3B4B78E18A358E28D422228DAA8A38000EC0514FA2BF463F84428A28A00F18FDB0FF00604F863FB73785534FF1E6829717D6A852C758B46FB3EA5A764E7F773007E5CF3B1C3213C9526BF2A3F69CFF008370FE2A7C38BDB8BCF86BAC693F10B4704B476B7122E9BAA20EB821CF9327A643A93FDD15FB7D4578F9864783C63E6AB1B4BBAD1FFC1F9A67EA3C0BE3171470A4551CB6BF351FF9F5517343E4AE9C7CF9251BF5B9FCBEFC43FD857E327C28BD64F107C29F1EE9AD19FF005DFD893CD11C7A4B1AB21FA86AE4FF00E100F1B43F2FF61F8C976F18FB15D0C7FE3B5FD57515F3B2E08A77F72AB4BCD27FAA3F75C3FD2FB30E44B13964252EEAA4A2BEE7193FC4FE547FE104F1B7FD017C65FF0080775FFC4D1FF08278DBFE80BE32FF00C03BAFFE26BFAAEA297FA92BFE7F3FFC07FE09B7FC4DF57FFA1547FF0006BFFE567F2A3FF08278DBFE80BE32FF00C03BAFFE268FF8413C6DFF00405F197FE01DD7FF00135FD575147FA92BFE7F3FFC07FE087FC4DF57FF00A1547FF06BFF00E567F2A3FF0008278DBFE80BE32FFC03BAFF00E268FF008413C6DFF405F197FE01DD7FF135FD575147FA92BFE7F3FF00C07FE087FC4DF57FFA1547FF0006BFFE567F2A3FF08278DBFE80BE'));
    dbms_lob.append(lob_out, hextoraw('32FF00C03BAFFE268FF8413C6DFF00405F197FE01DD7FF00135FD575147FA92BFE7F3FFC07FE087FC4DF57FF00A1547FF06BFF00E567F2A3FF0008278DBFE80BE32FFC03BAFF00E268FF008413C6DFF405F197FE01DD7FF135FD575147FA92BFE7F3FF00C07FE087FC4DF57FFA1547FF0006BFFE567F2A3FF08278DBFE80BE32FF00C03BAFFE268FF8413C6DFF00405F197FE01DD7FF00135FD575147FA92BFE7F3FFC07FE087FC4DF57FF00A1547FF06BFF00E567F2A3FF0008278DBFE80BE32FFC03BAFF00E2683E04F1B7FD017C65FF0080775FFC4D7F55D452FF005257FCFEFF00C97FE087FC4DF57FFA1547FF0006BFFE567F2DBE09FD913E2B7C53D4523D07E1A78FB5AB893A3C3A15CBAFD4BB26D03DC915F5F7ECBBFF0006EE7C62F8B97D6D79F102E74DF869A1310D224B225FEA922FA2C31B79687DDE40467EE9E95FBA945766178330B07CD5A4E5E5B2FC35FC4F9BE20FA58F12E2E93A395E1E9E1AFF006B5A925E9CD68FDF0678BFEC67FB02FC35FD84FC16DA5F81745F2EFAED15751D66F184DA96A64723CD97030A0F21102A0ECB9C93ED14515F59468C294153A4924B648FE66CD334C66638A9E371F56552ACDDE52936DB7E6DFE1D968B40A28A2B4380FFD9'));
    return(lob_out) ;
  end ;

    /*
     *
     * ----------------------------------------------------------------------------
     *  Algorithm
     *  ---------
     *
     *        Execute the routine action using the package state, input parameters, SQL statements,
     *    and external API calls implemented below.
     *
     *  Possible Issues
     *  ---------------
     *
     *       - Generated documentation: review input validation, exception handling,
     *         and assumptions about data cardinality before changing the code.
     *       - SQL queries and external package calls may propagate runtime errors
     *         unless they are explicitly handled in the implementation.
     *
     * ----------------------------------------------------------------------------
     *
     */
    procedure remove_plan_wbp(P_MIG_ID in number) IS
        BEGIN
            update migration_planned_operations
            set current_plan='N'
            ,comments='Plan removal : ' || to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')
            where mig_id = P_MIG_ID and current_plan='Y' ;
        EXCEPTION
            when others then raise_application_error(-20000,'Cannot unplanned mig id ' || P_MIG_ID) ;
    end ;

end;
/

