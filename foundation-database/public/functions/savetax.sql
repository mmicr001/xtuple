CREATE OR REPLACE FUNCTION saveTax(pOrderType TEXT, pOrderId INTEGER, pResult JSONB) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _tablename TEXT;
  _subtablename TEXT;
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
    EXECUTE format(_qry, _tablename, pOrderId,
                   (pResult->'freight'->>'taxtypeid')::INTEGER,
                   (pResult->'freight'->>'taxable')::NUMERIC, pOrderType, 'F',
                   pResult->'freight'->'tax');
  END IF;

  IF jsonb_array_length(pResult->'misc'->'tax') != 0 THEN
    EXECUTE format(_qry, _tablename, pOrderId,
                   (pResult->'misc'->>'taxtypeid')::INTEGER,
                   (pResult->'misc'->>'taxable')::NUMERIC, pOrderType, 'M',
                   pResult->'misc'->'tax');
  END IF;

  FOR _r IN
  SELECT value
    FROM jsonb_array_elements(pResult->'lines')
  LOOP
    SELECT docitem_id
      INTO _lineid
      FROM docitem
     WHERE docitem_type = pOrderType
       AND docitem_dochead_id = pOrderId
       AND docitem_number = _r.value->>'line';

    EXECUTE format(_qry, _subtablename, _lineid, (_r.value->>'taxtypeid')::INTEGER,
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
