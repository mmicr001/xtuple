CREATE OR REPLACE FUNCTION crmacct() RETURNS SETOF crmacct AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _priv TEXT;
  _grant BOOLEAN;

BEGIN
  -- This query will give us the most permissive privilege the user has been granted
  SELECT privilege, granted INTO _priv, _grant
  FROM privgranted 
  WHERE privilege IN ('MaintainAllCRMAccounts','ViewAllCRMAccounts','MaintainPersonalCRMAccounts','ViewPersonalCRMAccounts')
  ORDER BY granted DESC, sequence
  LIMIT 1;

  -- If have an 'All' privilege return all results
  IF (_priv ~ 'All' AND _grant) THEN
    RETURN QUERY SELECT * FROM crmacct;
  -- Otherwise if have any other grant, must be personal privilege.
  ELSIF (_grant) THEN
    RETURN QUERY SELECT * FROM crmacct 
                  WHERE crmacct_owner_username = getEffectiveXtUser();
  END IF;

  RETURN;

END;
$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION crmacct() IS 'A table function that returns CRM Account results according to privilege settings.';
