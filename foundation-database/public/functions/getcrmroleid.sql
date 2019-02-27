CREATE OR REPLACE FUNCTION getCrmRoleId(pRoleName text DEFAULT 'Primary') RETURNS INTEGER STABLE AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _returnVal INTEGER;
BEGIN
  
  IF (pRoleName IS NULL) THEN
    RETURN NULL;
  END IF;

  SELECT crmrole_id INTO _returnVal
  FROM crmrole
  WHERE (UPPER(crmrole_name)=UPPER(pRoleName));
  
  RETURN _returnVal;
END;
$$ LANGUAGE plpgsql;
