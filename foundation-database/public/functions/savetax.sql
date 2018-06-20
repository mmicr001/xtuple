CREATE OR REPLACE FUNCTION saveTax(pOrderType TEXT, pOrderId INTEGER, pResult JSONB) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _tablename TEXT;
  _subtablename TEXT;
  _lineidqry TEXT;
  _subtype TEXT;
  _qry TEXT;
  _r RECORD;
  _lineid INTEGER;
  _adjustment NUMERIC;

BEGIN

  IF (fetchMetricText('TaxService') = 'A') THEN
    RETURN saveAvaTax(pOrderType, pOrderId, pResult);
  END IF;

  IF pOrderType = 'Q' THEN
    _tablename := 'quhead';
    _subtablename := 'quitem';
    _lineidqry := 'SELECT quitem_id
                     FROM quitem
                    WHERE quitem_quhead_id = %L
                      AND formatSoLineNumber(quitem_id, ''QI'') = %L';
    _subtype := 'QI';
  ELSIF pOrderType = 'S' THEN
    _tablename := 'cohead';
    _subtablename := 'coitem';
    _lineidqry := 'SELECT coitem_id
                     FROM coitem
                    WHERE coitem_cohead_id = %L
                      AND formatSoLineNumber(coitem_id) = %L';
    _subtype := 'SI';
  ELSIF pOrderType = 'COB' THEN
    _tablename := 'cobmisc';
    _subtablename := 'cobill';
    _lineidqry := 'SELECT cobill_id
                     FROM cobill
                     JOIN coitem ON cobill_coitem_id = coitem_id
                    WHERE cobill_cobmisc_id = %L
                      AND formatSoLineNumber(coitem_id) = %L';
    _subtype := 'COBI';
  ELSIF pOrderType = 'INV' THEN
    _tablename := 'invchead';
    _subtablename := 'invcitem';
    _lineidqry := 'SELECT invcitem_id
                     FROM invcitem
                    WHERE invcitem_invchead_id = %L
                      AND formatInvcLineNumber(invcitem_id) = %L';
    _subtype := 'INVI';
  END IF;

  EXECUTE format('DELETE FROM %I
                   WHERE taxhist_parent_id = %L
                     AND taxhist_line_type = %L',
                 format('%stax', _tablename), pOrderId, 'A');

  EXECUTE format('DELETE FROM %I
                   WHERE taxhist_parent_id IN (SELECT %I
                                                 FROM %I
                                                WHERE %I = %L)',
                 format('%stax', _subtablename), format('%s_id', _subtablename), _subtablename,
                 format('%s_%s_id', _subtablename, _tablename), pOrderId);

  _qry := format($_$INSERT INTO %%I
                   (taxhist_parent_id, taxhist_taxtype_id, taxhist_tax_id, taxhist_basis, 
                    taxhist_basis_tax_id,
                    taxhist_sequence,
                    taxhist_percent, taxhist_amount, 
                    taxhist_tax, taxhist_docdate, taxhist_curr_id,
                    taxhist_curr_rate, taxhist_doctype, taxhist_line_type)
                   SELECT %%L, %%L, (value->>'taxid')::INTEGER, %%L,
                          NULLIF((value->>'basistaxid')::INTEGER, -1),
                          (value->>'sequence')::INTEGER,
                          (value->>'percent')::NUMERIC, (value->>'amount')::NUMERIC,
                          (value->>'tax')::NUMERIC, %L, %L,
                          %L, %%L, %%L
                     FROM jsonb_array_elements(%%L)$_$,
                  (pResult->>'date')::DATE, (pResult->>'currid')::INTEGER,
                  (pResult->>'currrate')::NUMERIC);


  IF jsonb_array_length(pResult->'freight'->'tax') != 0 THEN
    EXECUTE format(_qry, format('%stax', _tablename), pOrderId,
                   (pResult->'freight'->>'taxtypeid')::INTEGER,
                   (pResult->'freight'->>'taxable')::NUMERIC, pOrderType, 'F',
                   pResult->'freight'->'tax');
  END IF;

  IF jsonb_array_length(pResult->'misc'->'tax') != 0 THEN
    EXECUTE format(_qry, format('%stax', _tablename), pOrderId,
                   (pResult->'misc'->>'taxtypeid')::INTEGER,
                   (pResult->'misc'->>'taxable')::NUMERIC, pOrderType, 'M',
                   pResult->'misc'->'tax');
  END IF;

  FOR _r IN
  SELECT value
    FROM jsonb_array_elements(pResult->'lines')
  LOOP
    EXECUTE format(_lineidqry, pOrderId, _r.value->>'line') INTO _lineid;

    EXECUTE format(_qry, format('%stax', _subtablename), _lineid, (_r.value->>'taxtypeid')::INTEGER,
                   (_r.value->>'taxable')::NUMERIC, _subtype, 'L', _r.value->'tax');
  END LOOP;

  SELECT COALESCE(SUM(taxhist_tax), 0.0)
    INTO _adjustment
    FROM taxhist
   WHERE taxhist_doctype = pOrderType
     AND taxhist_parent_id = pOrderId
     AND taxhist_line_type = 'A';

  RETURN (pResult->>'total')::NUMERIC + _adjustment;

END
$$ language plpgsql;
