CREATE OR REPLACE FUNCTION getOrderTax(pOrderType TEXT, pOrderId INTEGER) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _result NUMERIC;

BEGIN
 
  IF pOrderType = 'Q' THEN
    SELECT SUM(taxhist_tax)
      INTO _result
      FROM (
            SELECT taxhist_tax
              FROM quitem
              JOIN taxhist ON taxhist_doctype = 'QI'
                          AND taxhist_parent_id = quitem_id
             WHERE quitem_quhead_id = pOrderId
            UNION
            SELECT taxhist_tax
              FROM taxhist
             WHERE taxhist_doctype = 'Q'
               AND taxhist_parent_id = pOrderId
           ) tax;
  ELSIF pOrderType = 'S' THEN
    SELECT SUM(taxhist_tax)
      INTO _result
      FROM (
            SELECT taxhist_tax
              FROM coitem
              JOIN taxhist ON taxhist_doctype = 'SI' 
                          AND taxhist_parent_id = coitem_id
             WHERE coitem_cohead_id = pOrderId
            UNION
            SELECT taxhist_tax
              FROM taxhist
             WHERE taxhist_doctype = 'S' 
               AND taxhist_parent_id = pOrderId
           ) tax;
  ELSIF pOrderType = 'COB' THEN
    SELECT SUM(taxhist_tax)
      INTO _result
      FROM (
            SELECT taxhist_tax
              FROM cobill
              JOIN taxhist ON taxhist_doctype = 'COBI'
                          AND taxhist_parent_id = cobill_id
             WHERE cobill_cobmisc_id = pOrderId
            UNION
            SELECT taxhist_tax
              FROM taxhist
             WHERE taxhist_doctype = 'COB'
               AND taxhist_parent_id = pOrderId
           ) tax;
  ELSIF pOrderType = 'INV' THEN
    SELECT SUM(taxhist_tax)
      INTO _result
      FROM (
            SELECT taxhist_tax
              FROM invcitem
              JOIN taxhist ON taxhist_doctype = 'INVI'
                          AND taxhist_parent_id = invcitem_id
             WHERE invcitem_invchead_id = pOrderId
            UNION
            SELECT taxhist_tax
              FROM taxhist
             WHERE taxhist_doctype = 'INV'
               AND taxhist_parent_id = pOrderId
           ) tax;
  ELSIF pOrderType = 'P' THEN
    SELECT SUM(taxhist_tax)
      INTO _result
      FROM (
            SELECT taxhist_tax
              FROM poitem
              JOIN taxhist ON taxhist_doctype = 'PI'
                          AND taxhist_parent_id = poitem_id
             WHERE poitem_pohead_id = pOrderId
            UNION
            SELECT taxhist_tax
              FROM taxhist
             WHERE taxhist_doctype = 'P'
               AND taxhist_parent_id = pOrderId
           ) tax;
  END IF;

  RETURN COALESCE(_result, 0.0);

END
$$ language plpgsql;
