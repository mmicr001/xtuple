CREATE OR REPLACE FUNCTION voidAPCheck(INTEGER) RETURNS INTEGER AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN
  RAISE WARNING ''voidAPCheck() is deprecated - use voidCheck() instead'';
  RETURN voidCheck($1);
END;
' LANGUAGE 'plpgsql';
