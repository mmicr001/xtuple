CREATE OR REPLACE FUNCTION formatCost(NUMERIC) RETURNS TEXT IMMUTABLE AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN
  RETURN formatNumeric($1, ''cost'');
END;'
LANGUAGE 'plpgsql';
