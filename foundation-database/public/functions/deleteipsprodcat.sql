CREATE OR REPLACE FUNCTION deleteIpsProdCat(pIpsItemId INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE

BEGIN

  DELETE FROM ipsiteminfo WHERE ipsitem_id=pIpsItemId;
  
  RETURN 1;
END;
$$ LANGUAGE 'plpgsql';

