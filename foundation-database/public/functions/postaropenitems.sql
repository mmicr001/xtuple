CREATE OR REPLACE FUNCTION postAropenItems() RETURNS BOOLEAN AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN

  UPDATE aropen
  SET aropen_posted=TRUE
  WHERE (NOT aropen_posted);

  RETURN TRUE;

END;
' LANGUAGE 'plpgsql';
