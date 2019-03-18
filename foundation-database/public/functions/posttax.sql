CREATE OR REPLACE FUNCTION postTax(pOrderType TEXT, pOrderId INTEGER) RETURNS JSONB AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _service TEXT;

BEGIN

  UPDATE taxhead
     SET taxhead_status = 'P'
   WHERE taxhead_doc_type = pOrderType
     AND taxhead_doc_id = pOrderId;

  IF pOrderType = 'VCH' THEN
    IF (SELECT (fetchMetricBool('AssumeCorrectTax') AND vohead_tax_charged IS NULL) OR
               getOrderTax('VCH', vohead_id) - COALESCE(vohead_tax_charged, 0.0) <= 0.0
          FROM vohead
         WHERE vohead_id = pOrderId) THEN
      RETURN NULL;
    END IF;
  END IF;

  _service := fetchMetricText('TaxService');

  IF _service = 'A' THEN
    RETURN '{"commit": true}'::JSONB;
  END IF;

  RETURN '{}'::JSONB;

END
$$ language plpgsql;
