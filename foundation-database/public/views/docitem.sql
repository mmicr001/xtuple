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
       item_descrip1 AS docitem_item_descrip,
       quitem_qtyord * quitem_qty_invuomratio AS docitem_qty,
       quitem_price / quitem_price_invuomratio AS docitem_unitprice,
       quitem_qtyord * quitem_qty_invuomratio *
       quitem_price / quitem_price_invuomratio AS docitem_price,
       quitem_taxtype_id AS docitem_taxtype_id,
       0.0 AS docitem_freight,
       quitem_tax_exemption AS docitem_tax_exemption
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
       itemsite_item_id,
       itemsite_warehous_id,
       item_number,
       item_descrip1,
       coitem_qtyord * coitem_qty_invuomratio,
       coitem_price / coitem_price_invuomratio,
       coitem_qtyord * coitem_qty_invuomratio *
       coitem_price / coitem_price_invuomratio,
       coitem_taxtype_id,
       0.0,
       coitem_tax_exemption
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
       itemsite_item_id,
       itemsite_warehous_id,
       item_number,
       item_descrip1,
       cobill_qty * coitem_qty_invuomratio,
       coitem_price / coitem_price_invuomratio,
       cobill_qty * coitem_qty_invuomratio *
       coitem_price / coitem_price_invuomratio,
       cobill_taxtype_id,
       0.0,
       cobill_tax_exemption
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
       invcitem_item_id,
       COALESCE(NULLIF(invcitem_warehous_id, -1), invchead_warehous_id),
       COALESCE(item_number, invcitem_number),
       COALESCE(item_descrip1, invcitem_descrip),
       invcitem_billed * invcitem_qty_invuomratio,
       invcitem_price / invcitem_price_invuomratio,
       invcitem_billed * invcitem_qty_invuomratio *
       invcitem_price / invcitem_price_invuomratio,
       invcitem_taxtype_id,
       0.0,
       invcitem_tax_exemption
  FROM invcitem
  JOIN invchead ON invcitem_invchead_id = invchead_id
  LEFT OUTER JOIN item ON invcitem_item_id = item_id
UNION ALL
SELECT 'P',
       poitem_id,
       poitem_pohead_id,
       poitem_linenumber,
       0,
       formatPoLineNumber(poitem_id),
       item_id,
       COALESCE(NULLIF(itemsite_warehous_id, -1), pohead_warehous_id),
       COALESCE(item_number, expcat_code),
       COALESCE(item_descrip1, expcat_descrip),
       poitem_qty_ordered,
       poitem_unitprice,
       poitem_qty_ordered * poitem_unitprice,
       poitem_taxtype_id,
       poitem_freight,
       poitem_tax_exemption
  FROM poitem
  JOIN pohead ON poitem_pohead_id = pohead_id
  LEFT OUTER JOIN itemsite ON poitem_itemsite_id = itemsite_id
  LEFT OUTER JOIN item ON itemsite_item_id = item_id
  LEFT OUTER JOIN expcat ON poitem_expcat_id = expcat_id
UNION ALL
SELECT 'VCH',
       MIN(vodist_id),
       voitem_vohead_id,
       poitem_linenumber,
       0,
       formatPoLineNumber(poitem_id),
       item_id,
       COALESCE(NULLIF(itemsite_warehous_id, -1), pohead_warehous_id),
       COALESCE(item_number, expcat_code),
       COALESCE(item_descrip1, expcat_descrip),
       voitem_qty,
       poitem_unitprice,
       voitem_qty * poitem_unitprice,
       voitem_taxtype_id,
       voitem_freight,
       voitem_tax_exemption
  FROM voitem
  JOIN vodist ON voitem_vohead_id = vodist_vohead_id
             AND voitem_poitem_id = vodist_poitem_id
  JOIN poitem ON voitem_poitem_id = poitem_id
  JOIN pohead ON poitem_pohead_id = pohead_id
  LEFT OUTER JOIN itemsite ON poitem_itemsite_id = itemsite_id
  LEFT OUTER JOIN item ON itemsite_item_id = item_id
  LEFT OUTER JOIN expcat ON poitem_expcat_id = expcat_id
 GROUP BY voitem_id, voitem_vohead_id, voitem_qty, voitem_taxtype_id, voitem_freight,
          voitem_tax_exemption, poitem_id, poitem_linenumber, poitem_unitprice, pohead_warehous_id,
          itemsite_warehous_id, item_id, item_number, item_descrip1, expcat_code, expcat_descrip
UNION ALL
SELECT 'VCH',
       vodist_id,
       vodist_vohead_id,
       (SELECT COALESCE(MAX(poitem_linenumber), 0)
          FROM vohead
          JOIN pohead ON vohead_pohead_id = pohead_id
          JOIN poitem ON pohead_id = poitem_pohead_id) +
       (SELECT row
          FROM (
                SELECT vodist_id AS id, row_number() OVER (ORDER BY vodist_id) AS row
                  FROM vodist
                 WHERE vodist_vohead_id = vohead_id
                   AND COALESCE(vodist_poitem_id, -1) = -1
                   AND (COALESCE(vodist_accnt_id, -1) != -1 OR COALESCE(vodist_expcat_id, -1) != -1)
               ) rows
         WHERE id = vodist_id),
       0,
       'Misc Distrib. ' ||
       (SELECT row
          FROM (
                SELECT vodist_id AS id, row_number() OVER (ORDER BY vodist_id) AS row
                  FROM vodist
                 WHERE vodist_vohead_id = vohead_id
                   AND COALESCE(vodist_poitem_id, -1) = -1
                   AND (COALESCE(vodist_accnt_id, -1) != -1 OR COALESCE(vodist_expcat_id, -1) != -1)
               ) rows
         WHERE id = vodist_id),
       NULL,
       COALESCE(vodist_warehous_id, pohead_warehous_id),
       COALESCE(formatGLAccount(accnt_id), expcat_code),
       COALESCE(accnt_descrip, expcat_descrip),
       1,
       vodist_amount,
       vodist_amount,
       vodist_taxtype_id,
       0,
       vodist_tax_exemption
  FROM vodist
  JOIN vohead ON vodist_vohead_id = vohead_id
  LEFT OUTER JOIN pohead ON vohead_pohead_id = pohead_id
  LEFT OUTER JOIN accnt ON vodist_accnt_id = accnt_id
  LEFT OUTER JOIN expcat ON vodist_expcat_id = expcat_id
 WHERE COALESCE(vodist_poitem_id, -1) = -1
   AND (COALESCE(vodist_accnt_id, -1) != -1 OR COALESCE(vodist_expcat_id, -1) != -1)
UNION ALL
SELECT 'CM',
       cmitem_id,
       cmitem_cmhead_id,
       cmitem_linenumber,
       0,
       cmitem_linenumber::TEXT,
       item_id,
       COALESCE(NULLIF(itemsite_warehous_id, -1), invchead_warehous_id, cmhead_warehous_id),
       COALESCE(item_number, cmitem_number),
       COALESCE(item_descrip1, cmitem_descrip),
       cmitem_qtycredit * cmitem_qty_invuomratio,
       cmitem_unitprice / cmitem_price_invuomratio,
       cmitem_qtycredit * cmitem_qty_invuomratio * cmitem_unitprice / cmitem_price_invuomratio,
       COALESCE(invcitem_taxtype_id, cmitem_taxtype_id),
       0.0,
       cmitem_tax_exemption
  FROM cmitem
  JOIN cmhead ON cmitem_cmhead_id = cmhead_id
  LEFT OUTER JOIN itemsite ON cmitem_itemsite_id = itemsite_id
  LEFT OUTER JOIN item ON itemsite_item_id = item_id
  LEFT OUTER JOIN invchead ON cmhead_invcnumber = invchead_invcnumber
  LEFT OUTER JOIN invcitem ON invchead_id = invcitem_invchead_id
                          AND ((itemsite_item_id = invcitem_item_id
                                AND itemsite_warehous_id = invcitem_warehous_id)
                               OR cmitem_number = invcitem_number)
                          AND (SELECT num
                                 FROM (SELECT items.invcitem_id,
                                              row_number() OVER
                                              (ORDER BY invcitem_linenumber,
                                               invcitem_subnumber) AS num
                                         FROM invcitem items
                                        WHERE items.invcitem_invchead_id = invchead_id
                                          AND ((items.invcitem_item_id = itemsite_item_id AND
                                                items.invcitem_warehous_id = itemsite_warehous_id)
                                               OR items.invcitem_number = cmitem_number)) items
                                WHERE items.invcitem_id = invcitem.invcitem_id)=
                              (SELECT num
                                 FROM (SELECT items.cmitem_id,
                                              row_number() OVER 
                                              (ORDER BY invcitem_linenumber,
                                               invcitem_subnumber) AS num
                                         FROM cmitem items
                                        WHERE items.cmitem_cmhead_id = cmhead_id
                                          AND (items.cmitem_itemsite_id = cmitem.cmitem_itemsite_id
                                               OR items.cmitem_number = cmitem.cmitem_number)) items
                                WHERE items.cmitem_id = cmitem.cmitem_id)
UNION ALL
SELECT 'AR',
       aropen_id,
       aropen_id,
       1,
       0,
       '',
       NULL,
       NULL,
       '',
       '',
       1,
       aropen_amount,
       aropen_amount,
       NULL,
       0.0,
       NULL
  FROM aropen
UNION ALL
SELECT 'AP',
       apopen_id,
       apopen_id,
       1,
       0,
       '',
       NULL,
       NULL,
       '',
       '',
       1,
       apopen_amount,
       apopen_amount,
       NULL,
       0.0,
       NULL
  FROM apopen
UNION ALL
SELECT 'CK',
       checkhead_id,
       checkhead_id,
       1,
       0,
       '',
       NULL,
       NULL,
       '',
       '',
       1,
       checkhead_amount,
       checkhead_amount,
       NULL,
       0.0,
       NULL
  FROM checkhead
UNION ALL
SELECT 'CR',
       cashrcpt_id,
       cashrcpt_id,
       1,
       0,
       '',
       NULL,
       NULL,
       '',
       '',
       1,
       cashrcpt_amount,
       cashrcpt_amount,
       NULL,
       0.0,
       NULL
  FROM cashrcpt;
