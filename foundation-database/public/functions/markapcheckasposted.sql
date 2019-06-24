CREATE OR REPLACE FUNCTION markAPCheckASPosted(INTEGER) RETURNS INTEGER AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN
  RAISE WARNING ''markAPCheckAsPosted() is deprecated - use markCheckAsPosted() instead'';
  RETURN markCheckAsPosted($1);

END;
' LANGUAGE 'plpgsql';
