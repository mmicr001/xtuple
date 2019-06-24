CREATE OR REPLACE FUNCTION countNotNull (pColumns ANYARRAY) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _notNull INTEGER;
BEGIN
  SELECT COUNT(cols) INTO _notNull
  FROM UNNEST(pColumns) AS cols;

  RETURN _notNull;
END;
$$ LANGUAGE 'plpgsql';
