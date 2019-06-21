CREATE OR REPLACE FUNCTION revokeGroup(TEXT, INTEGER) RETURNS BOOL AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  pUsername ALIAS FOR $1;
  pGrpid ALIAS FOR $2;

BEGIN

  DELETE FROM usrgrp
  WHERE ( (usrgrp_username=pUsername)
   AND (usrgrp_grp_id=pGrpid) );

  RETURN TRUE;

END;
' LANGUAGE 'plpgsql';

