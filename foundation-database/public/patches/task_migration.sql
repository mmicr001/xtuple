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

-- =====================================
-- Migrate Project Tasks
-- =====================================
IF EXISTS (SELECT 1
             FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = 'prjtask') THEN

  CREATE TEMPORARY TABLE prjtaskmap (prjtask_id INTEGER, task_id INTEGER) ON COMMIT DROP;

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

    IF _nid IS NOT NULL THEN
      INSERT INTO prjtaskmap (task_id, prjtask_id) VALUES (_nid, _rec.prjtask_id);
    END IF;
  END LOOP;

  INSERT INTO taskass (taskass_task_id, taskass_username, taskass_assigned_date)
                SELECT task_id,         prjtask_username, prjtask_assigned_date
                  FROM prjtask
                  NATURAL JOIN prjtaskmap
                 WHERE prjtask_username IS NOT NULL;

  UPDATE alarm SET alarm_source_id = _nid
    FROM prjtaskmap
   WHERE alarm_source = 'J' AND alarm_source_id = prjtask_id;

  UPDATE comment SET comment_source_id = _nid
    FROM prjtaskmap
   WHERE comment_source = 'TA' AND comment_source_id = prjtask_id;

  UPDATE docass SET docass_source_id = _nid
    FROM prjtaskmap
   WHERE docass_source_type = 'TASK' AND docass_source_id = prjtask_id;

  UPDATE charass SET charass_target_id = _nid
    FROM prjtaskmap
   WHERE charass_target_type = 'TASK' AND charass_target_id = prjtask_id;

  FOR _rec IN SELECT fn.nspname, ft.relname, attname, conname
                FROM pg_constraint key
                JOIN pg_class      tab ON confrelid        = tab.oid
                JOIN pg_namespace  nsp ON tab.relnamespace = nsp.oid
                JOIN pg_attribute  col ON key.conrelid     = attrelid
                                      AND attnum IN (SELECT * FROM unnest(conkey))
                JOIN pg_class      ft  ON attrelid         = ft.oid
                JOIN pg_namespace  fn  ON ft.relnamespace  = fn.oid
               WHERE contype = 'f'
                 AND nsp.nspname = 'public'
                 AND tab.relname = 'prjtask'
                 AND confrelid != conrelid
  LOOP
    EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT IF EXISTS %I;', _rec.nspname, _rec.relname, _rec.conname);
    RAISE WARNING 'Upgrade the % extension! The constraint % has been dropped',
                  _rec.nspname, _rec.conname;
    EXECUTE format('UPDATE %I.%I
                       SET %I = task_id
                      FROM prjtaskmap
                     WHERE %I = prjtask_id;',
                   _rec.nspname, _rec.relname, _rec.attname, _rec.attname);
  END LOOP;

  DROP TABLE IF EXISTS prjtask CASCADE;
END IF;

-- =====================================
-- Migrate ToDo Items
-- =====================================
IF EXISTS (SELECT 1
             FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = 'todoitem') THEN

  UPDATE todoitem
     SET todoitem_priority_id = _defaultpriority
   WHERE todoitem_priority_id NOT IN (SELECT incdtpriority_id FROM incdtpriority);

  CREATE TEMPORARY TABLE todotaskmap (todoitem_id INTEGER, task_id INTEGER) ON COMMIT DROP;

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
      INSERT INTO todotaskmap (task_id, todoitem_id) VALUES (_nid, _rec.todoitem_id);
    END IF;
  END LOOP;

  UPDATE task
     SET task_recurring_task_id = map.task_id
    FROM todotaskmap map
   WHERE task_recurring_task_id = map.todoitem_id;

  INSERT INTO taskass (taskass_task_id, taskass_username,  taskass_assigned_date)
                SELECT task_id,         todoitem_username, todoitem_assigned_date
                  FROM todoitem
                  NATURAL JOIN todotaskmap
                 WHERE todoitem_username IS NOT NULL;

  UPDATE alarm SET alarm_source_id = task_id
    FROM todotaskmap
   WHERE alarm_source = 'TODO' AND alarm_source_id = todoitem_id;

  UPDATE comment SET comment_source_id = task_id
    FROM todotaskmap
   WHERE comment_source = 'TD' AND comment_source_id = todoitem_id;

  UPDATE docass SET docass_source_id = task_id
    FROM todotaskmap
   WHERE docass_source_type = 'TODO' AND docass_source_id = todoitem_id;

  FOR _rec IN SELECT fn.nspname, ft.relname, attname
                FROM pg_constraint key
                JOIN pg_class      tab ON confrelid        = tab.oid
                JOIN pg_namespace  nsp ON tab.relnamespace = nsp.oid
                JOIN pg_attribute  col ON key.conrelid     = attrelid
                                      AND attnum IN (SELECT * FROM unnest(conkey))
                JOIN pg_class      ft  ON attrelid         = ft.oid
                JOIN pg_namespace  fn  ON ft.relnamespace  = fn.oid
               WHERE contype = 'f'
                 AND nsp.nspname = 'public'
                 AND tab.relname = 'prjtask'
                 AND confrelid != conrelid
  LOOP
    EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT IF EXISTS %I;', _rec.nspname, _rec.relname, _rec.conname);
    RAISE WARNING 'Upgrade the % extension! The constraint % has been dropped',
                  _rec.nspname, _rec.conname;
    EXECUTE format('UPDATE %I.%I
                       SET %I = task_id
                      FROM todotaskmap
                     WHERE %I = prjtask_id;',
                   _rec.nspname, _rec.relname, _rec.attname, _rec.attname);
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
