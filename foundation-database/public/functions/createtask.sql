DROP FUNCTION IF EXISTS createtask(TEXT, TEXT, TEXT, TEXT, BOOLEAN, TEXT, TEXT, TEXT, TEXT,
                                 JSON, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, DATE, DATE,
                                 DATE, TEXT) CASCADE;
DROP FUNCTION IF EXISTS createtask(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT,
                                 JSON, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, DATE, DATE,
                                 DATE, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION createtask (
    pParentType TEXT,
    pParent TEXT,
    pNumber TEXT,
    pStatus TEXT,
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

  INSERT INTO task (
    task_parent_type,
    task_parent_id,
    task_number,
    task_status,
    task_name,
    task_descrip,
    task_priority_id,
    task_owner_username,
    task_hours_budget,
    task_hours_actual,
    task_exp_budget,
    task_exp_actual,
    task_pct_complete,
    task_due_date,
    task_start_date,
    task_completed_date,
    task_notes
    )
  VALUES (
    _parenttype,
    _parentid,
    COALESCE(pNumber, fetchtasknumber()::TEXT),
    _status,
    pName,
    COALESCE(pDescrip,''),
    (SELECT incdtpriority_id FROM incdtpriority WHERE incdtpriority_name=pPriority),
    COALESCE(pOwner, getEffectiveXtUser()),
    COALESCE(pHoursBudget,0),
    COALESCE(pHoursActual,0),
    COALESCE(pExpBudget,0),
    COALESCE(pExpActual,0),
    pPercCmplt,
    pDueDate,
    pStartDate,
    pCompletedDate,
    pNotes
    )
  ON CONFLICT (task_parent_type, task_parent_id, task_number) DO UPDATE SET
    task_status=_status,
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
  RETURNING task_id INTO _taskid;
  
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
