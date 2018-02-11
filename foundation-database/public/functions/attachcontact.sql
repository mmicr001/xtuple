DROP FUNCTION IF EXISTS attachContact(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION attachContact(pCntctId INTEGER, pCrmacctId INTEGER, pRole INTEGER, pDefault BOOLEAN DEFAULT FALSE) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

-- First remove existing defaults
  IF (pDefault) THEN
    UPDATE crmacctcntctass SET crmacctcntctass_default=FALSE
    WHERE crmacctcntctass_crmacct_id=pCrmacctId
      AND  crmacctcntctass_cntct_id != pCntctId
      AND  crmacctcntctass_crmrole_id=pRole;
  END IF;

-- Now insert new Contact assignment
  INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id,
                               crmacctcntctass_crmrole_id, crmacctcntctass_default)
  SELECT pCrmacctId, pCntctId, pRole, pDefault
  WHERE NOT EXISTS (SELECT 1 FROM crmacctcntctass
                            WHERE crmacctcntctass_crmacct_id=pCrmacctId
                             AND  crmacctcntctass_cntct_id=pCntctId
                             AND  crmacctcntctass_crmrole_id=pRole);
  RETURN 0;
END;
$$ LANGUAGE plpgsql;

