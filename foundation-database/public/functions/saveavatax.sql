CREATE OR REPLACE FUNCTION saveAvaTax(pOrderType TEXT, pOrderId INTEGER, pResult JSONB) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _return NUMERIC;
  _currid INTEGER;
  _taxheadid INTEGER;
  _taxlineid INTEGER;
  _r RECORD;
  _lineid INTEGER;
  _taxtypeid INTEGER;
  _linetype TEXT;
  _freightgroup TEXT;
  _freighttaxtypeid INTEGER;
  _misctaxtypeid INTEGER;

BEGIN

  _return := CASE WHEN pOrderType NOT IN ('Q', 'S', 'COB', 'INV', 'P', 'VCH') THEN -1 ELSE 1 END;

  SELECT curr_id
    INTO _currid
    FROM curr_symbol
   WHERE curr_abbr = pResult->>'currencyCode';

  SELECT dochead_freight_taxtype_id, dochead_misc_taxtype_id
    INTO _freighttaxtypeid, _misctaxtypeid
    FROM dochead
   WHERE dochead_id = pOrderId;

  DELETE FROM taxhead
   WHERE taxhead_doc_type = pOrderType
     AND taxhead_doc_id = pOrderId;

  INSERT INTO taxhead (taxhead_service, taxhead_doc_type, taxhead_doc_id, taxhead_cust_id,
                       taxhead_exemption_code, taxhead_date, taxhead_orig_doc_type,
                       taxhead_orig_doc_id, taxhead_orig_date, taxhead_curr_id, taxhead_curr_rate,
                       taxhead_shiptoaddr_line1, taxhead_shiptoaddr_line2,
                       taxhead_shiptoaddr_line3, taxhead_shiptoaddr_city,
                       taxhead_shiptoaddr_region, taxhead_shiptoaddr_postalcode,
                       taxhead_shiptoaddr_country, taxhead_discount)
  SELECT 'A', pOrderType, pOrderId, dochead_cust_id,
         (pResult->>'entityUseCode')::TEXT, (pResult->>'date')::DATE, dochead_origtype,
         dochead_origid, dochead_origdate, _currid, (pResult->>'exchangeRate')::NUMERIC,
         dochead_toaddr1, dochead_toaddr2,
         dochead_toaddr3, dochead_tocity,
         dochead_tostate, dochead_tozip,
         dochead_tocountry, (pResult->>'totalDiscount')::NUMERIC
    FROM dochead
   WHERE dochead_type = pOrderType
     AND dochead_id = pOrderId
  RETURNING taxhead_id INTO _taxheadid;

  FOR _r IN
  SELECT value
    FROM jsonb_array_elements(pResult->'lines')
  LOOP
    IF NOT _r.value->>'lineNumber' ~ 'Freight' AND NOT _r.value->>'lineNumber' = 'Misc' THEN
      SELECT docitem_id, docitem_taxtype_id, docitem_price
        INTO _lineid, _taxtypeid
        FROM docitem
        JOIN whsinfo ON docitem_warehous_id = warehous_id
        LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
       WHERE docitem_type = pOrderType
         AND docitem_dochead_id = pOrderId
         AND docitem_number = _r.value->>'lineNumber';

      _linetype := 'L';
      _freightgroup := NULL;
    ELSIF _r.value->>'lineNumber' ~ 'Freight' THEN
      _lineid := NULL;
      _taxtypeid := _freighttaxtypeid;
      _linetype := 'F';
      _freightgroup := NULLIF(right(_r.value->>'lineNumber', -7), '');
    ELSIF _r.value->>'lineNumber' = 'Misc' THEN
      _lineid := NULL;
      _taxtypeid := _misctaxtypeid;
      _linetype := 'M';
      _freightgroup := NULL;
    END IF;

    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_line_id,
                         taxline_linenumber, taxline_subnumber,
                         taxline_number, taxline_item_number,
                         taxline_shipfromaddr_line1, taxline_shipfromaddr_line2,
                         taxline_shipfromaddr_line3, taxline_shipfromaddr_city,
                         taxline_shipfromaddr_region, taxline_shipfromaddr_postalcode,
                         taxline_shipfromaddr_country,
                         taxline_taxtype_id, taxline_taxtype_external_code, taxline_qty,
                         taxline_amount, taxline_extended)
    SELECT _taxheadid, _linetype, _lineid,
           COALESCE(docitem_linenumber, 1), COALESCE(docitem_subnumber, 0),
           COALESCE(docitem_number, _freightgroup), COALESCE(docitem_item_number, ''),
           addr_line1, addr_line2,
           addr_line3, addr_city,
           addr_state, addr_postalcode,
           addr_country,
           _taxtypeid, (_r.value->>'taxCode'), docitem_qty,
           docitem_unitprice, (_r.value->>'lineAmount')::NUMERIC
      FROM dochead
      LEFT OUTER JOIN docitem ON docitem_type = pOrderType
                             AND docitem_id = _lineid
      JOIN whsinfo ON COALESCE(docitem_warehous_id, dochead_warehous_id) = warehous_id
      LEFT OUTER JOIN addr ON warehous_addr_id = addr_id
     WHERE dochead_type = pOrderType
       AND dochead_id = pOrderId
    RETURNING taxline_id INTO _taxlineid;

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_code,
                           taxdetail_percent, taxdetail_tax,
                           taxdetail_tax_owed)
    SELECT _taxlineid, (value->>'taxableAmount')::NUMERIC * _return, (value->>'taxName'),
           (value->>'rate')::NUMERIC, (value->>'taxCalculated')::NUMERIC * _return,
           ((value->>'taxCalculated')::NUMERIC - (value->>'tax')::NUMERIC) * _return
      FROM jsonb_array_elements(_r.value->'details');
  END LOOP;

  RETURN (pResult->>'totalTaxCalculated')::NUMERIC * _return;

END
$$ language plpgsql;
