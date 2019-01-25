DROP FUNCTION IF EXISTS deleteEmpGrp(INTEGER);

CREATE OR REPLACE FUNCTION deleteEmpGrp(pempgrpid INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
--  Check to see if any employees are assigned to the passed empgrp
  PERFORM groupsitem_reference_id
  FROM empgrpitem
  WHERE (groupsitem_groups_id=pempgrpid)
  LIMIT 1;
  IF (FOUND) THEN
    RETURN -1;
  END IF;

  DELETE FROM empgrp WHERE (groups_id=pempgrpid);

  RETURN 0;
END;
$$ LANGUAGE plpgsql;
