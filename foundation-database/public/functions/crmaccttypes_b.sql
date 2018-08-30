CREATE OR REPLACE FUNCTION crmacctTypes_b(pCrmAcctId INTEGER)
RETURNS jsonb AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.

-- Returns CRM entity relationship IDs as a jsonb structure
-- TODO make dynamic based on foreign keys (at this stage it returns non CRM table fks)

  SELECT jsonb_object_agg(key, value)
    FROM (SELECT           'customer' AS key, cust_id::text AS value FROM custinfo WHERE cust_crmacct_id = pCrmAcctId
          UNION ALL SELECT 'vendor',          vend_id::text          FROM vendinfo WHERE vend_crmacct_id = pCrmAcctId
          UNION ALL SELECT 'salesrep',        salesrep_id::text      FROM salesrep WHERE salesrep_crmacct_id = pCrmAcctId
          UNION ALL SELECT 'taxauth',         taxauth_id::text       FROM taxauth  WHERE taxauth_crmacct_id = pCrmAcctId
          UNION ALL SELECT 'prospect',        prospect_id::text      FROM prospect WHERE prospect_crmacct_id = pCrmAcctId
          UNION ALL SELECT 'employee',        emp_id::text           FROM emp      WHERE emp_crmacct_id = pCrmAcctId
          UNION ALL SELECT 'user',            crmacct_usr_username   FROM crmacct  WHERE crmacct_usr_username IS NOT NULL AND crmacct_id = pCrmAcctId
    ) data;

$$ LANGUAGE SQL;
