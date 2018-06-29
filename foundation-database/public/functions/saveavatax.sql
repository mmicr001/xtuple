CREATE OR REPLACE FUNCTION saveAvaTax(pOrderType TEXT, pOrderId INTEGER, pResult JSONB) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _tablename TEXT;
  _subtablename TEXT;
  _lineidqry TEXT;
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
    _tablename := 'quhead';
    _subtablename := 'quitem';
    _lineidqry := 'SELECT quitem_id, quitem_taxtype_id
                     FROM quitem
                    WHERE quitem_quhead_id = %L
                      AND formatSoLineNumber(quitem_id, ''QI'') = %L';
    _subtype := 'QI';
  ELSIF pOrderType = 'S' THEN
    _tablename := 'cohead';
    _subtablename := 'coitem';
    _lineidqry := 'SELECT coitem_id, coitem_taxtype_id
                     FROM coitem
                    WHERE coitem_cohead_id = %L
                      AND formatSoLineNumber(coitem_id) = %L';
    _subtype := 'SI';
  ELSIF pOrderType = 'COB' THEN
    _tablename := 'cobmisc';
    _subtablename := 'cobill';
    _lineidqry := 'SELECT cobill_id, cobill_taxtype_id
                     FROM cobill
                     JOIN coitem ON cobill_coitem_id = coitem_id
                    WHERE cobill_cobmisc_id = %L
                      AND formatSoLineNumber(coitem_id) = %L';
    _subtype := 'COBI';
  ELSIF pOrderType = 'INV' THEN
    _tablename := 'invchead';
    _subtablename := 'invcitem';
    _lineidqry := 'SELECT invcitem_id, invcitem_taxtype_id
                     FROM invcitem
                    WHERE invcitem_invchead_id = %L
                      AND formatInvcLineNumber(invcitem_id) = %L';
    _subtype := 'INVI';
  END IF;

  SELECT curr_id
    INTO _currid
    FROM curr_symbol
   WHERE curr_abbr = pResult->>'currencyCode';

  EXECUTE format('SELECT %I, %I                     
                    FROM %I
                   WHERE %I = %L', format('%s_freight_taxtype_id', _tablename), 
                 format('%s_misc_taxtype_id', _tablename), _tablename, 
                 format('%s_id', _tablename), pOrderId) INTO _freighttaxtypeid, _misctaxtypeid;

  EXECUTE format('DELETE FROM %I
                   WHERE taxhist_parent_id = %L
                     AND taxhist_line_type != %L',
                 format('%stax', _tablename), pOrderId, 'A');

  EXECUTE format('DELETE FROM %I
                   WHERE taxhist_parent_id IN (SELECT %I
                                                 FROM %I
                                                WHERE %I = %L)',
                 format('%stax', _subtablename), format('%s_id', _subtablename), _subtablename,
                 format('%s_%s_id', _subtablename, _tablename), pOrderId);

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
      EXECUTE format(_lineidqry, pOrderId, _r.value->>'lineNumber') INTO _lineid, _taxtypeid;

      EXECUTE format(_qry, format('%stax', _subtablename), _lineid, _taxtypeid,
                     (_r.value->>'taxableAmount')::NUMERIC, _subtype, 'L', _r.value->'details');
    ELSIF _r.value->>'lineNumber' = 'Freight' THEN
      EXECUTE format(_qry, format('%stax', _tablename), pOrderId,
                     _freighttaxtypeid,
                     (_r.value->>'taxableAmount')::NUMERIC, pOrderType, 'F', _r.value->'details');
    ELSIF _r.value->>'lineNumber' = 'Misc' THEN
      EXECUTE format(_qry, format('%stax', _tablename), pOrderId,
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

  RETURN (pResult->>'totalTax')::NUMERIC + _adjustment;

END
$$ language plpgsql;
