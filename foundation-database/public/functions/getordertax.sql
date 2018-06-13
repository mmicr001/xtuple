CREATE OR REPLACE FUNCTION getOrderTax(pOrderType TEXT, pOrderId INTEGER) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _result NUMERIC;

BEGIN
 
  IF pOrderType = 'Q' THEN
    SELECT SUM(taxhist_tax)
      INTO _result
      FROM quitem
      JOIN taxhist ON (taxhist_doctype = 'Q' AND taxhist_parent_id = pOrderId)
                   OR (taxhist_doctype = 'QI' AND taxhist_parent_id = quitem_id)
     WHERE quitem_quhead_id = pOrderId;
  ELSIF pOrderType = 'S' THEN
    SELECT SUM(taxhist_tax) 
      INTO _result
      FROM coitem
      JOIN taxhist ON (taxhist_doctype = 'S' AND taxhist_parent_id = pOrderId)
                   OR (taxhist_doctype = 'SI' AND taxhist_parent_id = coitem_id)
     WHERE coitem_cohead_id = pOrderId;
  ELSIF pOrderType = 'COB' THEN
    SELECT SUM(taxhist_tax) 
      INTO _result
      FROM cobill
      JOIN taxhist ON (taxhist_doctype = 'COB' AND taxhist_parent_id = pOrderId)
                   OR (taxhist_doctype = 'COBI' AND taxhist_parent_id = cobill_id)
     WHERE cobill_cobmisc_id = pOrderId;
  END IF;

  RETURN _result;

END
$$ language plpgsql;
