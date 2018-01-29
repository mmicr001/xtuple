/**
   This is really not a good idea because address relationships are not generally extensible
   using a union like this. Implementing this way because of time constraints. A
   different method more like the way documents are handled shoud be used in the future.
*/
DROP VIEW IF EXISTS xt.crmacctaddr CASCADE;

create or replace view xt.crmacctaddr as

  -- Contact
  select addr.*, crmacctcntctass_crmacct_id AS crmacct_id
  from addr
    join cntct ON cntct_addr_id=addr_id
    join crmacctcntctass ON crmacctcntctass_cntct_id=cntct_id
  union
  -- Vendor
  select addr.*, vend_crmacct_id AS crmacct_id
  from addr
    join vendinfo ON vend_addr_id=addr_id
  union
  -- Vendor Addresses
  select addr.*, vend_crmacct_id AS crmacct_id
  from addr
    join vendaddrinfo on vendaddr_addr_id=addr_id
    join vendinfo on vendaddr_vend_id=vend_id
  union
  -- Tax Authority
  select addr.*, taxauth_crmacct_id AS crmacct_id
  from addr
    join taxauth on taxauth_addr_id=addr_id
  union
  -- Customer Billing Contact
  select addr.*, cust_crmacct_id AS crmacct_id
  from addr
    join cntct on cntct_addr_id=addr_id
    join custinfo on cust_cntct_id=cntct_id
  union
  -- Customer Correspondence Contact
  select addr.*, cust_crmacct_id AS crmacct_id
  from addr
    join cntct on cntct_addr_id=addr_id
    join custinfo on cust_corrcntct_id=cntct_id
  union
  -- Customer Ship-to
  select addr.*, cust_crmacct_id AS crmacct_id
  from addr
    join shiptoinfo on shipto_addr_id=addr_id
    join custinfo on shipto_cust_id=cust_id;

grant all on xt.crmacctaddr to xtrole;
