
DROP FUNCTION IF EXISTS copyTodoitem(INTEGER, DATE, INTEGER);

CREATE OR REPLACE FUNCTION copyTask(pParentTaskId INTEGER, pDate DATE, 
                                    pParentType TEXT DEFAULT 'TASK', pParentId INTEGER DEFAULT NULL) 
RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _duedate    DATE := COALESCE(pDate, CURRENT_DATE);
  _alarmid    INTEGER;
  _taskid INTEGER;
BEGIN
  INSERT INTO task(
            task_name,          
            task_number,        
            task_descrip,
            task_parent_type,   task_parent_id,
            task_created_by,    task_status,
            task_due_date,
            task_notes,        
            task_owner_username,task_priority_id,
            task_prj_id,
            task_recurring_task_id, task_istemplate )
    SELECT  task_name,          
            CASE WHEN (task_istemplate 
                       AND pParentType <> 'J' 
                       AND fetchmetrictext('TaskNumberGeneration') <> 'M') 
            THEN fetchTaskNumber()::TEXT              
            ELSE COALESCE(task_number, '10') END,
            task_descrip,
            COALESCE(pParentType, 'TASK'), pParentId,
            getEffectiveXtUser(), 'N',
            _duedate,
            task_notes,      
            COALESCE(NULLIF(task_owner_username,''), geteffectivextuser()), task_priority_id,
            CASE WHEN pParentType = 'J' THEN pParentId END,
            task_recurring_task_id, false
      FROM task
     WHERE task_id = pParentTaskId
  RETURNING task_id INTO _taskid;

  IF (_taskid IS NULL) THEN
    RAISE EXCEPTION 'Error copying Task [xtuple: copytask, -10]';
  END IF;

  INSERT INTO taskass(
           taskass_task_id, taskass_username, taskass_crmrole_id,
           taskass_assigned_date)
  SELECT   _taskid, taskass_username, taskass_crmrole_id,
           CURRENT_DATE
    FROM   taskass
   WHERE   taskass_task_id = pParentTaskId;

  -- If no default assignments are created, set the currenct user as assigned
  IF (NOT EXISTS (SELECT 1 FROM taskass 
                   WHERE taskass_task_id=_taskid)) THEN
     INSERT INTO taskass(taskass_task_id, taskass_username, taskass_crmrole_id,
                         taskass_assigned_date)
          VALUES (_taskid, geteffectivextuser(), getcrmroleid(), CURRENT_DATE);
  END IF;

  INSERT INTO charass (charass_target_type, charass_target_id, charass_char_id,
                       charass_value, charass_default)
  SELECT charass_target_type, _taskid, charass_char_id,
                       charass_value, charass_default
  FROM charass
  WHERE charass_target_type='TASK'
    AND charass_target_id = pParentTaskId;

  INSERT INTO docass(docass_source_id, docass_source_type,
                     docass_target_id, docass_target_type,
                     docass_purpose)
  SELECT _taskid, docass_source_type,
         docass_target_id, docass_target_type, 'S'
  FROM docass
  WHERE docass_source_type = 'TASK'
    AND docass_source_id = pParentTaskId;

  SELECT saveAlarm(NULL, NULL, _duedate,
                   CAST(alarm_time - DATE_TRUNC('day',alarm_time) AS TIME),
                   alarm_time_offset,
                   alarm_time_qualifier,
                   (alarm_event_recipient IS NOT NULL), alarm_event_recipient,
                   (alarm_email_recipient IS NOT NULL AND fetchMetricBool('EnableBatchManager')), alarm_email_recipient,
                   (alarm_sysmsg_recipient IS NOT NULL), alarm_sysmsg_recipient,
                   'TASK', _taskid, 'CHANGEONE')
    INTO _alarmid
    FROM alarm
   WHERE alarm_source='TASK'
     AND alarm_source_id = pParentTaskId;

   IF (_alarmid < 0) THEN
     RETURN _alarmid;
   END IF;

  RETURN _taskid;
END;
$$ LANGUAGE plpgsql;
