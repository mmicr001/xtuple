DROP FUNCTION IF EXISTS updatetask(TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN, TEXT, TEXT, TEXT, TEXT,
                                 JSON, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, DATE, DATE,
                                 DATE, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION updatetask (
    pParentType TEXT,
    pParent TEXT,
    pOldNumber TEXT,
    pNewNumber TEXT,
    pStatus TEXT,
    pActive BOOLEAN,
    pName TEXT,
    pDescrip TEXT,
    pPriority TEXT,
    pOwner TEXT,
    pAssignments JSON,
    pHoursBudget NUMERIC,
    pHoursActual NUMERIC,
    pExpBudget NUMERIC,
    pExpActual NUMERIC,
    pPercCmplt NUMERIC,
    pDueDate DATE,
    pStartDate DATE,
    pCompletedDate DATE,
    pNotes TEXT
    )
RETURNS integer AS $$
DECLARE
  _parenttype TEXT;
  _parentid  INTEGER;
  _status    TEXT;
  _taskid    INTEGER;
  _assignments JSON;
BEGIN
-- Validate data
  IF ( COALESCE(pParentType,'') = '' 
    OR COALESCE(pNewNumber,'') = '' 
    OR COALESCE(pStatus,'') = '' 
    OR COALESCE(pName,'') = '') THEN
    
    RAISE EXCEPTION 'Insufficient information supplied to save this task [xtuple: savetask, -1]';
  END IF;

  _parentid := CASE pParentType
               WHEN 'Incident'    THEN getincidentid(pParent::INTEGER)
               WHEN 'Opportunity' THEN getopheadid(pParent)
               WHEN 'Project'     THEN getPrjId(pParent)
               WHEN 'Account'     THEN getcrmacctid(pParent)
               WHEN 'Contact'     THEN getcntctid(pParent, false)
               END;
  _parenttype := CASE pParentType
                 WHEN 'Incident'    THEN 'INCDT'
                 WHEN 'Opportunity' THEN 'OPP'
                 WHEN 'Project'     THEN 'J'
                 WHEN 'Account'     THEN 'CRMA'
                 WHEN 'Contact'     THEN 'T'
                 ELSE 'TA'  END;
  _status := CASE pStatus
             WHEN 'New'        THEN 'N'       
             WHEN 'In-Process' THEN 'O'
             WHEN 'Completed'  THEN 'C'
             WHEN 'Deferred'   THEN 'D'
             WHEN 'Pending'    THEN 'P'
             ELSE 'P' END;

  UPDATE task SET
    task_number=pNewNumber,
    task_status=_status,
    task_active=COALESCE(pActive, true),
    task_name=pName,
    task_descrip=COALESCE(pDescrip,''),
    task_priority_id=(SELECT incdtpriority_id FROM incdtpriority WHERE incdtpriority_name=pPriority),
    task_owner_username=COALESCE(pOwner, getEffectiveXtUser()),
    task_hours_budget=COALESCE(pHoursBudget,0),
    task_hours_actual=COALESCE(pHoursActual,0),
    task_exp_budget=COALESCE(pExpBudget,0),
    task_exp_actual=COALESCE(pExpActual,0),
    task_pct_complete=pPercCmplt,
    task_due_date=pDueDate,
    task_start_date=pStartDate,
    task_completed_date=pCompletedDate,
    task_notes=pNotes
  WHERE task_parent_type=_parenttype
    AND task_parent_id=_parentid
    AND task_number=pOldNumber
  RETURNING task_id INTO _taskid;
  
  DELETE FROM taskass WHERE taskass_task_id=_taskid;

  IF (pAssignments IS NOT NULL) THEN 
    _assignments := json_extract_path(pAssignments, 'assigned');
    INSERT INTO taskass (taskass_task_id,taskass_crmrole_id, taskass_username, taskass_assigned_date)
    SELECT _taskid, getcrmroleid(json_array_elements(_assignments)->>'role'), 
           json_array_elements(_assignments)->>'username', 
           (json_array_elements(_assignments)->>'assigned_date')::DATE
      ON CONFLICT DO NOTHING; 
  END IF;

  RETURN _taskid;

END; $$ LANGUAGE plpgsql;
