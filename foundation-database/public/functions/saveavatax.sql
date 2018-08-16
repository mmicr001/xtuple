CREATE OR REPLACE FUNCTION saveAvaTax(pOrderType TEXT, pOrderId INTEGER, pResult JSONB) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _tablename TEXT;
  _subtablename TEXT;
  _subtype TEXT;
  _return BOOLEAN;
  _currid INTEGER;
  _qry TEXT;
  _r RECORD;
  _lineid INTEGER;
  _taxtypeid INTEGER;
  _freighttaxtypeid INTEGER;
  _misctaxtypeid INTEGER;

BEGIN

  IF pOrderType = 'Q' THEN
    _tablename := 'quheadtax';
    _subtablename := 'quitemtax';
    _subtype := 'QI';
  ELSIF pOrderType = 'S' THEN
    _tablename := 'coheadtax';
    _subtablename := 'coitemtax';
    _subtype := 'SI';
  ELSIF pOrderType = 'COB' THEN
    _tablename := 'cobmisctax';
    _subtablename := 'cobilltax';
    _subtype := 'COBI';
  ELSIF pOrderType = 'INV' THEN
    _tablename := 'invcheadtax';
    _subtablename := 'invcitemtax';
    _subtype := 'INVI';
  ELSIF pOrderType = 'P' THEN
    _tablename := 'poheadtax';
    _subtablename := 'poitemtax';
    _subtype := 'PI';
  ELSIF pOrderType = 'VCH' THEN
    _tablename := 'voheadtax';
    _subtablename := 'voitemtax';
    _subtype := 'VCHI';
  ELSIF pOrderType = 'RA' THEN -- Temporary reference to commercial table
    _tablename := 'raheadtax';
    _subtablename := 'raitemtax';
    _subtype := 'RI';
  ELSIF pOrderType = 'CM' THEN
    _tablename := 'cmheadtax';
    _subtablename := 'cmitemtax';
    _subtype := 'CMI';
  END IF;

  _return := pOrderType NOT IN ('Q', 'S', 'COB', 'INV', 'P', 'VCH');

  SELECT curr_id
    INTO _currid
    FROM curr_symbol
   WHERE curr_abbr = pResult->>'currencyCode';

  SELECT dochead_freight_taxtype_id, dochead_misc_taxtype_id
    INTO _freighttaxtypeid, _misctaxtypeid
    FROM dochead
   WHERE dochead_id = pOrderId;

  EXECUTE format('DELETE FROM %I
                   WHERE taxhist_parent_id = %L
                     AND taxhist_line_type != ''A''',
                 _tablename, pOrderId);

  EXECUTE format('DELETE FROM %I
                   WHERE taxhist_parent_id IN (SELECT docitem_id
                                                 FROM docitem
                                                WHERE docitem_type = %L
                                                  AND docitem_dochead_id = %L)',
                 _subtablename, pOrderType, pOrderId);

  _qry := format($_$INSERT INTO %%I
                   (taxhist_parent_id, taxhist_taxtype_id, taxhist_tax_code, taxhist_basis, 
                    taxhist_basis_tax_id,
                    taxhist_sequence,
                    taxhist_percent, taxhist_amount, 
                    taxhist_tax, taxhist_tax_owed,
                    taxhist_docdate, taxhist_curr_id,
                    taxhist_curr_rate, taxhist_doctype, taxhist_line_type, taxhist_freightgroup)
                   SELECT %%L, %%L, (value->>'taxName'), (value->>'taxableAmount')::NUMERIC * %L,
                          NULL,
                          0,
                          (value->>'rate')::NUMERIC, 0,
                          (value->>'taxCalculated')::NUMERIC * %L, (value->>'tax')::NUMERIC * %L,
                          %L, %L,
                          %L, %%L, %%L, %%L
                     FROM jsonb_array_elements(%%L)
                    WHERE (value->>'tax')::NUMERIC != 0.0$_$,
                  CASE WHEN _return THEN -1 ELSE 1 END,
                  CASE WHEN _return THEN -1 ELSE 1 END,
                  CASE WHEN _return THEN -1 ELSE 1 END,
                  (pResult->>'date')::DATE, _currid,
                  (pResult->>'exchangeRate')::NUMERIC);

  FOR _r IN
  SELECT value
    FROM jsonb_array_elements(pResult->'lines')
  LOOP
    IF NOT _r.value->>'lineNumber' ~ 'Freight' AND NOT _r.value->>'lineNumber' = 'Misc' THEN
      SELECT docitem_id, docitem_taxtype_id
        INTO _lineid, _taxtypeid
        FROM docitem
       WHERE docitem_type = pOrderType
         AND docitem_dochead_id = pOrderId
         AND docitem_number = _r.value->>'lineNumber';

      EXECUTE format(_qry, _subtablename, _lineid, _taxtypeid,
                     _subtype, 'L', NULL,
                      _r.value->'details');
    ELSIF _r.value->>'lineNumber' ~ 'Freight' THEN
      EXECUTE format(_qry, _tablename, pOrderId,
                     _freighttaxtypeid,
                     pOrderType, 'F',
                      NULLIF(right(_r.value->>'lineNumber', -7), '')::INTEGER, _r.value->'details');
    ELSIF _r.value->>'lineNumber' = 'Misc' THEN
      EXECUTE format(_qry, _tablename, pOrderId,
                     _misctaxtypeid,
                     pOrderType, 'M', NULL,
                      _r.value->'details');
    END IF;
  END LOOP;

  RETURN (pResult->>'totalTaxCalculated')::NUMERIC * CASE WHEN _return THEN -1 ELSE 1 END;

END
$$ language plpgsql;
