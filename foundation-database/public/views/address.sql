DROP VIEW IF EXISTS address;

CREATE VIEW address AS
SELECT addr.*,
       COALESCE(crmacct_id, -1) AS crmacct_id, crmacct_number, crmacct_name
  FROM addr
  LEFT OUTER JOIN (
    SELECT cntct_addr_id AS join_id, crmacct_id, crmacct_number, crmacct_name
    FROM cntct
    JOIN crmacctcntctass ON (cntct_id=crmacctcntctass_cntct_id)
    JOIN crmacct ON (crmacctcntctass_crmacct_id=crmacct_id)
    UNION
    -- Vendor
    SELECT vend_addr_id, crmacct_id, crmacct_number, crmacct_name
    FROM vendinfo
    JOIN crmacct ON (vend_crmacct_id=crmacct_id)
    UNION
    -- Vendor Addresses
    SELECT vendaddr_addr_id, crmacct_id, crmacct_number, crmacct_name
    FROM vendaddrinfo
    JOIN vendinfo ON (vendaddr_vend_id=vend_id)
    JOIN crmacct ON (vend_crmacct_id=crmacct_id)
    UNION
    -- Tax Authority
    SELECT taxauth_addr_id, crmacct_id, crmacct_number, crmacct_name
    FROM taxauth
    JOIN crmacct ON (taxauth_crmacct_id=crmacct_id)
    UNION
    -- Customer Ship-to
    SELECT shipto_addr_id, crmacct_id, crmacct_number, crmacct_name
    FROM shiptoinfo
    JOIN custinfo ON (shipto_cust_id=cust_id)
    JOIN crmacct ON (cust_crmacct_id=crmacct_id)
  ) AS addresses ON addr_id = join_id
;

GRANT ALL ON address TO xtrole;
