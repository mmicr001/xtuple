CREATE OR REPLACE FUNCTION getOrderTax(pOrderType TEXT, pOrderId INTEGER) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _result NUMERIC;

BEGIN
 
  SELECT SUM(taxdetail_tax)
    INTO _result
    FROM taxhead
    JOIN taxline ON taxhead_id = taxline_taxhead_id
    JOIN taxdetail ON taxline_id = taxdetail_taxline_id
   WHERE taxhead_doc_type = pOrderType
     AND taxhead_doc_id = pOrderId;

  RETURN COALESCE(_result, 0.0);

END
$$ language plpgsql;
