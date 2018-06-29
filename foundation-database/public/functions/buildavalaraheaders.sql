CREATE OR REPLACE FUNCTION buildAvalaraHeaders(pLocalHost TEXT,
                                               pOverrideAccount TEXT,
                                               pOverrideKey TEXT) RETURNS TEXT AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _account TEXT;
  _key TEXT;
  _client TEXT;
  _auth TEXT;

BEGIN

  IF pOverrideAccount IS NOT NULL THEN
    _account := pOverrideAccount;
  ELSE
    _account := fetchMetricText('AvalaraAccount');
  END IF;

  IF pOverrideKey IS NOT NULL THEN 
    _key := pOverrideKey;
  ELSE
    _key := fetchMetricText('AvalaraKey');
  END IF;

  _client := 'X-Avalara-Client: xTuple; ' || fetchMetricText('ServerVersion') || '; REST; V2; ' || pLocalHost;
  _auth := 'Authorization: Basic ' || encode(setbytea(_account || ':' || _key), 'base64');

  RETURN 'Content-Type: application/json' || ',' || 'X-Avalara-UID: a0o0b000003PfVt'::TEXT || ',' ||
         _client || ',' || _auth;

END
$$ language plpgsql;
