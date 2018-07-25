CREATE OR REPLACE FUNCTION buildAvalaraUrl(pType        TEXT,
                                           pOrderType   TEXT,
                                           pOrderId     INTEGER,
                                           pOverrideUrl TEXT) RETURNS TEXT AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _base TEXT;
  _number TEXT;

BEGIN

  IF pOverrideUrl IS NOT NULL THEN
    _base := pOverrideUrl;
  ELSE
    _base := fetchMetricText('AvalaraUrl');
  END IF;

  _base := _base || 'api/v2/';

  SELECT dochead_number
    INTO _number
    FROM dochead
   WHERE dochead_type = pOrderType
     AND dochead_id = pOrderId;

  IF pType = 'taxcodes' THEN
    RETURN _base || 'definitions/taxcodes';
  ELSIF pType = 'taxexempt' THEN
    RETURN _base || 'definitions/entityusecodes';
  ELSIF pType = 'createtransaction' THEN
    RETURN _base || 'transactions/createoradjust?$include=Details';
  ELSIF pType = 'committransaction' THEN
    RETURN _base || 'companies/' || fetchMetricText('AvalaraCompany') || '/' ||
           _number || '/commit';
  ELSIF pType = 'voidtransaction' THEN
    RETURN _base || 'companies/' || fetchMetricText('AvalaraCompany') || '/' ||
           _number || '/void';
  ELSE
    RETURN _base || 'utilities/ping';
  END IF;

END
$$ language plpgsql;
