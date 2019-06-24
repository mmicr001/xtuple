CREATE OR REPLACE FUNCTION FetchDefaultShipVia() RETURNS TEXT AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _returnVal TEXT;
BEGIN
  SELECT shipvia_code || '-' || COALESCE(shipvia_descrip, '') INTO _returnVal
  FROM shipvia
  WHERE shipvia_id=
	(SELECT CAST(metric_value AS integer)
	FROM metric
	WHERE metric_name = 'DefaultShipViaId');
  RETURN _returnVal;
END;
$$ LANGUAGE 'plpgsql';
