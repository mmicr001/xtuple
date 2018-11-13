DROP FUNCTION IF EXISTS detachContact(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS detachContact(INTEGER, INTEGER, TEXT);

CREATE OR REPLACE FUNCTION detachContact(pAssignmentId INTEGER)
RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
 _rec    RECORD;
BEGIN

-- Cache full-text information
  SELECT cntct_id, cntct_name, crmacct_name, crmrole_name INTO _rec
    FROM crmacctcntctass
    JOIN cntct   ON cntct_id   = crmacctcntctass_cntct_id
    JOIN crmacct ON crmacct_id = crmacctcntctass_crmacct_id
    JOIN crmrole ON crmrole_id = crmacctcntctass_crmrole_id
   WHERE crmacctcntctass_id = pAssignmentId;

  UPDATE crmacctcntctass SET crmacctcntctass_active = FALSE
  WHERE crmacctcntctass_id = pAssignmentId;

  PERFORM postComment('ChangeLog', 'T', _rec.cntct_id,
                      format('Assignment Updated: %s was marked as inactive in Account %s',
                             _rec.cntct_name, _rec.crmacct_name));

  RETURN 0;
END;
$$ LANGUAGE plpgsql;

