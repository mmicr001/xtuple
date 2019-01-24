CREATE OR REPLACE FUNCTION creditmemototal(INTEGER) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pCreditmemoId ALIAS FOR $1;
  _result       NUMERIC;

BEGIN

  -- TO DO:  Add in line item taxes
  SELECT COALESCE(cmhead_freight,0.0) + COALESCE(cmhead_misc,0.0) +
         ( SELECT COALESCE(ROUND(SUM((cmitem_qtycredit * cmitem_qty_invuomratio) * cmitem_unitprice / cmitem_price_invuomratio), 2), 0.0)
             FROM cmitem
            WHERE (cmitem_cmhead_id=cmhead_id)
           ) + getOrderTax('CM', pCreditmemoId)
           INTO _result
  FROM cmhead
  WHERE (cmhead_id=pCreditmemoId);

  IF (NOT FOUND) THEN
    return 0;
  ELSE
    RETURN _result;
  END IF;

END;
$$ LANGUAGE 'plpgsql';

