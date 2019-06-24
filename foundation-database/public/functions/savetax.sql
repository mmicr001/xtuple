CREATE OR REPLACE FUNCTION saveTax(pOrderType TEXT, pOrderId INTEGER, pResult JSONB) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _taxheadid INTEGER;
  _taxlineid INTEGER;
  _dochead RECORD;
  _r RECORD;
  _adjustment NUMERIC;
  _taxcharged NUMERIC;
  _taxtotal NUMERIC;

BEGIN

  IF pResult IS NULL THEN
    RETURN 0.0;
  END IF;

  IF (fetchMetricText('TaxService') = 'A') THEN
    RETURN saveAvaTax(pOrderType, pOrderId, pResult);
  END IF;

  DELETE FROM taxhead
   WHERE taxhead_doc_type = pOrderType
     AND taxhead_doc_id = pOrderId
     AND taxhead_service = 'A';

  SELECT taxhead_id
    INTO _taxheadid
    FROM taxhead
   WHERE taxhead_doc_type = pOrderType
     AND taxhead_doc_id = pOrderId;

  IF NOT FOUND THEN
    INSERT INTO taxhead (taxhead_doc_type, taxhead_doc_id, taxhead_cust_id, taxhead_date,
                         taxhead_orig_doc_type, taxhead_orig_doc_id, taxhead_orig_date,
                         taxhead_curr_id, taxhead_curr_rate,
                         taxhead_taxzone_id, taxhead_discount)
    SELECT pOrderType, pOrderId, dochead_cust_id, (pResult->>'date')::DATE,
           dochead_origtype, dochead_origid, dochead_origdate,
           (pResult->>'currid')::INTEGER, (pResult->>'currrate')::NUMERIC,
           (pResult->>'taxzoneid')::INTEGER, (pResult->>'discount')::NUMERIC
      FROM dochead
     WHERE dochead_type = pOrderType
       AND dochead_id = pOrderId
    RETURNING taxhead_id INTO _taxheadid;
  ELSE
    SELECT dochead_cust_id, dochead_origtype, dochead_origid, dochead_origdate INTO _dochead
      FROM taxhead
      JOIN dochead ON taxhead_doc_type = dochead_type
                  AND taxhead_doc_id = dochead_id
     WHERE taxhead_id = _taxheadid;

    UPDATE taxhead
       SET taxhead_cust_id = _dochead.dochead_cust_id,
           taxhead_date = (pResult->>'date')::DATE,
           taxhead_orig_doc_type = _dochead.dochead_origtype,
           taxhead_orig_doc_id = _dochead.dochead_origid,
           taxhead_orig_date = _dochead.dochead_origdate,
           taxhead_curr_id = (pResult->>'currid')::INTEGER,
           taxhead_curr_rate = (pResult->>'currrate')::NUMERIC,
           taxhead_taxzone_id = (pResult->>'taxzoneid')::INTEGER,
           taxhead_discount = (pResult->>'discount')::NUMERIC
     WHERE taxhead_id = _taxheadid;
  END IF;

  DELETE FROM taxline
   WHERE taxline_taxhead_id = _taxheadid
     AND taxline_line_type != 'A';

  FOR _r IN
  SELECT value
    FROM jsonb_array_elements(pResult->'lines')
  LOOP
    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_line_id,
                         taxline_linenumber, taxline_subnumber, taxline_number, taxline_item_number,
                         taxline_taxtype_id,
                         taxline_qty, taxline_amount, taxline_extended)
    SELECT _taxheadid, 'L', docitem_id,
           docitem_linenumber, docitem_subnumber, docitem_number, docitem_item_number,
           NULLIF((_r.value->>'taxtypeid')::INTEGER, -1),
           docitem_qty, docitem_unitprice, docitem_price
      FROM docitem
     WHERE docitem_type = pOrderType
       AND docitem_dochead_id = pOrderId
       AND docitem_number = _r.value->>'line'
    RETURNING taxline_id INTO _taxlineid;

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                           taxdetail_taxclass_id, taxdetail_sequence,
                           taxdetail_basis_tax_id, taxdetail_amount,
                           taxdetail_percent, taxdetail_tax, taxdetail_vat)
    SELECT _taxlineid, (_r.value->>'taxable')::NUMERIC, (value->>'taxid')::INTEGER,
           NULLIF((value->>'taxclassid')::INTEGER, -1), (value->>'sequence')::INTEGER,
           NULLIF((value->>'basistaxid')::INTEGER, -1), (value->>'amount')::NUMERIC,
           (value->>'percent')::NUMERIC, (value->>'tax')::NUMERIC, tax_vat
      FROM jsonb_array_elements(_r.value->'tax')
      JOIN tax ON (value->>'taxid')::INTEGER = tax_id;
  END LOOP;

  IF pResult->'freight' IS NOT NULL THEN
    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_taxtype_id,
                         taxline_extended)
    VALUES(_taxheadid, 'F', NULLIF((pResult->'freight'->>'taxtypeid')::INTEGER, -1),
           COALESCE((pResult->'freight'->>'taxable')::NUMERIC, 0.0))
    RETURNING taxline_id INTO _taxlineid;
  END IF;

  IF jsonb_array_length(pResult->'freight'->'tax') != 0 THEN
    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                           taxdetail_taxclass_id, taxdetail_sequence,
                           taxdetail_basis_tax_id, taxdetail_amount,
                           taxdetail_percent, taxdetail_tax, taxdetail_vat)
    SELECT _taxlineid, (pResult->'freight'->>'taxable')::NUMERIC, (value->>'taxid')::INTEGER,
           NULLIF((value->>'taxclassid')::INTEGER, -1), (value->>'sequence')::INTEGER,
           NULLIF((value->>'basistaxid')::INTEGER, -1), (value->>'amount')::NUMERIC,
           (value->>'percent')::NUMERIC, (value->>'tax')::NUMERIC, tax_vat
      FROM jsonb_array_elements(pResult->'freight'->'tax')
      JOIN tax ON (value->>'taxid')::INTEGER = tax_id;
  END IF;

  IF pResult->'misc' IS NOT NULL THEN
    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_taxtype_id,
                         taxline_extended)
    VALUES(_taxheadid, 'M', NULLIF((pResult->'misc'->>'taxtypeid')::INTEGER, -1),
           COALESCE((pResult->'misc'->>'taxable')::NUMERIC, 0.0))
    RETURNING taxline_id INTO _taxlineid;
  END IF;

  IF jsonb_array_length(pResult->'misc'->'tax') != 0 THEN
    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                           taxdetail_taxclass_id, taxdetail_sequence,
                           taxdetail_basis_tax_id, taxdetail_amount,
                           taxdetail_percent, taxdetail_tax, taxdetail_vat)
    SELECT _taxlineid, (pResult->'freight'->>'taxable')::NUMERIC, (value->>'taxid')::INTEGER,
           NULLIF((value->>'taxclassid')::INTEGER, -1), (value->>'sequence')::INTEGER,
           NULLIF((value->>'basistaxid')::INTEGER, -1), (value->>'amount')::NUMERIC,
           (value->>'percent')::NUMERIC, (value->>'tax')::NUMERIC, tax_vat
      FROM jsonb_array_elements(pResult->'misc'->'tax')
      JOIN tax ON (value->>'taxid')::INTEGER = tax_id;
  END IF;

  IF pOrderType = 'VCH' THEN
    _taxtotal := getOrderTax('VCH', pOrderId);

    SELECT COALESCE(vohead_tax_charged, CASE WHEN fetchMetricBool('AssumeCorrectTax')
                                             THEN _taxtotal
                                             ELSE 0.0
                                         END) INTO _taxcharged
      FROM vohead
     WHERE vohead_id = pOrderId;

    UPDATE taxhead
       SET taxhead_tax_paid = _taxcharged
     WHERE taxhead_id = _taxheadid;

    UPDATE taxdetail
       SET taxdetail_tax_owed = taxdetail_tax * GREATEST(_taxtotal - _taxcharged, 0.0) / _taxtotal
      FROM taxhead
      JOIN taxline ON taxhead_id = taxline_taxhead_id
     WHERE taxline_id = taxdetail_taxline_id
       AND taxhead_id = _taxheadid;
  END IF;

  SELECT COALESCE(SUM(taxdetail_tax), 0.0)
    INTO _adjustment
    FROM taxhead
    JOIN taxline ON taxhead_id = taxline_taxhead_id
    JOIN taxdetail ON taxline_id = taxdetail_taxline_id
   WHERE taxhead_id = _taxheadid
     AND taxline_line_type = 'A';

  RETURN (pResult->>'total')::NUMERIC + _adjustment;

END
$$ language plpgsql;
