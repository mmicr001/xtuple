CREATE OR REPLACE FUNCTION _taskassAfterTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  IF (TG_OP = 'UPDATE') THEN
    IF (OLD.taskass_assigned_date <> NEW.taskass_assigned_date) THEN
      PERFORM postComment('ChangeLog', 'TA', NEW.task_id, 'Assigned Date',
                          formatDate(OLD.taskass_assigned_date), formatDate(NEW.taskass_assigned_date));
    END IF;
  END IF;

  RETURN NEW;

END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS taskassAfterTrigger ON taskass;

CREATE TRIGGER taskassAfterTrigger
  AFTER INSERT OR UPDATE
  ON taskass
  FOR EACH ROW
  EXECUTE PROCEDURE _taskassAfterTrigger();
