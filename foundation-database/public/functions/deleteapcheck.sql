CREATE OR REPLACE FUNCTION deleteAPCheck(INTEGER) RETURNS INTEGER AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN
  RAISE WARNING ''deleteAPCheck() is deprecated - use deleteCheck() instead'';
  RETURN deleteCheck($1);
END;
' LANGUAGE 'plpgsql';
