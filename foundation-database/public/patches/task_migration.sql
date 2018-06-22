DO $_$
DECLARE
  _rec  RECORD;
  _nid  INTEGER;
  _defaultpriority INTEGER;
  _tab  TEXT;
  _tabs TEXT[] := ARRAY[ 'alarm', 'charass', 'comment', 'docass',
                         'prjtask', 'task', 'taskass', 'todoitem' ];
BEGIN
FOREACH _tab IN ARRAY _tabs LOOP
  IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = _tab) THEN
    EXECUTE format('ALTER TABLE %I DISABLE TRIGGER ALL;', _tab);
  END IF;
END LOOP;

_defaultpriority := COALESCE((SELECT incdtpriority_id FROM incdtpriority
                               WHERE incdtpriority_name='Normal'), 1);

IF EXISTS (
   SELECT 1
   FROM   information_schema.tables 
   WHERE  table_schema = 'public'
   AND    table_name = 'prjtask') THEN

-- =====================================
-- Migrate Project Tasks
-- =====================================
  FOR _rec IN 
    SELECT 
      prjtask_id,
      prjtask_number,
      prjtask_name,
      prjtask_descrip,
      prjtask_prj_id,
      prjtask_status,
      prjtask_owner_username,
      prjtask_start_date,
      prjtask_due_date,
      prjtask_assigned_date,
      prjtask_completed_date,
      prjtask_username,
      prjtask_hours_budget,
      prjtask_hours_actual,
      prjtask_exp_budget,
      prjtask_exp_actual
    FROM prjtask
  LOOP
    INSERT INTO task (
      task_number,
      task_name,
      task_descrip,
      task_parent_type,
      task_parent_id,
      task_prj_id,
      task_status,
      task_owner_username,
      task_priority_id, 
      task_start_date,
      task_due_date,
      task_completed_date,
      task_hours_budget,
      task_hours_actual,
      task_exp_budget,
      task_exp_actual,
      task_notes
    )
    VALUES  
     (_rec.prjtask_number,
      _rec.prjtask_name,
      _rec.prjtask_descrip,
      'J',
      _rec.prjtask_prj_id,
      _rec.prjtask_prj_id,
      _rec.prjtask_status,
      _rec.prjtask_owner_username,
      _defaultpriority,
      _rec.prjtask_start_date,
      _rec.prjtask_due_date,
      _rec.prjtask_completed_date,
      _rec.prjtask_hours_budget,
      _rec.prjtask_hours_actual,
      _rec.prjtask_exp_budget,
      _rec.prjtask_exp_actual,
      ''
     )
    ON CONFLICT DO NOTHING
    RETURNING task_id INTO _nid;

    IF (_rec.prjtask_username IS NOT NULL) THEN
      INSERT INTO taskass (
        taskass_task_id,
        taskass_username,
        taskass_assigned_date)
      VALUES 
       (_nid,
        _rec.prjtask_username,
        _rec.prjtask_assigned_date);
    END IF;

    UPDATE alarm SET alarm_source_id = _nid
    WHERE alarm_source = 'J' AND alarm_source_id = _rec.prjtask_id;

    UPDATE comment SET comment_source_id = _nid
    WHERE comment_source = 'TA' AND comment_source_id = _rec.prjtask_id;

    UPDATE docass SET docass_source_id = _nid
    WHERE docass_source_type = 'TASK' AND docass_source_id = _rec.prjtask_id;

    UPDATE charass SET charass_target_id = _nid
    WHERE charass_target_type = 'TASK' AND charass_target_id = _rec.prjtask_id;

  END LOOP;

  DROP TABLE IF EXISTS prjtask CASCADE;
END IF;

IF EXISTS (
   SELECT 1
   FROM   information_schema.tables 
   WHERE  table_schema = 'public'
   AND    table_name = 'todoitem') THEN

-- =====================================
-- Migrate ToDo Items
-- =====================================

  UPDATE todoitem
     SET todoitem_priority_id = _defaultpriority
   WHERE todoitem_priority_id NOT IN (SELECT incdtpriority_id FROM incdtpriority);

  -- we must map recurring todoitems to the tasks they become to preserve the chain
  CREATE TEMPORARY TABLE todorecurrences ON COMMIT DROP AS
    SELECT DISTINCT todoitem_recurring_todoitem_id AS todoitem_id, -1 AS task_id FROM todoitem;

  FOR _rec IN 
    SELECT
      todoitem_id, 
      todoitem_name,
      todoitem_description,
      CASE WHEN todoitem_incdt_id   IS NOT NULL THEN 'INCDT'
           WHEN todoitem_ophead_id  IS NOT NULL THEN 'OPP'
           WHEN todoitem_crmacct_id IS NOT NULL THEN 'CRMA'
           WHEN todoitem_cntct_id   IS NOT NULL THEN 'T' 
           ELSE 'TASK' END AS parent_type,
      COALESCE(todoitem_incdt_id, todoitem_ophead_id, todoitem_crmacct_id, todoitem_cntct_id, todoitem_id) AS parent_id,
      CASE WHEN todoitem_incdt_id IS NOT NULL THEN (SELECT incdt_prj_id FROM incdt WHERE incdt_id=todoitem_incdt_id) END AS prj_id,
      CASE WHEN todoitem_status = 'I' THEN 'O' ELSE todoitem_status END AS status,
      todoitem_owner_username,
      todoitem_priority_id,
      todoitem_start_date,
      todoitem_due_date,
      todoitem_assigned_date,
      todoitem_completed_date,
      todoitem_username,
      todoitem_notes,
      todoitem_recurring_todoitem_id,
      todoitem_creator_username
    FROM todoitem
   ORDER BY todoitem_recurring_todoitem_id
  LOOP
    INSERT INTO task (
      task_number,
      task_name,
      task_descrip,
      task_parent_type,
      task_parent_id,
      task_prj_id,
      task_status,
      task_owner_username,
      task_priority_id, 
      task_start_date,
      task_due_date,
      task_completed_date,
      task_pct_complete,
      task_notes,
      task_created,
      task_created_by,
      task_lastupdated)
    VALUES ( 
      _rec.todoitem_name,
      _rec.todoitem_name,
      _rec.todoitem_description,
      _rec.parent_type,
      _rec.parent_id,
      _rec.prj_id,
      _rec.status,
      _rec.todoitem_owner_username,
      _rec.todoitem_priority_id,
      _rec.todoitem_start_date,
      _rec.todoitem_due_date,
      _rec.todoitem_completed_date,
      0,
      _rec.todoitem_notes,
      now(),
      _rec.todoitem_creator_username,
      now())
    ON CONFLICT DO NOTHING
    RETURNING task_id INTO _nid;

    IF _nid IS NOT NULL THEN
      UPDATE todorecurrences SET task_id = _nid WHERE todoitem_id = _rec.todoitem_id;

      UPDATE task
         SET task_recurring_task_id = (SELECT task_id FROM todorecurrences
                                        WHERE todoitem_id = _rec.todoitem_recurring_todoitem_id);

      IF _rec.todoitem_username IS NOT NULL THEN
        INSERT INTO taskass (
          taskass_task_id,
          taskass_username,
          taskass_assigned_date)
        VALUES 
         (_nid,
          _rec.todoitem_username,
          _rec.todoitem_assigned_date);
      END IF;

      UPDATE alarm SET alarm_source_id = _nid
      WHERE alarm_source = 'TODO' AND alarm_source_id = _rec.todoitem_id;

      UPDATE comment SET comment_source_id = _nid
      WHERE comment_source = 'TD' AND comment_source_id = _rec.todoitem_id;

      UPDATE docass SET docass_source_id = _nid
      WHERE docass_source_type = 'TODO' AND docass_source_id = _rec.todoitem_id;
    END IF;

  END LOOP;  

  DROP TABLE IF EXISTS todoitem CASCADE;
END IF;

UPDATE recurtype SET recurtype_type = 'TASK', 
                     recurtype_table = 'task', 
                     recurtype_donecheck='task_completed_date IS NOT NULL',
                     recurtype_schedcol='task_due_date',
                     recurtype_copyfunc='copytask',
                     recurtype_limit=$$checkprivilege('MaintainAllTaskItems') 
                                     OR (checkprivilege('MaintainPersonalTaskItems') 
                                         AND (CURRENT_USER = task_owner_username 
                                              OR task_id IN (SELECT taskass_task_id 
                                                             FROM taskass 
                                                             WHERE taskass_username = CURRENT_USER)
                                             )
                                        )$$
WHERE recurtype_type = 'TODO';

-- =====================================
-- DROP deprecated objects
-- =====================================
DROP VIEW IF EXISTS api.todo;

DROP FUNCTION IF EXISTS getprjtaskid(TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS createTodoItem(INTEGER, TEXT, TEXT, TEXT, INTEGER, INTEGER, INTEGER, DATE, DATE, CHARACTER(1), DATE, DATE, INTEGER, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS createTodoItem(INTEGER, TEXT, TEXT, TEXT, INTEGER, INTEGER, INTEGER, DATE, DATE, CHARACTER(1), DATE, DATE, INTEGER, TEXT, TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS updateTodoItem(INTEGER, TEXT, TEXT, TEXT, INTEGER, INTEGER, INTEGER, DATE, DATE, CHARACTER(1), DATE, DATE, INTEGER, TEXT, BOOLEAN, TEXT) CASCADE;
DROP FUNCTION IF EXISTS updateTodoItem(INTEGER, TEXT, TEXT, TEXT, INTEGER, INTEGER, INTEGER, DATE, DATE, CHARACTER(1), DATE, DATE, INTEGER, TEXT, BOOLEAN, TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS deleteTodoItem(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS copytask(INTEGER, DATE, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS todoitem() CASCADE;
DROP FUNCTION IF EXISTS todoItemMove(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS todoItemMoveUp(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS todoItemMoveDown(INTEGER, INTEGER) CASCADE;

DELETE from report 
where report_name IN ('TodoItem', 'TodoList')
AND report_grade = 0;

FOREACH _tab IN ARRAY _tabs LOOP
  IF EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = _tab) THEN
    EXECUTE format('ALTER TABLE %I ENABLE TRIGGER ALL;', _tab);
  END IF;
END LOOP;

END; $_$ LANGUAGE plpgsql;
