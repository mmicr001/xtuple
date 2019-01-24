DROP FUNCTION IF EXISTS deleteOpportunity(INTEGER);
DROP FUNCTION IF EXISTS deleteOpportunity(INTEGER, BOOLEAN);

CREATE OR REPLACE FUNCTION deleteOpportunity(pOpheadid INTEGER, pDelTasks BOOLEAN DEFAULT false) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _test INTEGER;
BEGIN

  IF (NOT pDelTasks) THEN
    IF EXISTS(SELECT 1 FROM task
              WHERE task_parent_id=pOpheadid 
              AND task_parent_type='OPP') THEN
      RAISE EXCEPTION 'The selected Opportunity cannot be deleted because there are Task Items assigned to it [xtuple: deleteOpportunity, -1]';
    END IF;
  END IF;

  SELECT quhead_id INTO _test
    FROM quhead
   WHERE(quhead_ophead_id=pOpheadid)
   LIMIT 1;
  IF(FOUND) THEN
    RAISE EXCEPTION 'The selected Opportunity cannot be deleted because there are Quotes assigned to it [xtuple: deleteOpportunity, -2]';
  END IF;

  SELECT cohead_id INTO _test
    FROM cohead
   WHERE(cohead_ophead_id=pOpheadid)
   LIMIT 1;
  IF(FOUND) THEN
    RAISE EXCEPTION 'The selected Opportunity cannot be deleted because there are Sales Orders assigned to it [xtuple: deleteOpportunity, -3]';
  END IF;

  DELETE FROM task
  WHERE task_parent_id=pOpheadid 
    AND task_parent_type='OPP';

  DELETE
    FROM ophead
   WHERE(ophead_id=pOpheadid);
  
  return 0;
END;
$$ LANGUAGE plpgsql;
