CREATE OR REPLACE FUNCTION postAPChecks(INTEGER) RETURNS INTEGER AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN

  RAISE WARNING ''postAPChecks() is deprecated - use postChecks() instead'';
  RETURN postChecks($1);

END;
' LANGUAGE 'plpgsql';
