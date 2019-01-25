DROP FUNCTION IF EXISTS setmetricenc(text, text, text);

CREATE OR REPLACE FUNCTION setmetricenc(pMetricName TEXT, pMetricValue TEXT, pMetricEnc TEXT)
  RETURNS bool AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _metricid INTEGER;
  _value bytea;
  _key bytea;

BEGIN

  _value = decode(pMetricValue, 'escape');
  _key = decode(pMetricEnc, 'escape');

  INSERT INTO metricenc (metricenc_name, metricenc_value)
       VALUES (pMetricName, encrypt(_value, _key, 'bf'))
  ON CONFLICT (metricenc_name)
  DO UPDATE SET metricenc_value=encrypt(_value, _key, 'bf');

  RETURN TRUE;

END;
$$ LANGUAGE plpgsql;
