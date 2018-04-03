DROP FUNCTION IF EXISTS _prjtasktrigger() CASCADE;

CREATE OR REPLACE FUNCTION _taskTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  --  Checks
  IF (NEW.task_owner_username=getEffectiveXtUser()) THEN
    IF (NEW.task_parent_type = 'J' AND NOT checkPrivilege('MaintainAllProjects') AND NOT checkPrivilege('MaintainPersonalProjects')) THEN
      RAISE EXCEPTION 'You do not have privileges to maintain Projects.';
    END IF;
    IF (NEW.task_parent_type <> 'J' AND NOT checkPrivilege('MaintainAllToDoItems') AND NOT checkPrivilege('MaintainPersonalToDoItems')) THEN
      RAISE EXCEPTION 'You do not have privileges to maintain Tasks.';
    END IF;
  ELSIF (NEW.task_parent_type = 'J' AND NOT checkPrivilege('MaintainAllProjects')) THEN
    RAISE EXCEPTION 'You do not have privileges to maintain Projects.';
  ELSIF (NEW.task_parent_type <> 'J' AND NOT checkPrivilege('MaintainAllToDoItems')) THEN
    RAISE EXCEPTION 'You do not have privileges to maintain Tasks.';
  ELSIF (LENGTH(COALESCE(NEW.task_number,'')) = 0) THEN
    RAISE EXCEPTION 'You must enter a valid number.';
  ELSIF (LENGTH(COALESCE(NEW.task_name,'')) = 0) THEN
    RAISE EXCEPTION 'You must enter a valid name.';
  END IF;

  -- Timestamps
  IF (TG_OP = 'INSERT') THEN
    NEW.task_created := now();
  ELSIF (TG_OP = 'UPDATE') THEN
    NEW.task_lastupdated := now();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prjtaskTrigger ON prjtask;
DROP TRIGGER IF EXISTS taskTrigger ON task;

CREATE TRIGGER taskTrigger
  BEFORE INSERT OR UPDATE
  ON task
  FOR EACH ROW
  EXECUTE PROCEDURE _taskTrigger();

DROP FUNCTION IF EXISTS _prjtaskAfterTrigger() CASCADE;

CREATE OR REPLACE FUNCTION _taskAfterTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  IF (TG_OP = 'INSERT') THEN
    PERFORM postComment('ChangeLog', 'TA', NEW.task_id, 'Created');

  ELSIF (TG_OP = 'UPDATE') THEN
    IF (OLD.task_start_date <> NEW.task_start_date) THEN
      PERFORM postComment('ChangeLog', 'TA', NEW.task_id, 'Start Date',
                          formatDate(OLD.task_start_date), formatDate(NEW.task_start_date));
    END IF;
    IF (OLD.task_due_date <> NEW.task_due_date) THEN
      PERFORM postComment('ChangeLog', 'TA', NEW.task_id, 'Due Date',
                          formatDate(OLD.task_due_date), formatDate(NEW.task_due_date));
    END IF;
    IF (OLD.task_completed_date <> NEW.task_completed_date) THEN
      PERFORM postComment('ChangeLog', 'TA', NEW.task_id, 'Completed Date',
                          formatDate(OLD.task_completed_date), formatDate(NEW.task_completed_date));
    END IF;
    IF (OLD.task_hours_actual != NEW.task_hours_actual) THEN
      PERFORM postComment('ChangeLog', 'TA', NEW.task_id, 'Actual Hours',
                          formatQty(OLD.task_hours_actual), formatQty(NEW.task_hours_actual));
    END IF;
    IF (OLD.task_exp_actual != NEW.task_exp_actual) THEN
      PERFORM postComment('ChangeLog', 'TA', NEW.task_id, 'Actual Expense',
                          formatMoney(OLD.task_exp_actual), formatMoney(NEW.task_exp_actual));
    END IF;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prjtaskAfterTrigger ON prjtask;
DROP TRIGGER IF EXISTS taskAfterTrigger ON task;

CREATE TRIGGER taskAfterTrigger
  AFTER INSERT OR UPDATE
  ON task
  FOR EACH ROW
  EXECUTE PROCEDURE _taskAfterTrigger();

CREATE OR REPLACE FUNCTION _taskAfterDeleteTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _recurid     INTEGER;
  _newparentid INTEGER;
BEGIN

  DELETE
  FROM charass
  WHERE charass_target_type = 'TASK'
    AND charass_target_id = OLD.task_id;

  SELECT recur_id INTO _recurid
    FROM recur
   WHERE ((recur_parent_id=OLD.task_id)
     AND  (recur_parent_type='TASK'));

  IF (_recurid IS NOT NULL) THEN
    RAISE DEBUG 'recur_id for deleted task item = %', _recurid;

    SELECT task_id INTO _newparentid
    FROM task
    WHERE ((task_recurring_task_id=OLD.task_id)
      AND (task_id!=OLD.task_id))
    ORDER BY task_due_date
    LIMIT 1;

    RAISE DEBUG '_newparentid for deleted task item = %', COALESCE(_newparentid, NULL);

    -- client is responsible for warning about deleting a recurring task
    IF (_newparentid IS NULL) THEN
      DELETE FROM recur WHERE recur_id=_recurid;
    ELSE
      UPDATE recur SET recur_parent_id=_newparentid
       WHERE recur_id=_recurid;

      UPDATE task SET task_recurring_task_id=_newparentid
      WHERE task_recurring_task_id=OLD.task_id
        AND task_id != OLD.task_id;

      RAISE DEBUG 'reparented recurrence';
    END IF;
  END IF;

  DELETE FROM alarm
   WHERE ((alarm_source='TODO')
      AND (alarm_source_id=OLD.task_id));

  DELETE FROM docass WHERE docass_source_id = OLD.task_id AND docass_source_type = 'TA';
  DELETE FROM docass WHERE docass_target_id = OLD.task_id AND docass_target_type = 'TA';

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prjtaskAfterDeleteTrigger ON prjtask;
DROP TRIGGER IF EXISTS taskAfterDeleteTrigger ON task;

CREATE TRIGGER taskAfterDeleteTrigger
  AFTER DELETE
  ON task
  FOR EACH ROW
  EXECUTE PROCEDURE _taskAfterDeleteTrigger();
