CREATE OR REPLACE FUNCTION ophead() RETURNS SETOF ophead AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _priv TEXT;
  _grant BOOLEAN;

BEGIN
  -- This query will give us the most permissive privilege the user has been granted
  SELECT privilege, granted INTO _priv, _grant
  FROM privgranted 
  WHERE privilege IN ('MaintainAllOpportunities','ViewAllOpportunities','MaintainPersonalOpportunities','ViewPersonalOpportunities')
  ORDER BY granted DESC, sequence
  LIMIT 1;

  -- If have an 'All' privilege return all results
  IF (_priv ~ 'All' AND _grant) THEN
    RETURN QUERY SELECT * FROM ophead;
  -- Otherwise if have any other grant, must be personal privilege.
  ELSIF (_grant) THEN
    RETURN QUERY SELECT * FROM ophead 
                 WHERE getEffectiveXtUser() IN (ophead_owner_username, ophead_username);
  END IF;

  RETURN;

END;
$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION ophead() IS 'A table function that returns Opportunity results according to privilege settings.';
