CREATE OR REPLACE FUNCTION calcCmheadAmt(INTEGER) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  pCmheadid ALIAS FOR $1;
  _amount NUMERIC := 0;

BEGIN

  SELECT SUM(COALESCE(extprice, 0)) INTO _amount
  FROM cmhead JOIN creditmemoitem ON (cmhead_id=cmitem_cmhead_id)
  WHERE (cmhead_id=pCmheadid);

  RETURN _amount;

END;
$$ LANGUAGE 'plpgsql';
