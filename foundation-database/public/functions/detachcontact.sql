DROP FUNCTION IF EXISTS detachContact(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION detachContact(pcntctId INTEGER, pcrmacctId INTEGER, prole TEXT DEFAULT '') 
RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
 roleid  INTEGER;
BEGIN

  roleid := (SELECT crmrole_id FROM crmrole WHERE crmrole_name = prole);

  DELETE FROM crmacctcntctass
  WHERE crmacctcntctass_crmacct_id = pcrmacctId
    AND crmacctcntctass_cntct_id = pcntctId
    AND (crmacctcntctass_crmrole_id = roleid OR roleid IS NULL);

  RETURN 0;
END;
$$ LANGUAGE plpgsql;

