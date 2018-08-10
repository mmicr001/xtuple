CREATE OR REPLACE FUNCTION calculateTaxIncluded(pTaxZoneId INTEGER,
                                                pCurrId INTEGER,
                                                pDocDate DATE,
                                                pFreight NUMERIC,
                                                pMisc NUMERIC,
                                                pFreightTaxtypeId INTEGER,
                                                pMiscTaxtypeId INTEGER,
                                                pMiscDiscount BOOLEAN,
                                                pLines TEXT[],
                                                pTaxTypes INTEGER[],
                                                pAmounts NUMERIC[]) RETURNS JSONB AS
$$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _taxdata JSONB;
  _total NUMERIC;
  _line RECORD;
  _tax RECORD;
  _percent NUMERIC;
  _amount NUMERIC;
  _effectivePercent NUMERIC;
  _effectiveAmount NUMERIC;
  _match INTEGER;
  _lineRatio NUMERIC;
  _lineRatios NUMERIC[] := ARRAY[]::NUMERIC[];
  _lineNums TEXT[] := ARRAY[]::TEXT[];
  _totalPercent NUMERIC := 0;
  _totalAmount NUMERIC := 0;
  _pretax NUMERIC;
  _lineAmounts NUMERIC[] := ARRAY[]::NUMERIC[];
  _freightAmount NUMERIC;
  _miscAmount NUMERIC;

BEGIN

  _taxdata := calculateTax(pTaxZoneId, pCurrId, pDocDate, pFreight, pMisc, pFreightTaxtypeId,
                           pMiscTaxtypeId, pMiscDiscount, pLines, pTaxTypes, pAmounts);

  SELECT SUM(amount) + pFreight + CASE WHEN pMiscDiscount AND pMisc < 0 THEN 0 ELSE pMisc END
    INTO _total
    FROM UNNEST(pAmounts) AS amount;

  FOR _line IN
  SELECT value->>'line' AS line, value->'tax' AS taxdetail
    FROM jsonb_array_elements(_taxdata->'lines')
  UNION
  SELECT 'Freight', _taxdata->'freight'->'tax'
  UNION
  SELECT 'Misc', _taxdata->'misc'->'tax'
  LOOP
    _percent := 0;
    _amount := 0;
    _effectivePercent := 0;
    _effectiveAmount := 0;

    FOR _tax IN
    WITH RECURSIVE _taxes AS
    (
     WITH taxes AS
     (
      SELECT value
        FROM jsonb_array_elements(_line.taxdetail)
     )
     SELECT (value->>'taxid')::INTEGER AS taxid, (value->>'sequence')::INTEGER AS sequence,
            (value->>'percent')::NUMERIC AS percent, (value->>'amount')::NUMERIC AS amount
       FROM taxes
      WHERE (value->>'basistaxid')::INTEGER = -1
     UNION
     SELECT (child.value->>'taxid')::INTEGER AS taxid, _taxes.sequence AS sequence,
            _taxes.percent * (child.value->>'percent')::NUMERIC AS percent,
            _taxes.amount * (child.value->>'percent')::NUMERIC +
            (child.value->>'amount')::NUMERIC AS amount
       FROM _taxes
       JOIN taxes child ON _taxes.taxid = (child.value->>'basistaxid')::INTEGER
    )
    SELECT sequence, SUM(percent) AS percent, SUM(amount) AS amount
      FROM _taxes
     GROUP BY sequence
     ORDER BY sequence
    LOOP
      _percent := (1 + _percent) * _tax.percent;
      _amount := _tax.percent * _amount + _tax.amount;
      _effectivePercent := _effectivePercent + _percent;
      _effectiveAmount := _effectiveAmount + _amount;
    END LOOP;

    FOR _match IN 1..COALESCE(array_length(pLines, 1), 0)
    LOOP
      IF pLines[_match] = _line.line THEN
        _lineRatio := pAmounts[_match] / _total;
        EXIT;
      END IF;
    END LOOP;

    IF _line.line = 'Freight' THEN
      _lineRatio := pFreight / _total;
    END IF;

    IF _line.line = 'Misc' THEN
      _lineRatio := pMisc / _total;
    END IF;

    _lineRatios := _lineRatios || _lineRatio;
    _lineNums := _lineNums || _line.line;
    _totalPercent := _totalPercent + _effectivePercent * _lineRatio;
    _totalAmount := _totalAmount + _effectiveAmount;
  END LOOP;

  _pretax := (_total - CASE WHEN pMiscDiscount AND pMisc < 0 THEN pMisc ELSE 0 END - _totalAmount) /
             (1 + _totalPercent);

  _miscAmount := pMisc;

  FOR _line IN 1..COALESCE(array_length(pLines, 1), 0)
  LOOP
    FOR _match IN 1..COALESCE(array_length(_lineNums, 1), 0)
    LOOP
      IF _lineNums[_match] = pLines[_line] THEN
        _lineAmounts := _lineAmounts || _lineRatios[_match] * _pretax;
        EXIT;
      END IF;
    END LOOP;
  END LOOP;

  FOR _match IN 1..COALESCE(array_length(_lineNums, 1), 0)
  LOOP
    IF _lineNums[_match] = 'Freight' THEN
      _freightAmount := _lineRatios[_match] * _pretax;
      EXIT;
    END IF;
  END LOOP;

  FOR _match IN 1..COALESCE(array_length(_lineNums, 1), 0)
  LOOP
    IF _lineNums[_match] = 'Misc' THEN
      _miscAmount := _lineRatios[_match] * _pretax;
      EXIT;
    END IF;
  END LOOP;

  IF pMiscDiscount AND pMisc < 0 THEN
    _lineAmounts := distributeDiscount(_lineAmounts, pMisc, _precision);
  END IF;

  RETURN calculateTax(pTaxZoneId, pCurrId, pDocDate, _freightAmount, _miscAmount, pFreightTaxtypeId,
                      pMiscTaxtypeId, pMiscDiscount, pLines, pTaxTypes, _lineAmounts);

END
$$ language plpgsql;
