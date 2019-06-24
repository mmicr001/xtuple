CREATE OR REPLACE FUNCTION createAPChecks(INTEGER, DATE) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN
  RAISE WARNING 'createAPChecks() is deprecated - use createChecks() instead';
  RETURN createChecks($1, $2);
END;
$$ LANGUAGE 'plpgsql';
