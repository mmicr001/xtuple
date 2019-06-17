CREATE OR REPLACE FUNCTION deleteEmpGrp(INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pempgrpid ALIAS FOR $1;

BEGIN
  DELETE FROM empgrpitem
  WHERE (empgrpitem_empgrp_id=pempgrpid);

  DELETE FROM empgrp     WHERE (empgrp_id=pempgrpid);

  RETURN 0;
END;
$$ LANGUAGE 'plpgsql';
