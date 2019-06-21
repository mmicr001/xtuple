DROP FUNCTION IF EXISTS detachContact(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS detachContact(INTEGER, INTEGER, TEXT);

CREATE OR REPLACE FUNCTION detachContact(pAssignmentId INTEGER)
RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN

  UPDATE crmacctcntctass SET crmacctcntctass_active = FALSE
  WHERE crmacctcntctass_id = pAssignmentId;

  RETURN 0;
END;
$$ LANGUAGE plpgsql;

