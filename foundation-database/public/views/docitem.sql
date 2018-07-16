DROP VIEW IF EXISTS docitem;
CREATE VIEW docitem AS
SELECT 'Q' AS docitem_type,
       quitem_id AS docitem_id,
       quitem_quhead_id AS docitem_dochead_id,
       quitem_linenumber AS docitem_linenumber,
       quitem_subnumber AS docitem_subnumber,
       formatSoLineNumber(quitem_id, 'QI') AS docitem_number,
       itemsite_item_id AS docitem_item_id,
       itemsite_warehous_id AS docitem_warehous_id,
       item_number AS docitem_item_number,
       quitem_qtyord * quitem_qty_invuomratio AS docitem_qty,
       quitem_price / quitem_price_invuomratio AS docitem_unitprice,
       quitem_qtyord * quitem_qty_invuomratio *
       quitem_price / quitem_price_invuomratio AS docitem_price,
       quitem_taxtype_id AS docitem_taxtype_id
  FROM quitem
  JOIN itemsite ON quitem_itemsite_id = itemsite_id
  JOIN item ON itemsite_item_id = item_id
UNION ALL
SELECT 'S',
       coitem_id,
       coitem_cohead_id,
       coitem_linenumber,
       coitem_subnumber,
       formatSoLineNumber(coitem_id, 'SI'),
       itemsite_item_id AS docitem_item_id,
       itemsite_warehous_id AS docitem_warehous_id,
       item_number AS docitem_item_number,
       coitem_qtyord * coitem_qty_invuomratio,
       coitem_price / coitem_price_invuomratio,
       coitem_qtyord * coitem_qty_invuomratio *
       coitem_price / coitem_price_invuomratio,
       coitem_taxtype_id
  FROM coitem
  JOIN itemsite ON coitem_itemsite_id = itemsite_id
  JOIN item ON itemsite_item_id = item_id
UNION ALL
SELECT 'COB',
       cobill_id,
       cobill_cobmisc_id,
       coitem_linenumber, 
       coitem_subnumber,
       formatSoLineNumber(coitem_id, 'SI'),
       itemsite_item_id AS docitem_item_id,
       itemsite_warehous_id AS docitem_warehous_id,
       item_number AS docitem_item_number,
       cobill_qty * coitem_qty_invuomratio,
       coitem_price / coitem_price_invuomratio,
       cobill_qty * coitem_qty_invuomratio *
       coitem_price / coitem_price_invuomratio,
       cobill_taxtype_id
  FROM cobill
  JOIN coitem ON cobill_coitem_id = coitem_id
  JOIN itemsite ON coitem_itemsite_id = itemsite_id
  JOIN item ON itemsite_item_id = item_id
UNION ALL
SELECT 'INV',
       invcitem_id,
       invcitem_invchead_id,
       invcitem_linenumber,
       invcitem_subnumber,
       formatInvcLineNumber(invcitem_id),
       invcitem_item_id AS docitem_item_id,
       COALESCE(NULLIF(invcitem_warehous_id, -1), invchead_warehous_id) AS docitem_warehous_id,
       COALESCE(item_number, invcitem_number) AS docitem_item_number,
       invcitem_billed * invcitem_qty_invuomratio,
       invcitem_price / invcitem_price_invuomratio,
       invcitem_billed * invcitem_qty_invuomratio *
       invcitem_price / invcitem_price_invuomratio,
       invcitem_taxtype_id
  FROM invcitem
  JOIN invchead ON invcitem_invchead_id = invchead_id
  LEFT OUTER JOIN item ON invcitem_item_id = item_id;
