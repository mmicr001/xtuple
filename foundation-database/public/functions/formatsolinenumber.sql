DROP FUNCTION IF EXISTS formatSoLineNumber(INTEGER) CASCADE;

CREATE OR REPLACE FUNCTION formatSoLineNumber(pOrderitemId   INTEGER,
                                              pOrderType TEXT DEFAULT 'SI') RETURNS TEXT AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _r RECORD;

BEGIN

  IF pOrderType = 'SI' THEN
    SELECT coitem_linenumber AS linenumber, coitem_subnumber AS subnumber
      INTO _r
      FROM coitem
     WHERE coitem_id = pOrderitemId;
  ELSIF pOrderType = 'QI' THEN
    SELECT quitem_linenumber AS linenumber, quitem_subnumber AS subnumber
      INTO _r
      FROM quitem
     WHERE quitem_id = pOrderitemId;
  END IF;

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
