CREATE OR REPLACE FUNCTION formatInvcLineNumber(pOrderitemId INTEGER) RETURNS TEXT AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _r RECORD;

BEGIN

  SELECT invcitem_linenumber AS linenumber, invcitem_subnumber AS subnumber
    INTO _r
    FROM invcitem
   WHERE invcitem_id = pOrderitemId;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  IF COALESCE(_r.subnumber, 0) > 0 THEN
    RETURN LPAD(_r.linenumber::TEXT, 3, '0') || '.' || LPAD(_r.subnumber::TEXT, 3, '0');
  ELSE
    RETURN LPAD(_r.linenumber::TEXT, 3, '0'); 
  END IF;

END
$$ language plpgsql;
