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
    RETURN QUERY SELECT * FROM crmacct
                 WHERE (CASE WHEN checkprivilege('MaintainVendorAccounts ViewVendorAccounts')
                                  THEN crmaccttypes(crmacct_id)#>>'{vendor}' IS NOT NULL
                                  ELSE false END
                         OR  CASE WHEN checkprivilege('MaintainCustomerMasters ViewCustomerMasters')
                                  THEN crmaccttypes(crmacct_id)#>>'{customer}' IS NOT NULL
                                  ELSE false END
                         OR  CASE WHEN checkprivilege('MaintainSalesReps ViewSalesReps')
                                  THEN crmaccttypes(crmacct_id)#>>'{salesrep}' IS NOT NULL
                                  ELSE false END
                         OR  CASE WHEN checkprivilege('MaintainTaxAuthorities ViewTaxAuthorities')
                                  THEN crmaccttypes(crmacct_id)#>>'{taxauth}' IS NOT NULL
                                  ELSE false END
                         OR  CASE WHEN checkprivilege('MaintainProspectMasters ViewProspectMasters')
                                  THEN crmaccttypes(crmacct_id)#>>'{prospect}' IS NOT NULL
                                  ELSE false END
                         OR  CASE WHEN checkprivilege('MaintainEmployees ViewEmployees')
                                  THEN crmaccttypes(crmacct_id)#>>'{employee}' IS NOT NULL
                                  ELSE false END
                         OR  CASE WHEN checkprivilege('MaintainUsers')
                                  THEN crmaccttypes(crmacct_id)#>>'{user}' IS NOT NULL
                                  ELSE false END
                         -- plus handle the 'other' types of CRM account
                         OR CASE WHEN crmaccttypes(crmacct_id)::TEXT ='{"customer":null,"vendor":null,"salesrep":null,"taxauth":null,"prospect":null,"employee":null,"user":null}'
                                  THEN true ELSE false END
                        );
  -- Otherwise if have any other grant, must be personal privilege.
  ELSIF (_grant) THEN
    RETURN QUERY SELECT * FROM crmacct
                  WHERE crmacct_owner_username = getEffectiveXtUser()
                    AND (CASE WHEN checkprivilege('MaintainVendorAccounts ViewVendorAccounts')
                                  THEN crmaccttypes(crmacct_id)#>>'{vendor}' IS NOT NULL
                                  ELSE false END
                         OR  CASE WHEN checkprivilege('MaintainCustomerMasters ViewCustomerMasters')
                                  THEN crmaccttypes(crmacct_id)#>>'{customer}' IS NOT NULL
                                  ELSE false END
                         OR  CASE WHEN checkprivilege('MaintainSalesReps ViewSalesReps')
                                  THEN crmaccttypes(crmacct_id)#>>'{salesrep}' IS NOT NULL
                                  ELSE false END
                         OR  CASE WHEN checkprivilege('MaintainTaxAuthorities ViewTaxAuthorities')
                                  THEN crmaccttypes(crmacct_id)#>>'{taxauth}' IS NOT NULL
                                  ELSE false END
                         OR  CASE WHEN checkprivilege('MaintainProspectMasters ViewProspectMasters')
                                  THEN crmaccttypes(crmacct_id)#>>'{prospect}' IS NOT NULL
                                  ELSE false END
                         OR  CASE WHEN checkprivilege('MaintainEmployees ViewEmployees')
                                  THEN crmaccttypes(crmacct_id)#>>'{employee}' IS NOT NULL
                                  ELSE false END
                         OR  CASE WHEN checkprivilege('MaintainUsers')
                                  THEN crmaccttypes(crmacct_id)#>>'{user}' IS NOT NULL
                                  ELSE false END
                         -- plus handle the 'other' types of CRM account
                         OR CASE WHEN crmaccttypes(crmacct_id)::TEXT ='{"customer":null,"vendor":null,"salesrep":null,"taxauth":null,"prospect":null,"employee":null,"user":null}'
                                  THEN true ELSE false END
                        );
  END IF;

  RETURN;

END;
$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION crmacct() IS 'A table function that returns CRM Account results according to privilege settings.';
