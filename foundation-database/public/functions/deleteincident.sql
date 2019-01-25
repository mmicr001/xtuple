DROP FUNCTION IF EXISTS deleteIncident(INTEGER);

CREATE OR REPLACE FUNCTION deleteIncident(pincdtid INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _incdtnbr   INTEGER := 0;
BEGIN
  
--  SELECT incdt_number INTO _incdtnbr
--  FROM incdt
--  WHERE incdt_id=pincdtid;

  DELETE FROM incdt
    WHERE incdt_id=pincdtid;

-- Incident #11538 needs to be fully resolved before release can be implemented
--    PERFORM releaseIncidentNumber(_incdtnbr);

  RETURN 0;
END;
$$ LANGUAGE plpgsql;
