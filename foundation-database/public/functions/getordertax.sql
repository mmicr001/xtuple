CREATE OR REPLACE FUNCTION getOrderTax(pOrderType TEXT, pOrderId INTEGER) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _subtype TEXT;
  _result NUMERIC;

BEGIN
  IF pOrderType = 'Q' THEN
    _subtype := 'QI';
  ELSIF pOrderType = 'S' THEN
    _subtype := 'SI';
  ELSIF pOrderType = 'COB' THEN
    _subtype := 'COBI';
  ELSIF pOrderType = 'INV' THEN
    _subtype := 'INVI';
  ELSIF pOrderType = 'P' THEN
    _subtype := 'PI';
  ELSIF pOrderType = 'VCH' THEN
    _subtype := 'VCHI';
  END IF;
 
  SELECT SUM(taxhist_tax)
    INTO _result
    FROM (
          SELECT taxhist_tax
            FROM docitem
            JOIN taxhist ON taxhist_doctype = _subtype
                        AND taxhist_parent_id = docitem_id
           WHERE docitem_dochead_id = pOrderId
          UNION ALL
          SELECT taxhist_tax
            FROM taxhist
           WHERE taxhist_doctype = pOrderType
             AND taxhist_parent_id = pOrderId
         ) tax;

  RETURN COALESCE(_result, 0.0);

END
$$ language plpgsql;
