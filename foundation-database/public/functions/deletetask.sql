DROP FUNCTION IF EXISTS deleteProjectTask(INTEGER);
DROP FUNCTION IF EXISTS deleteTask(INTEGER);

CREATE OR REPLACE FUNCTION deleteTask(pTaskId INTEGER, pDeleteSubs BOOLEAN DEFAULT FALSE) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
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
    RAISE EXCEPTION 'Actual Hours have been posted against this Task (or sub-task) [xtuple: deleteTask, -2]';
  END IF;

  IF (COALESCE(_row.task_exp_actual, 0.0) > 0.0) THEN
    RAISE EXCEPTION 'Actual Expenses have been posted against this Task (or sub-task) [xtuple: deleteTask, -3]';
  END IF;

  FOR _row IN 
    SELECT task_id FROM task
    WHERE task_parent_task_id = pTaskId 
  LOOP
    IF (NOT pDeleteSubs) THEN
    -- Return result indicates sub-tasks exist so the client has to ask whether to proceed
       RETURN -1;
    END IF;
    -- Recursively delete sub-tasks
    PERFORM deleteTask(_row.task_id, pDeleteSubs);
  END LOOP;

  DELETE FROM comment
  WHERE ((comment_source='TA')
  AND (comment_source_id=pTaskId));

  DELETE FROM task
   WHERE (task_id=pTaskId);

  RETURN 0;

END;
$$ LANGUAGE plpgsql;

