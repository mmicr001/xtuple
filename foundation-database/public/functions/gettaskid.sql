CREATE OR REPLACE FUNCTION gettaskid(pPrjNumber TEXT,
                                     pTaskNumber TEXT) 
  RETURNS INTEGER STABLE AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _returnVal INTEGER;
BEGIN
  IF (pPrjNumber IS NULL OR pTaskNumber IS NULL) THEN
	RETURN NULL;
  END IF;

  SELECT task_id INTO _returnVal
  FROM task
  JOIN prj ON prj_id=task_prj_id
  WHERE prj_number=pPrjNumber
    AND task_number=pTaskNumber
  LIMIT 1;

  IF (_returnVal IS NULL) THEN
	RAISE EXCEPTION 'Task Number % not found. [xtuple: gettaskid, -1, %]', pTaskNumber, pTaskNumber;
  END IF;

  RETURN _returnVal;
END;
$$ LANGUAGE plpgsql;
