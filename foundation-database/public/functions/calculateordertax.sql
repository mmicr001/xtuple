CREATE OR REPLACE FUNCTION calculateOrderTax(pOrderType TEXT, pOrderId INTEGER, pRecord BOOLEAN DEFAULT TRUE) RETURNS JSONB AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _precision INTEGER := 2;
  _tmp TEXT;
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
  _singlelocation BOOLEAN := FALSE;
  _cust TEXT;
  _usage TEXT;
  _taxreg TEXT;
  _currid INTEGER;
  _docdate DATE;
  _origdate DATE;
  _origorder TEXT;
  _freight NUMERIC;
  _misc NUMERIC;
  _miscdescrip TEXT;
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
  _linecodes TEXT[];
  _lineupc TEXT[];
  _linedescrips TEXT[];
  _qtys NUMERIC[];
  _taxtypeids INTEGER[];
  _amounts NUMERIC[];
  _usages TEXT[];
  _lineline1 TEXT[];
  _lineline2 TEXT[];
  _lineline3 TEXT[];
  _linecity TEXT[];
  _linestate TEXT[];
  _linezip TEXT[];
  _linecountry TEXT[];
  _taxpaid NUMERIC;

BEGIN
 
  SELECT dochead_number, dochead_taxzone_id, addr_line1, addr_line2, addr_line3, addr_city,
         addr_state, addr_postalcode, addr_country, dochead_toaddr1, dochead_toaddr2,
         dochead_toaddr3, dochead_tocity, dochead_tostate, dochead_tozip, dochead_tocountry,
         COALESCE(cust_number, prospect_number, vend_number, fetchMetricText('remitto_name')),
         CASE WHEN dochead_cust_id IS NOT NULL
              THEN COALESCE(dochead_tax_exemption, cust_tax_exemption,
                            fetchMetricText('AvalaraSalesExemptionCode'))
              WHEN dochead_vend_id IS NOT NULL
              THEN COALESCE(dochead_tax_exemption, vend_tax_exemption,
                            fetchMetricText('AvalaraPurchaseExemptionCode'))
              ELSE ''
          END,
         COALESCE(taxreg_number, ' '), dochead_curr_id, dochead_date, dochead_origdate,
         dochead_orignumber, dochead_freight + COALESCE(SUM(docitem_freight), 0.0), dochead_misc,
         dochead_misc_descrip, dochead_freight_taxtype_id, dochead_misc_taxtype_id,
         dochead_misc_discount
    INTO _number, _taxzoneid, _fromline1, _fromline2, _fromline3, _fromcity,
         _fromstate, _fromzip, _fromcountry, _toline1, _toline2,
         _toline3, _tocity, _tostate, _tozip, _tocountry,
         _cust,
         _usage,
         _taxreg, _currid, _docdate, _origdate,
         _origorder, _freight, _misc,
         _miscdescrip, _freighttaxtype, _misctaxtype,
         _miscdiscount
    FROM dochead
    JOIN whsinfo ON dochead_warehous_id = warehous_id
    LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
    LEFT OUTER JOIN custinfo ON dochead_cust_id = cust_id
    LEFT OUTER JOIN prospect ON dochead_cust_id = prospect_id
    LEFT OUTER JOIN vendinfo ON dochead_vend_id = vend_id
    LEFT OUTER JOIN taxreg ON ((taxreg_rel_type = 'C' AND dochead_cust_id = taxreg_rel_id)
                               OR (taxreg_rel_type = 'V' AND dochead_vend_id = taxreg_rel_id))
                          AND CURRENT_DATE BETWEEN taxreg_effective AND taxreg_expires
    LEFT OUTER JOIN docitem ON dochead_type = docitem_type
                           AND dochead_id = docitem_dochead_id
   WHERE dochead_type = pOrderType
     AND dochead_id = pOrderId
   GROUP BY dochead_id, dochead_number, dochead_taxzone_id, dochead_warehous_id, dochead_toaddr1,
            dochead_toaddr2, dochead_toaddr3, dochead_tocity, dochead_tostate, dochead_tozip,
            dochead_tocountry, dochead_cust_id, dochead_vend_id, dochead_tax_exemption,
            dochead_curr_id, dochead_date, dochead_origdate, dochead_orignumber, dochead_freight,
            dochead_misc, dochead_misc_descrip, dochead_freight_taxtype_id, dochead_misc_taxtype_id,
            dochead_misc_discount, addr_line1, addr_line2, addr_line3, addr_city, addr_state,
            addr_postalcode, addr_country, cust_number, cust_tax_exemption, prospect_number,
            vend_number, vend_tax_exemption, taxreg_number;

  IF pOrderType IN ('P', 'VCH') THEN
    _tmp := _fromline1;
    _fromline1 := _toline1;
    _toline1 := _tmp;
    _tmp := _fromline2;
    _fromline2 := _toline2;
    _toline2 := _tmp;
    _tmp := _fromline3;
    _fromline3 := _toline3;
    _toline3 := _tmp;
    _tmp := _fromcity;
    _fromcity := _tocity;
    _tocity := _tmp;
    _tmp := _fromstate;
    _fromstate := _tostate;
    _tostate := _tmp;
    _tmp := _fromzip;
    _fromzip := _tozip;
    _tozip := _tmp;
    _tmp := _fromcountry;
    _fromcountry := _tocountry;
    _tocountry := _tmp;
  END IF;

  IF pOrderType = 'EX' OR
     (pOrderType = 'VCH' AND (SELECT COALESCE(vohead_pohead_id, -1) = -1
                                FROM vohead
                               WHERE vohead_id = pOrderId)) THEN
    _singlelocation := TRUE;
  END IF;

  SELECT COALESCE(array_agg(addr_line1), ARRAY[_toline1]),
         COALESCE(array_agg(addr_line2), ARRAY[_toline2]),
         COALESCE(array_agg(addr_line3), ARRAY[_toline3]),
         COALESCE(array_agg(addr_city), ARRAY[_tocity]),
         COALESCE(array_agg(addr_state), ARRAY[_tostate]),
         COALESCE(array_agg(addr_postalcode), ARRAY[_tozip]),
         COALESCE(array_agg(addr_country), ARRAY[_tocountry]),
         COALESCE(array_agg(freight), ARRAY[_freight])
    INTO _freightline1,
         _freightline2,
         _freightline3,
         _freightcity,
         _freightstate,
         _freightzip,
         _freightcountry,
         _freightsplit
    FROM
    (
     SELECT addr_line1, addr_line2, addr_line3,
            addr_city, addr_state, addr_postalcode, addr_country,
            SUM(freight) AS freight
       FROM
       (
        SELECT docitem_warehous_id,
               CASE WHEN pOrderType NOT IN ('P', 'VCH', 'EX')
                    THEN (SELECT freightdata_total
                            FROM calculateFreightDetail(cust_id, custtype_id, custtype_code,
                                                        COALESCE(shipto_id, -1), shipto_shipzone_id,
                                                        COALESCE(shipto_num, ''), dochead_date,
                                                        dochead_shipvia, dochead_curr_id,
                                                        currConcat(dochead_curr_id),
                                                        docitem_warehous_id, item_freightclass_id,
                                                        SUM(docitem_qty *
                                                            (item_prodweight +
                                                             CASE WHEN fetchMetricBool('IncludePackageWeight')
                                                                  THEN item_packweight
                                                                  ELSE 0
                                                              END
                                                            )
                                                           )
                                                       ))
                    ELSE docitem_freight
                END AS freight
          FROM dochead
          LEFT OUTER JOIN custinfo ON dochead_cust_id = cust_id
          LEFT OUTER JOIN custtype ON cust_custtype_id = custtype_id
          LEFT OUTER JOIN shiptoinfo ON dochead_shipto_id = shipto_id
          JOIN docitem ON dochead_type = docitem_type 
                      AND dochead_id = docitem_dochead_id
          LEFT OUTER JOIN item ON docitem_item_id = item_id
         WHERE dochead_type = pOrderType
           AND dochead_id = pOrderId
         GROUP BY docitem_warehous_id, cust_id, custtype_id, custtype_code, shipto_id,
                  shipto_shipzone_id, shipto_num, dochead_date, dochead_shipvia, dochead_curr_id,
                  item_freightclass_id, docitem_freight
       ) freights
       JOIN whsinfo ON docitem_warehous_id = warehous_id
       LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
      GROUP BY addr_line1, addr_line2, addr_line3,
               addr_city, addr_state, addr_postalcode, addr_country
    ) data;

  SELECT COALESCE(array_agg(docitem_number), ARRAY[]::TEXT[]),
         COALESCE(array_agg(docitem_item_number), ARRAY[]::TEXT[]),
         COALESCE(array_agg(item_upccode), ARRAY[]::TEXT[]),
         COALESCE(array_agg(docitem_item_descrip), ARRAY[]::TEXT[]),
         COALESCE(array_agg(ROUND(docitem_qty, 6)), ARRAY[]::NUMERIC[]),
         COALESCE(array_agg(docitem_taxtype_id), ARRAY[]::INTEGER[]),
         COALESCE(array_agg(ROUND(docitem_price, _precision)), ARRAY[]::NUMERIC[]),
         COALESCE(array_agg(CASE WHEN dochead_cust_id IS NOT NULL
                                 THEN COALESCE(docitem_tax_exemption, dochead_tax_exemption,
                                               cust_tax_exemption,
                                               fetchMetricText('AvalaraSalesExemptionCode'))
                                 ELSE COALESCE(docitem_tax_exemption, dochead_tax_exemption,
                                               vend_tax_exemption,
                                               fetchMetricText('AvalaraPurchaseExemptionCode'))
                             END), ARRAY[]::TEXT[]),
         COALESCE(array_agg(addr_line1), ARRAY[]::TEXT[]),
         COALESCE(array_agg(addr_line2), ARRAY[]::TEXT[]),
         COALESCE(array_agg(addr_line3), ARRAY[]::TEXT[]),
         COALESCE(array_agg(addr_city), ARRAY[]::TEXT[]),
         COALESCE(array_agg(addr_state), ARRAY[]::TEXT[]),
         COALESCE(array_agg(addr_postalcode), ARRAY[]::TEXT[]),
         COALESCE(array_agg(addr_country), ARRAY[]::TEXT[])
    INTO _linenums,
         _linecodes,
         _lineupc,
         _linedescrips,
         _qtys,
         _taxtypeids,
         _amounts,
         _usages,
         _lineline1,
         _lineline2,
         _lineline3,
         _linecity,
         _linestate,
         _linezip,
         _linecountry
    FROM docitem
    JOIN dochead ON docitem_type = dochead_type
                AND docitem_dochead_id = dochead_id
    JOIN whsinfo ON docitem_warehous_id = warehous_id
    LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
    LEFT OUTER JOIN item ON docitem_item_id = item_id
    LEFT OUTER JOIN custinfo ON dochead_cust_id = cust_id
    LEFT OUTER JOIN vendinfo ON dochead_vend_id = vend_id
   WHERE docitem_type = pOrderType
     AND docitem_dochead_id = pOrderId;

  IF COALESCE(array_length(_amounts, 1), 0) = 0 AND
     COALESCE(_freight, 0.0) = 0.0 AND
     (COALESCE(_misc, 0.0) = 0.0 OR _miscdiscount) THEN
    RETURN NULL;
  END IF;

  IF pOrderType = 'VCH' THEN
    SELECT NULLIF(vohead_tax_charged, 0.0) INTO _taxpaid
      FROM vohead
     WHERE vohead_id = pOrderId;
  END IF;

  RETURN calculateTax(pOrderType, _number, _taxzoneid, _fromline1, _fromline2, _fromline3,
                      _fromcity, _fromstate, _fromzip, _fromcountry, _toline1, _toline2, _toline3,
                      _tocity, _tostate, _tozip, _tocountry, _singlelocation, _cust, _usage,
                      _taxreg, _currid, _docdate, _origdate, _origorder, _freight, _misc,
                      _miscdescrip, _freighttaxtype, _misctaxtype, _miscdiscount, _freightline1,
                      _freightline2, _freightline3, _freightcity, _freightstate, _freightzip,
                      _freightcountry, _freightsplit, _linenums, _linecodes, _lineupc,
                      _linedescrips, _qtys, _taxtypeids, _amounts, _usages, _lineline1, _lineline2,
                      _lineline3, _linecity, _linestate, _linezip, _linecountry, _taxpaid, pRecord);

END
$$ language plpgsql;
