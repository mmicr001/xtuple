CREATE OR REPLACE FUNCTION getContactPhone(pContctId INTEGER, pType TEXT)
RETURNS TEXT AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.

-- Returns the most recently entered phone number by Type for a Contact
   SELECT cntctphone_phone FROM cntctphone
   JOIN crmrole ON (crmrole_id=cntctphone_crmrole_id)
   WHERE cntctphone_cntct_id=pContctId
   and crmrole_name = pType
   ORDER BY cntctphone_id DESC
   LIMIT 1;
$$ LANGUAGE sql;
