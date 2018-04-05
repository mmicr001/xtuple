CREATE OR REPLACE FUNCTION crmacctTypes(pCrmAcctId INTEGER)
RETURNS json AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.

-- Returns list of CRM entity relationship IDs as a json string
-- TODO make dynamic based on foreign keys (at this stage it returns non CRM table fks)

      SELECT row_to_json(d) AS associations
      FROM (
         SELECT
            (SELECT cust_id
            FROM custinfo
            WHERE cust_crmacct_id = pCrmAcctId) as customer,
           (SELECT vend_id
            FROM vendinfo
            WHERE vend_crmacct_id = pCrmAcctId) as vendor,
            (SELECT salesrep_id
            FROM salesrep
            WHERE salesrep_crmacct_id = pCrmAcctId) as salesrep,
            (SELECT taxauth_id
            FROM taxauth
            WHERE taxauth_crmacct_id = pCrmAcctId) as taxauth,
            (SELECT prospect_id
            FROM prospect
            WHERE prospect_crmacct_id = pCrmAcctId) as prospect,
            (SELECT emp_id
            FROM emp
            WHERE emp_crmacct_id = pCrmAcctId) as employee,
            (SELECT crmacct_usr_username
             FROM crmacct
             WHERE crmacct_id = pCrmAcctId) as user
      ) d

$$ LANGUAGE SQL;
