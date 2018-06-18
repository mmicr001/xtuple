CREATE OR REPLACE FUNCTION calculateOrderTax(pOrderType TEXT, pOrderId INTEGER) RETURNS JSONB AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _precision INTEGER := 2;
  _number TEXT;
  _taxzoneid INTEGER;
  _fromline1 TEXT;
  _fromline2 TEXT;
  _fromline3 TEXT;
  _fromcity TEXT;
  _fromstate TEXT;
  _fromzip TEXT;
  _fromcountry TEXT;
  _toline1 TEXT;
  _toline2 TEXT;
  _toline3 TEXT;
  _tocity TEXT;
  _tostate TEXT;
  _tozip TEXT;
  _tocountry TEXT;
  _custid INTEGER;
  _currid INTEGER;
  _docdate DATE;
  _freight NUMERIC;
  _misc NUMERIC;
  _freighttaxtype INTEGER;
  _misctaxtype INTEGER;
  _miscdiscount BOOLEAN;
  _linenums TEXT[];
  _qtys NUMERIC[];
  _taxtypeids INTEGER[];
  _amounts NUMERIC[];

BEGIN
 
  IF pOrderType = 'Q' THEN
    SELECT quhead_number, quhead_taxzone_id, addr_line1, addr_line2, addr_line3, addr_city,
           addr_state, addr_postalcode, addr_country, quhead_shiptoaddress1, quhead_shiptoaddress2,
           quhead_shiptoaddress3, quhead_shiptocity, quhead_shiptostate, quhead_shiptozipcode,
           quhead_shiptocountry, quhead_cust_id, quhead_curr_id, quhead_quotedate, quhead_freight,
           quhead_misc, quhead_freight_taxtype_id, quhead_misc_taxtype_id, quhead_misc_discount
      INTO _number, _taxzoneid, _fromline1, _fromline2, _fromline3, _fromcity,
           _fromstate, _fromzip, _fromcountry, _toline1, _toline2,
           _toline3, _tocity, _tostate, _tozip,
           _tocountry, _custid, _currid, _docdate, _freight,
           _misc, _freighttaxtype, _misctaxtype, _miscdiscount
      FROM quhead
      JOIN whsinfo ON quhead_warehous_id = warehous_id
      LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
     WHERE quhead_id = pOrderId;

    _linenums := ARRAY(SELECT formatSoLineNumber(quitem_id, 'QI')
                         FROM quitem
                        WHERE quitem_quhead_id = pOrderId
                        ORDER BY quitem_linenumber, quitem_subnumber);

    _qtys := ARRAY(SELECT ROUND(quitem_qtyord * quitem_qty_invuomratio, 6)
                     FROM quitem
                    WHERE quitem_quhead_id = pOrderId
                    ORDER BY quitem_linenumber, quitem_subnumber);

    _taxtypeids := ARRAY(SELECT quitem_taxtype_id
                           FROM quitem
                          WHERE quitem_quhead_id = pOrderId
                          ORDER BY quitem_linenumber, quitem_subnumber);

    _amounts := ARRAY(SELECT ROUND(quitem_qtyord * quitem_qty_invuomratio *
                                   quitem_price / quitem_price_invuomratio, _precision)
                        FROM quitem
                       WHERE quitem_quhead_id = pOrderId
                       ORDER BY quitem_linenumber, quitem_subnumber);
  ELSIF pOrderType = 'S' THEN
    SELECT cohead_number, cohead_taxzone_id, addr_line1, addr_line2, addr_line3, addr_city,
           addr_state, addr_postalcode, addr_country, cohead_shiptoaddress1, cohead_shiptoaddress2,
           cohead_shiptoaddress3, cohead_shiptocity, cohead_shiptostate, cohead_shiptozipcode,
           cohead_shiptocountry, cohead_cust_id, cohead_curr_id, cohead_orderdate, cohead_freight,
           cohead_misc, cohead_freight_taxtype_id, cohead_misc_taxtype_id, cohead_misc_discount
      INTO _number, _taxzoneid, _fromline1, _fromline2, _fromline3, _fromcity,
           _fromstate, _fromzip, _fromcountry, _toline1, _toline2,
           _toline3, _tocity, _tostate, _tozip,
           _tocountry, _custid, _currid, _docdate, _freight,
           _misc, _freighttaxtype, _misctaxtype, _miscdiscount
      FROM cohead
      JOIN whsinfo ON cohead_warehous_id = warehous_id
      LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
     WHERE cohead_id = pOrderId;

    _linenums := ARRAY(SELECT formatSoLineNumber(coitem_id)
                         FROM coitem
                        WHERE coitem_cohead_id = pOrderId
                        ORDER BY coitem_linenumber, coitem_subnumber);

    _qtys := ARRAY(SELECT ROUND(coitem_qtyord * coitem_qty_invuomratio, 6)
                     FROM coitem
                    WHERE coitem_cohead_id = pOrderId
                    ORDER BY coitem_linenumber, coitem_subnumber);

    _taxtypeids := ARRAY(SELECT coitem_taxtype_id
                           FROM coitem
                          WHERE coitem_cohead_id = pOrderId
                          ORDER BY coitem_linenumber, coitem_subnumber);

    _amounts := ARRAY(SELECT ROUND(coitem_qtyord * coitem_qty_invuomratio *
                                   coitem_price / coitem_price_invuomratio, _precision)
                        FROM coitem
                       WHERE coitem_cohead_id = pOrderId
                       ORDER BY coitem_linenumber, coitem_subnumber);
  ELSIF pOrderType = 'COB' THEN
    SELECT cohead_number, cobmisc_taxzone_id, addr_line1, addr_line2, addr_line3, addr_city,
           addr_state, addr_postalcode, addr_country, cohead_shiptoaddress1, cohead_shiptoaddress2,
           cohead_shiptoaddress3, cohead_shiptocity, cohead_shiptostate, cohead_shiptozipcode,
           cohead_shiptocountry, cohead_cust_id, cohead_curr_id, cohead_orderdate, cobmisc_freight,
           cobmisc_misc, cobmisc_freight_taxtype_id, cobmisc_misc_taxtype_id, cobmisc_misc_discount
      INTO _number, _taxzoneid, _fromline1, _fromline2, _fromline3, _fromcity,
           _fromstate, _fromzip, _fromcountry, _toline1, _toline2,
           _toline3, _tocity, _tostate, _tozip,
           _tocountry, _custid, _currid, _docdate, _freight,
           _misc, _freighttaxtype, _misctaxtype, _miscdiscount
      FROM cobmisc
      JOIN cohead ON cobmisc_cohead_id = cohead_id
      JOIN whsinfo ON cohead_warehous_id = warehous_id
      LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
     WHERE cobmisc_id = pOrderId;

    _linenums := ARRAY(SELECT formatSoLineNumber(coitem_id)
                         FROM cobill
                         JOIN coitem ON cobill_coitem_id = coitem_id
                        WHERE cobill_cobmisc_id = pOrderId
                        ORDER BY coitem_linenumber, coitem_subnumber);

    _qtys := ARRAY(SELECT ROUND(cobill_qty * coitem_qty_invuomratio, 6)
                     FROM cobill
                     JOIN coitem ON cobill_coitem_id = coitem_id
                    WHERE cobill_cobmisc_id = pOrderId
                    ORDER BY coitem_linenumber, coitem_subnumber);

    _taxtypeids := ARRAY(SELECT cobill_taxtype_id
                           FROM cobill
                           JOIN coitem ON cobill_coitem_id = coitem_id
                          WHERE cobill_cobmisc_id = pOrderId
                          ORDER BY coitem_linenumber, coitem_subnumber);

    _amounts := ARRAY(SELECT ROUND(cobill_qty * coitem_qty_invuomratio *
                                   coitem_price / coitem_price_invuomratio, _precision)
                        FROM cobill
                        JOIN coitem ON cobill_coitem_id = coitem_id
                       WHERE cobill_cobmisc_id = pOrderId
                       ORDER BY coitem_linenumber, coitem_subnumber);
  END IF;

  RETURN calculateTax(pOrderType, _number, _taxzoneid, _fromline1, _fromline2, _fromline3,
                      _fromcity, _fromstate, _fromzip, _fromcountry, _toline1, _toline2, _toline3,
                      _tocity, _tostate, _tozip, _tocountry, _custid, _currid, _docdate, _freight,
                      _misc, _freighttaxtype, _misctaxtype, _miscdiscount, _linenums, _qtys,
                      _taxtypeids, _amounts);

END
$$ language plpgsql;
