DROP FUNCTION IF EXISTS deleteOpportunity(INTEGER);

CREATE OR REPLACE FUNCTION deleteOpportunity(pOpheadid INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _test INTEGER;
BEGIN

  IF EXISTS(SELECT 1 FROM task
            WHERE task_parent_id=pOpheadid 
            AND task_parent_type='OPP') THEN
    RETURN -1;
  END IF;

  SELECT quhead_id INTO _test
    FROM quhead
   WHERE(quhead_ophead_id=pOpheadid)
   LIMIT 1;
  IF(FOUND) THEN
    RETURN -2;
  END IF;

  SELECT cohead_id INTO _test
    FROM cohead
   WHERE(cohead_ophead_id=pOpheadid)
   LIMIT 1;
  IF(FOUND) THEN
    RETURN -3;
  END IF;

  DELETE
    FROM charass
   WHERE((charass_target_type='OPP')
     AND (charass_target_id=pOpheadid));

  DELETE
    FROM comment
   WHERE((comment_source='OPP')
     AND (comment_source_id=pOpheadid));

  DELETE
    FROM ophead
   WHERE(ophead_id=pOpheadid);
  
  return 0;
END;
$$ LANGUAGE plpgsql;
