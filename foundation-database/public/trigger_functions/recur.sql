CREATE OR REPLACE FUNCTION _recurAfterTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _parentid   INTEGER;
  _parenttype TEXT;
BEGIN
  IF (TG_OP = 'DELETE') THEN
    IF (UPPER(OLD.recur_parent_type) = 'TASK') THEN
      UPDATE task SET task_recurring_task_id=NULL
       WHERE task_recurring_task_id=OLD.recur_parent_id;
    END IF;

    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS recurAfterTrigger ON recur;

CREATE TRIGGER recurAfterTrigger AFTER DELETE ON recur FOR EACH ROW EXECUTE PROCEDURE _recurAfterTrigger();
