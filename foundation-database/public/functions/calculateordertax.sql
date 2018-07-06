CREATE OR REPLACE FUNCTION calculateOrderTax(pOrderType TEXT, pOrderId INTEGER, pRecord BOOLEAN DEFAULT TRUE) RETURNS JSONB AS $$
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
  _freightline1 TEXT[];
  _freightline2 TEXT[];
  _freightline3 TEXT[];
  _freightcity TEXT[];
  _freightstate TEXT[];
  _freightzip TEXT[];
  _freightcountry TEXT[];
  _freightsplit NUMERIC[];
  _linenums TEXT[];
  _qtys NUMERIC[];
  _taxtypeids INTEGER[];
  _amounts NUMERIC[];
  _lineline1 TEXT[];
  _lineline2 TEXT[];
  _lineline3 TEXT[];
  _linecity TEXT[];
  _linestate TEXT[];
  _linezip TEXT[];
  _linecountry TEXT[];
  _override NUMERIC;

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

    SELECT array_agg(addr_line1), array_agg(addr_line2), array_agg(addr_line3),
           array_agg(addr_city), array_agg(addr_state), array_agg(addr_postalcode),
           array_agg(addr_country),
           array_agg(freight)
      INTO _freightline1, _freightline2, _freightline3,
           _freightcity, _freightstate, _freightzip,
           _freightcountry,
           _freightsplit
      FROM
      (
       SELECT addr_line1, addr_line2, addr_line3,
              addr_city, addr_state, addr_postalcode, addr_country,
              SUM((freight).freightdata_total) AS freight
         FROM
         (
          SELECT itemsite_warehous_id,
                 calculateFreightDetail(cust_id, custtype_id, custtype_code,
                                        COALESCE(shipto_id, -1),
                                        shipto_shipzone_id, COALESCE(shipto_num, ''),
                                        quhead_quotedate,
                                        quhead_shipvia, quhead_curr_id, currConcat(quhead_curr_id),
                                        itemsite_warehous_id, item_freightclass_id,
                                        SUM(quitem_qtyord * quitem_qty_invuomratio *
                                            (item_prodweight +
                                             CASE WHEN fetchMetricBool('IncludePackageWeight')
                                                  THEN item_packweight
                                                  ELSE 0
                                              END
                                            )
                                           )
                                       ) AS freight
            FROM quhead
            JOIN custinfo ON quhead_cust_id = cust_id
            JOIN custtype ON cust_custtype_id = custtype_id
            JOIN shiptoinfo ON quhead_shipto_id = shipto_id
            JOIN quitem ON quhead_id = quitem_quhead_id
            JOIN itemsite ON quitem_itemsite_id = itemsite_id
            JOIN item ON itemsite_item_id = item_id
           WHERE quhead_id = pOrderId
           GROUP BY itemsite_warehous_id, cust_id, custtype_id, custtype_code, shipto_id,
                    shipto_shipzone_id, shipto_num, quhead_quotedate, quhead_shipvia,
                    quhead_curr_id, item_freightclass_id
         ) freights
         JOIN whsinfo ON itemsite_warehous_id = warehous_id
         LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
        GROUP BY addr_line1, addr_line2, addr_line3,
                 addr_city, addr_state, addr_postalcode, addr_country
      ) data;

    SELECT array_agg(formatSoLineNumber(quitem_id, 'QI')),
           array_agg(ROUND(quitem_qtyord * quitem_qty_invuomratio, 6)),
           array_agg(quitem_taxtype_id),
           array_agg(ROUND(quitem_qtyord * quitem_qty_invuomratio *
                     quitem_price / quitem_price_invuomratio, _precision)),
           array_agg(addr_line1),
           array_agg(addr_line2),
           array_agg(addr_line3),
           array_agg(addr_city),
           array_agg(addr_state),
           array_agg(addr_postalcode),
           array_agg(addr_country)
      INTO _linenums,
           _qtys,
           _taxtypeids,
           _amounts,
           _lineline1,
           _lineline2,
           _lineline3,
           _linecity,
           _linestate,
           _linezip,
           _linecountry
      FROM quitem
      JOIN itemsite ON quitem_itemsite_id = itemsite_id
      JOIN whsinfo ON itemsite_warehous_id = warehous_id
      LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
     WHERE quitem_quhead_id = pOrderId
     GROUP BY quitem_linenumber, quitem_subnumber
     ORDER BY quitem_linenumber, quitem_subnumber;
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

    SELECT array_agg(addr_line1), array_agg(addr_line2), array_agg(addr_line3),
           array_agg(addr_city), array_agg(addr_state), array_agg(addr_postalcode),
           array_agg(addr_country),
           array_agg(freight)
      INTO _freightline1, _freightline2, _freightline3,
           _freightcity, _freightstate, _freightzip,
           _freightcountry,
           _freightsplit
      FROM
      (
       SELECT addr_line1, addr_line2, addr_line3,
              addr_city, addr_state, addr_postalcode, addr_country,
              SUM((freight).freightdata_total) AS freight
         FROM
         (
          SELECT itemsite_warehous_id,
                 calculateFreightDetail(cust_id, custtype_id, custtype_code,
                                        COALESCE(shipto_id, -1), shipto_shipzone_id,
                                        COALESCE(shipto_num, ''), cohead_orderdate, cohead_shipvia,
                                        cohead_curr_id, currConcat(cohead_curr_id),
                                        itemsite_warehous_id, item_freightclass_id,
                                        SUM(coitem_qtyord * coitem_qty_invuomratio *
                                            (item_prodweight +
                                             CASE WHEN fetchMetricBool('IncludePackageWeight')
                                                  THEN item_packweight
                                                  ELSE 0
                                              END
                                            )
                                           )
                                       ) AS freight
            FROM cohead
            JOIN custinfo ON cohead_cust_id = cust_id
            JOIN custtype ON cust_custtype_id = custtype_id
            JOIN shiptoinfo ON cohead_shipto_id = shipto_id
            JOIN coitem ON cohead_id = coitem_cohead_id
            JOIN itemsite ON coitem_itemsite_id = itemsite_id
            JOIN item ON itemsite_item_id = item_id
           WHERE cohead_id = pOrderId
           GROUP BY itemsite_warehous_id, cust_id, custtype_id, custtype_code, shipto_id,
                    shipto_shipzone_id, shipto_num, cohead_orderdate, cohead_shipvia,
                    cohead_curr_id, item_freightclass_id
         ) freights
         JOIN whsinfo ON itemsite_warehous_id = warehous_id
         LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
        GROUP BY addr_line1, addr_line2, addr_line3,
                 addr_city, addr_state, addr_postalcode, addr_country
      ) data;

    SELECT array_agg(formatSoLineNumber(coitem_id)),
           array_agg(ROUND(coitem_qtyord * coitem_qty_invuomratio, 6)),
           array_agg(coitem_taxtype_id),
           array_agg(ROUND(coitem_qtyord * coitem_qty_invuomratio *
                     coitem_price / coitem_price_invuomratio, _precision)),
           array_agg(addr_line1),
           array_agg(addr_line2),
           array_agg(addr_line3),
           array_agg(addr_city),
           array_agg(addr_state),
           array_agg(addr_postalcode),
           array_agg(addr_country)
      INTO _linenums,
           _qtys,
           _taxtypeids,
           _amounts,
           _lineline1,
           _lineline2,
           _lineline3,
           _linecity,
           _linestate,
           _linezip,
           _linecountry
      FROM coitem
      JOIN itemsite ON coitem_itemsite_id = itemsite_id
      JOIN whsinfo ON itemsite_warehous_id = warehous_id
      LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
     WHERE coitem_cohead_id = pOrderId
     GROUP BY coitem_linenumber, coitem_subnumber
     ORDER BY coitem_linenumber, coitem_subnumber;
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

    SELECT array_agg(addr_line1), array_agg(addr_line2), array_agg(addr_line3),
           array_agg(addr_city), array_agg(addr_state), array_agg(addr_postalcode),
           array_agg(addr_country),
           array_agg(freight)
      INTO _freightline1, _freightline2, _freightline3,
           _freightcity, _freightstate, _freightzip,
           _freightcountry,
           _freightsplit
      FROM
      (
       SELECT addr_line1, addr_line2, addr_line3,
              addr_city, addr_state, addr_postalcode, addr_country,
              SUM((freight).freightdata_total) AS freight
         FROM
         (
          SELECT itemsite_warehous_id,
                 calculateFreightDetail(cust_id, custtype_id, custtype_code,
                                        COALESCE(shipto_id, -1), shipto_shipzone_id,
                                        COALESCE(shipto_num, ''), cohead_orderdate,
                                        cobmisc_shipvia, cobmisc_curr_id,
                                        currConcat(cobmisc_curr_id), itemsite_warehous_id,
                                        item_freightclass_id,
                                        SUM(cobill_qty * coitem_qty_invuomratio *
                                            (item_prodweight +
                                             CASE WHEN fetchMetricBool('IncludePackageWeight')
                                                  THEN item_packweight
                                                  ELSE 0
                                              END
                                            )
                                           )
                                       ) AS freight
            FROM cobmisc
            JOIN cohead ON cobmisc_cohead_id = cohead_id
            JOIN custinfo ON cohead_cust_id = cust_id
            JOIN custtype ON cust_custtype_id = custtype_id
            JOIN shiptoinfo ON cohead_shipto_id = shipto_id
            JOIN cobill ON cobmisc_id = cobill_cobmisc_id
            JOIN coitem ON cobill_coitem_id = coitem_id
            JOIN itemsite ON coitem_itemsite_id = itemsite_id
            JOIN item ON itemsite_item_id = item_id
           WHERE cobmisc_id = pOrderId
           GROUP BY itemsite_warehous_id, cust_id, custtype_id, custtype_code, shipto_id,
                    shipto_shipzone_id, shipto_num, cohead_orderdate, cobmisc_shipvia,
                    cobmisc_curr_id, item_freightclass_id
         ) freights
         JOIN whsinfo ON itemsite_warehous_id = warehous_id
         LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
        GROUP BY addr_line1, addr_line2, addr_line3,
                 addr_city, addr_state, addr_postalcode, addr_country
      ) data;

    SELECT array_agg(formatSoLineNumber(coitem_id)),
           array_agg(ROUND(cobill_qty * coitem_qty_invuomratio, 6)),
           array_agg(cobill_taxtype_id),
           array_agg(ROUND(cobill_qty * coitem_qty_invuomratio *
                     coitem_price / coitem_price_invuomratio, _precision)),
           array_agg(addr_line1),
           array_agg(addr_line2),
           array_agg(addr_line3),
           array_agg(addr_city),
           array_agg(addr_state),
           array_agg(addr_postalcode),
           array_agg(addr_country)
      INTO _linenums,
           _qtys,
           _taxtypeids,
           _amounts,
           _lineline1,
           _lineline2,
           _lineline3,
           _linecity,
           _linestate,
           _linezip,
           _linecountry
      FROM cobill
      JOIN coitem ON cobill_coitem_id = coitem_id
      JOIN itemsite ON coitem_itemsite_id = itemsite_id
      JOIN whsinfo ON itemsite_warehous_id = warehous_id
      LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
     WHERE cobill_cobmisc_id = pOrderId
     GROUP BY coitem_linenumber, coitem_subnumber
     ORDER BY coitem_linenumber, coitem_subnumber;
  ELSIF pOrderType = 'INV' THEN
    SELECT invchead_invcnumber, invchead_taxzone_id, addr_line1, addr_line2, addr_line3, addr_city,
           addr_state, addr_postalcode, addr_country, invchead_shipto_address1,
           invchead_shipto_address2, invchead_shipto_address3, invchead_shipto_city,
           invchead_shipto_state, invchead_shipto_zipcode, invchead_shipto_country,
           invchead_cust_id, invchead_curr_id, invchead_invcdate, invchead_freight,
           invchead_misc_amount, invchead_freight_taxtype_id, invchead_misc_taxtype_id,
           invchead_misc_discount
      INTO _number, _taxzoneid, _fromline1, _fromline2, _fromline3, _fromcity,
           _fromstate, _fromzip, _fromcountry, _toline1,
           _toline2, _toline3, _tocity,
           _tostate, _tozip, _tocountry,
           _custid, _currid, _docdate, _freight,
           _misc, _freighttaxtype, _misctaxtype,
           _miscdiscount
      FROM invchead
      JOIN cohead ON invchead_ordernumber = cohead_number
      JOIN whsinfo ON cohead_warehous_id = warehous_id
      LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
     WHERE invchead_id = pOrderId;

    SELECT array_agg(addr_line1), array_agg(addr_line2), array_agg(addr_line3),
           array_agg(addr_city), array_agg(addr_state), array_agg(addr_postalcode),
           array_agg(addr_country),
           array_agg(freight)
      INTO _freightline1, _freightline2, _freightline3,
           _freightcity, _freightstate, _freightzip,
           _freightcountry,
           _freightsplit
      FROM
      (
       SELECT addr_line1, addr_line2, addr_line3,
              addr_city, addr_state, addr_postalcode, addr_country,
              SUM((freight).freightdata_total) AS freight
         FROM
         (
          SELECT invcitem_warehous_id,
                 calculateFreightDetail(cust_id, custtype_id, custtype_code,
                                        COALESCE(shipto_id, -1), shipto_shipzone_id,
                                        COALESCE(shipto_num, ''), invchead_invcdate,
                                        invchead_shipvia, invchead_curr_id,
                                        currConcat(invchead_curr_id), invcitem_warehous_id,
                                        item_freightclass_id,
                                        SUM(invcitem_billed * invcitem_qty_invuomratio *
                                            (item_prodweight +
                                             CASE WHEN fetchMetricBool('IncludePackageWeight')
                                                  THEN item_packweight
                                                  ELSE 0
                                              END
                                            )
                                           )
                                       ) AS freight
            FROM invchead
            JOIN custinfo ON invchead_cust_id = cust_id
            JOIN custtype ON cust_custtype_id = custtype_id
            JOIN shiptoinfo ON invchead_shipto_id = shipto_id
            JOIN invcitem ON invchead_id = invcitem_invchead_id
            JOIN item ON invcitem_item_id = item_id
           WHERE invchead_id = pOrderId
           GROUP BY warehous_id, cust_id, custtype_id, custtype_code, shipto_id, shipto_shipzone_id,
                    shipto_num, invchead_invcdate, invchead_shipvia, invchead_curr_id,
                    item_freightclass_id
         ) freights
         JOIN whsinfo ON invcitem_warehous_id = warehous_id
         LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
        GROUP BY addr_line1, addr_line2, addr_line3,
                 addr_city, addr_state, addr_postalcode, addr_country
      ) data;

    SELECT array_agg(formatInvcLineNumber(invcitem_id)),
           array_agg(ROUND(invcitem_billed * invcitem_qty_invuomratio, 6)),
           array_agg(invcitem_taxtype_id),
           array_agg(ROUND(invcitem_billed * invcitem_qty_invuomratio *
                     invcitem_price / invcitem_price_invuomratio, _precision)),
           array_agg(addr_line1),
           array_agg(addr_line2),
           array_agg(addr_line3),
           array_agg(addr_city),
           array_agg(addr_state),
           array_agg(addr_postalcode),
           array_agg(addr_country)
      INTO _linenums,
           _qtys,
           _taxtypeids,
           _amounts,
           _lineline1,
           _lineline2,
           _lineline3,
           _linecity,
           _linestate,
           _linezip,
           _linecountry
      FROM invcitem
      JOIN itemsite ON invcitem_itemsite_id = itemsite_id
      JOIN whsinfo ON itemsite_warehous_id = warehous_id
      LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
     WHERE invcitem_invchead_id = pOrderId
     GROUP BY invcitem_linenumber, invcitem_subnumber
     ORDER BY invcitem_linenumber, invcitem_subnumber;

    IF EXISTS(SELECT 1
                FROM taxhist
               WHERE taxhist_doctype = 'INV'
                 AND taxhist_parent_id = pOrderId
                 AND taxhist_line_type = 'A') THEN
      _override := getOrderTax('INV', pOrderId);
    END IF;
  END IF;

  RETURN calculateTax(pOrderType, _number, _taxzoneid, _fromline1, _fromline2, _fromline3,
                      _fromcity, _fromstate, _fromzip, _fromcountry, _toline1, _toline2, _toline3,
                      _tocity, _tostate, _tozip, _tocountry, _custid, _currid, _docdate, _freight,
                      _misc, _freighttaxtype, _misctaxtype, _miscdiscount, _freightline1,
                      _freightline2, _freightline3, _freightcity, _freightstate, _freightzip,
                      _freightcountry, _freightsplit, _linenums, _qtys, _taxtypeids, _amounts,
                      _lineline1, _lineline2, _lineline3, _linecity, _linestate, _linezip,
                      _linecountry, _override, pRecord);

END
$$ language plpgsql;
