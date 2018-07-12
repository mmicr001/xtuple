CREATE OR REPLACE FUNCTION saveAvaTax(pOrderType TEXT, pOrderId INTEGER, pResult JSONB) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _tablename TEXT;
  _subtablename TEXT;
  _subtype TEXT;
  _currid INTEGER;
  _qry TEXT;
  _r RECORD;
  _lineid INTEGER;
  _taxtypeid INTEGER;
  _freighttaxtypeid INTEGER;
  _misctaxtypeid INTEGER;
  _adjustment NUMERIC;

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
  END IF;

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
                    taxhist_tax, taxhist_docdate, taxhist_curr_id,
                    taxhist_curr_rate, taxhist_doctype, taxhist_line_type)
                   SELECT %%L, %%L, (value->>'taxName'), %%L,
                          NULL,
                          0,
                          (value->>'rate')::NUMERIC, 0,
                          (value->>'tax')::NUMERIC, %L, %L,
                          %L, %%L, %%L
                     FROM jsonb_array_elements(%%L)
                    WHERE (value->>'tax')::NUMERIC != 0.0$_$,
                  (pResult->>'date')::DATE, _currid,
                  (pResult->>'exchangeRate')::NUMERIC);

  FOR _r IN
  SELECT value
    FROM jsonb_array_elements(pResult->'lines')
  LOOP
    IF _r.value->>'lineNumber' NOT IN ('Freight', 'Misc') THEN
      SELECT docitem_id, docitem_taxtype_id
        INTO _lineid, _taxtypeid
        FROM docitem
       WHERE docitem_type = pOrderType
         AND docitem_dochead_id = pOrderId
         AND docitem_number = _r.value->>'lineNumber';

      EXECUTE format(_qry, _subtablename, _lineid, _taxtypeid,
                     (_r.value->>'taxableAmount')::NUMERIC, _subtype, 'L', _r.value->'details');
    ELSIF _r.value->>'lineNumber' = 'Freight' THEN
      EXECUTE format(_qry, _tablename, pOrderId,
                     _freighttaxtypeid,
                     (_r.value->>'taxableAmount')::NUMERIC, pOrderType, 'F', _r.value->'details');
    ELSIF _r.value->>'lineNumber' = 'Misc' THEN
      EXECUTE format(_qry, _tablename, pOrderId,
                     _misctaxtypeid,
                     (_r.value->>'taxableAmount')::NUMERIC, pOrderType, 'M', _r.value->'details');
    END IF;
  END LOOP;

  SELECT COALESCE(SUM(taxhist_tax), 0.0)
    INTO _adjustment
    FROM taxhist
   WHERE taxhist_doctype = pOrderType
     AND taxhist_parent_id = pOrderId
     AND taxhist_line_type = 'A';

  RETURN (pResult->>'totalTaxCalculated')::NUMERIC + _adjustment;

END
$$ language plpgsql;
