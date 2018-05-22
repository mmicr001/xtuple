CREATE OR REPLACE FUNCTION public.applydefaulttasks(
    ptype text,
    pcategory integer,
    pparentid integer,
    poverride boolean DEFAULT false)
  RETURNS integer AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _table     TEXT;
  _template  INTEGER;
BEGIN

  IF (pType IS NULL OR pCategory IS NULL OR pParentId IS NULL) THEN
    RAISE EXCEPTION 'Missing input parameters [xtuple: applyDefaultTasks, -1]';
  END IF;

  -- First Check if Tasks already exist for object
  IF (EXISTS(SELECT 1 FROM task 
             WHERE task_parent_id=pParentId 
               AND task_parent_type=pType)) THEN
    IF (NOT pOverride) THEN
      RETURN -2; -- Ask whether to delete existing tasks
    ELSE
      DELETE FROM task 
      WHERE task_parent_type=pType 
        AND task_parent_id=pParentId;
    END IF;
  END IF;
                       
  _table := CASE pType WHEN 'J' THEN 'prjtype'
                       WHEN 'OPP' THEN 'optype'
                       WHEN 'INCDT' THEN 'incdtcat'
                       END;
  
  EXECUTE format('SELECT %1$s_tasktmpl_id FROM %1$s WHERE %1$s_id = %2$s',
                 _table, pCategory) INTO _template;
           
  IF (_template IS NULL) THEN
    RETURN 0;
  END IF;

  PERFORM copyTask(task_id, CURRENT_DATE+(task_due_date::DATE-task_created::DATE)::INT, pType, pParentId)
  FROM task
  WHERE task_id IN (SELECT tasktmplitem_task_id 
                    FROM tasktmplitem
                    WHERE tasktmplitem_tasktmpl_id = _template)
    AND task_istemplate;

  RETURN 1;
END;
$$ LANGUAGE plpgsql;

