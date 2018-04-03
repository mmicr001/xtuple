DROP FUNCTION IF EXISTS deleteIncident(INTEGER);

CREATE OR REPLACE FUNCTION deleteIncident(pincdtid INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _count      INTEGER := 0;
  _incdtnbr   INTEGER := 0;
BEGIN
  
  DELETE FROM task
   WHERE task_parent_id=pincdtid 
     AND task_parent_type='INCDT';

  DELETE FROM comment
   WHERE comment_source='INCDT'
     AND comment_source_id=pincdtid;

  DELETE FROM incdthist
   WHERE incdthist_incdt_id=pincdtid;

  DELETE FROM imageass
  WHERE imageass_source='INCDT'
     AND imageass_source_id=pincdtid;

  DELETE FROM docass
  WHERE docass_source_type='INCDT'
     AND docass_source_id=pincdtid;

  DELETE FROM url
  WHERE url_source='INCDT'
     AND url_source_id=pincdtid;

  SELECT incdt_number INTO _incdtnbr
  FROM incdt
  WHERE incdt_id=pincdtid;

  DELETE FROM incdt
    WHERE incdt_id=pincdtid;

-- Incident #11538 needs to be fully resolved before release can be implemented
--    PERFORM releaseIncidentNumber(_incdtnbr);

  RETURN 0;
END;
$$ LANGUAGE plpgsql;
