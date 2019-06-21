CREATE OR REPLACE FUNCTION deleteBOMWorkset(INTEGER) RETURNS INTEGER AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  pWorksetid ALIAS FOR $1;

BEGIN

--  All done with the bomwork set indicated by pWorksetid, delete all of it
  DELETE FROM bomwork
  WHERE (bomwork_set_id=pWorksetid);

  RETURN 1;

END;
' LANGUAGE 'plpgsql';
