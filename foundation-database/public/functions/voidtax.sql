CREATE OR REPLACE FUNCTION voidTax(pOrderType TEXT, pOrderId INTEGER) RETURNS JSONB AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _service TEXT;

BEGIN

  IF pOrderType = 'VCH' THEN
    IF (SELECT getOrderTax('VCH', vohead_id) - vohead_tax_charged <= 0.0
          FROM vohead
         WHERE vohead_id = pOrderId) THEN
      RETURN NULL;
    END IF;
  END IF;

  _service := fetchMetricText('TaxService');

  IF _service = 'A' THEN
    RETURN '{"code": "DocVoided"}'::JSONB;
  END IF;

  RETURN '{}'::JSONB;

END
$$ language plpgsql;
