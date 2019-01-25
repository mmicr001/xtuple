DROP FUNCTION IF EXISTS setMetric(TEXT, TEXT);

CREATE OR REPLACE FUNCTION setMetric(pMetricName TEXT, pMetricValue TEXT) RETURNS BOOLEAN AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  INSERT INTO metric (metric_name, metric_value)
  VALUES (pMetricName, pMetricValue)
  ON CONFLICT (metric_name)
  DO UPDATE SET metric_value=pMetricValue;

  RETURN TRUE;

END;
$$ LANGUAGE plpgsql;
