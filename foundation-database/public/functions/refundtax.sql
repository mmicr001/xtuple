CREATE OR REPLACE FUNCTION refundTax(pInvcheadId INTEGER, pRefundDate DATE) RETURNS JSONB AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _aropenid INTEGER;
  _number TEXT;
  _service TEXT;

BEGIN

  _number := fetchARMemoNumber();

  INSERT INTO aropen (aropen_docdate, aropen_duedate, aropen_docnumber, aropen_amount)
  VALUES (pRefundDate, pRefundDate, _number, getOrderTax('INV', pInvcheadId))
  RETURNING aropen_id INTO _aropenid;

  PERFORM copyTax('INV', pInvcheadId, 'AR', _aropenid);
  PERFORM copyTax('INV', pInvcheadId, 'AR', _aropenid, _aropenid);

  PERFORM createARCreditMemo(_aropenid, invchead_cust_id, _number, '', pRefundDate,
                             getOrderTax('INV', pInvcheadId), '', -1, -1, -1, pRefundDate, -1,
                             invchead_salesrep_id, 0, NULL, invchead_curr_id)
     FROM invchead
    WHERE invchead_id = pInvcheadid;
  
  _service := fetchMetricText('TaxService');

  IF _service = 'A' THEN
    RETURN ('{"refundType": "TaxOnly", "refundTransactionCode":"AR-' || _number || '", "refundDate": "' || pRefundDate || '"}')::JSONB;
  END IF;

  RETURN '{}'::JSONB;

END
$$ language plpgsql;
