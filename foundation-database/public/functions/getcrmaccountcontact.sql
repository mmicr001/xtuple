CREATE OR REPLACE FUNCTION getCrmAccountContact(pCRMAcct INTEGER, pRole TEXT DEFAULT 'Primary') RETURNS INTEGER STABLE AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _returnVal INTEGER;
BEGIN
  
  IF (pCRMAcct IS NULL OR pRole IS NULL) THEN
    RETURN NULL;
  END IF;

  SELECT crmacctcntctass_cntct_id INTO _returnVal
  FROM crmacctcntctass
  WHERE crmacctcntctass_crmacct_id=pCRMAcct
  AND   crmacctcntctass_crmrole_id=getcrmroleid(pRole)
  ORDER BY crmacctcntctass_default DESC
  LIMIT 1;
  
  RETURN _returnVal;
END;
$$ LANGUAGE plpgsql;
