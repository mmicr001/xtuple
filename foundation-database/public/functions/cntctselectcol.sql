DROP FUNCTION IF EXISTS cntctselectcol(integer, integer);

CREATE OR REPLACE FUNCTION cntctselectcol(pCntctId integer, pCol text) RETURNS boolean AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  if (pCntctid IS NOT NULL AND pCol IS NOT NULL) THEN
    EXECUTE format('UPDATE cntctsel SET %I=false WHERE (%I AND cntctsel_cntct_id != %L)', 
                   'cntctsel_mrg_cntct_'||pCol,
                   'cntctsel_mrg_cntct_'||pCol,
                   pCntctId);
    EXECUTE format('UPDATE cntctsel SET %I=true WHERE (cntctsel_cntct_id = %L)',
                   'cntctsel_mrg_cntct_'||pCol,
                   pCntctId);
    RETURN true;
  END IF;

  RETURN false;
END;
$$ LANGUAGE 'plpgsql';
