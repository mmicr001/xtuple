CREATE OR REPLACE FUNCTION voidTax(pOrderType TEXT, pOrderId INTEGER) RETURNS JSONB AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _service TEXT;

BEGIN

  _service := fetchMetricText('TaxService');

  IF _service = 'A' THEN
    RETURN '{"code": "DocVoided"}'::JSONB;
  END IF;

  RETURN ''::JSONB;

END
$$ language plpgsql;
