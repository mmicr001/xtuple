DROP FUNCTION IF EXISTS deleteProjectTask(INTEGER);

CREATE OR REPLACE FUNCTION deleteTask(pTaskId INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _row RECORD;
  _result INTEGER;
BEGIN

  SELECT * INTO _row
    FROM task
   WHERE (task_id=pTaskId)
   LIMIT 1;
  IF (NOT FOUND) THEN
    RAISE EXCEPTION 'Could not find Task [xtuple: deleteTask, -1]';
  END IF;

  IF (COALESCE(_row.task_hours_actual, 0.0) > 0.0) THEN
    RAISE EXCEPTION 'Actual Hours have been posted against this Task [xtuple: deleteTask, -2]';
  END IF;

  IF (COALESCE(_row.task_exp_actual, 0.0) > 0.0) THEN
    RAISE EXCEPTION 'Actual Expenses have been posted against this Task [xtuple: deleteTask, -3]';
  END IF;

  DELETE FROM task
   WHERE (task_id=pTaskId);

  RETURN 0;

END;
$$ LANGUAGE plpgsql;

