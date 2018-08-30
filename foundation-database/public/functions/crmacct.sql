CREATE OR REPLACE FUNCTION crmacct() RETURNS SETOF crmacct AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _all  BOOLEAN := checkPrivilege('MaintainAllCRMAccounts ViewAllCRMAccounts');
  _mine BOOLEAN := checkPrivilege('MaintainPersonalCRMAccounts ViewPersonalCRMAccounts');
BEGIN

  RETURN QUERY
    WITH augmented AS (
      SELECT row(crmacct.*)::crmacct, crmaccttypes(crmacct_id) AS types FROM crmacct
    )
    SELECT (row).* FROM augmented
     WHERE _all
        OR (_mine AND (row).crmacct_owner_username = getEffectiveXtUser()
            AND  CASE WHEN types ? 'vendor' THEN checkprivilege('MaintainVendorAccounts ViewVendorAccounts')
                      WHEN types ? 'customer' THEN checkprivilege('MaintainCustomerMasters ViewCustomerMasters')
                      WHEN types ? 'salesrep' THEN checkprivilege('MaintainSalesReps ViewSalesReps')
                      WHEN types ? 'taxauth' THEN checkprivilege('MaintainTaxAuthorities ViewTaxAuthorities')
                      WHEN types ? 'prospect' THEN checkprivilege('MaintainProspectMasters ViewProspectMasters')
                      WHEN types ? 'employee' THEN checkprivilege('MaintainEmployees ViewEmployees')
                      WHEN types ? 'user' THEN checkprivilege('MaintainUsers')
                      ELSE true
                 END);

END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION crmacct() IS 'A table function that returns CRM Account results according to privilege settings.';
