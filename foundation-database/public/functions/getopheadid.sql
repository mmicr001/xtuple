CREATE OR REPLACE FUNCTION getOpHeadId(text) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pOpHeadNumber ALIAS FOR $1;
  _returnVal INTEGER;
BEGIN
  
  IF (pOpHeadNumber IS NULL) THEN
    RETURN NULL;
  END IF;

  SELECT ophead_id INTO _returnVal
  FROM ophead
  WHERE (UPPER(ophead_number)=UPPER(pOpHeadNumber));
  
  IF (_returnVal IS NULL) THEN
      RAISE EXCEPTION 'Opportunity % not found.', pOpHeadNumber;
  END IF;

  RETURN _returnVal;
END;
$$ LANGUAGE 'plpgsql';
