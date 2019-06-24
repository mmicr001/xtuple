CREATE OR REPLACE FUNCTION postAPCheck(INTEGER) RETURNS INTEGER AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN
  RAISE WARNING ''postAPCheck() is deprecated - use postCheck() instead'';
  RETURN postCheck($1, fetchJournalNumber(''AP-CK''));
END;
' LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION postAPCheck(INTEGER, INTEGER) RETURNS INTEGER AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN
  RAISE WARNING ''postAPCheck() is deprecated - use postCheck() instead'';
  RETURN postCheck($1, $2);
END;
' LANGUAGE 'plpgsql';
