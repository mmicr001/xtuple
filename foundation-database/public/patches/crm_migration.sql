-- =================================================================================================
-- Migrate Contact Links from CRM Accounts into assignment table
-- =================================================================================================
INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
SELECT crmacct_id, crmacct_cntct_id_1, (select crmrole_id from crmrole WHERE crmrole_name = 'Primary')
FROM crmacct WHERE crmacct_cntct_id_1 IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM crmacctcntctass WHERE crmacctcntctass_crmacct_id=crmacct_id AND crmacctcntctass_cntct_id=crmacct_cntct_id_1);

INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
SELECT crmacct_id, crmacct_cntct_id_2, (select crmrole_id from crmrole WHERE crmrole_name = 'Secondary')
FROM crmacct WHERE crmacct_cntct_id_2 IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM crmacctcntctass WHERE crmacctcntctass_crmacct_id=crmacct_id AND crmacctcntctass_cntct_id=crmacct_cntct_id_2);

INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
SELECT cntct_crmacct_id, cntct_id, (select crmrole_id from crmrole WHERE crmrole_name = 'Other')
FROM cntct WHERE cntct_crmacct_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM crmacctcntctass WHERE crmacctcntctass_crmacct_id=cntct_crmacct_id AND crmacctcntctass_cntct_id=cntct_id);

ALTER TABLE public.crmacct DROP CONSTRAINT IF EXISTS crmacct_crmacct_cntct_id_1_fkey;
ALTER TABLE public.crmacct DROP CONSTRAINT IF EXISTS crmacct_crmacct_cntct_id_2_fkey;

-- Remove CRM Account object links (reversing FK relationships)
ALTER TABLE public.crmacct DROP CONSTRAINT IF EXISTS crmacct_crmacct_cust_id_fkey;
ALTER TABLE public.crmacct DROP CONSTRAINT IF EXISTS crmacct_crmacct_emp_id_fkey;
ALTER TABLE public.crmacct DROP CONSTRAINT IF EXISTS crmacct_crmacct_prospect_id_fkey;
ALTER TABLE public.crmacct DROP CONSTRAINT IF EXISTS crmacct_crmacct_salesrep_id_fkey;
ALTER TABLE public.crmacct DROP CONSTRAINT IF EXISTS crmacct_crmacct_taxauth_id_fkey;
ALTER TABLE public.crmacct DROP CONSTRAINT IF EXISTS crmacct_crmacct_vend_id_fkey;

ALTER TABLE public.cntct DROP CONSTRAINT IF EXISTS cntct_cntct_crmacct_id_fkey;

-- =================================================================================================
-- Migrate CRM Account Links from CRM Accouonts to other entities
-- =================================================================================================
-- Add CRM Account link to tables (apply NOT NULL after populating)
SELECT 
  xt.add_column('custinfo', 'cust_crmacct_id',     'INTEGER', null, 'public'),
  xt.add_column('prospect', 'prospect_crmacct_id', 'INTEGER', null, 'public'),
  xt.add_column('emp',      'emp_crmacct_id',      'INTEGER', null, 'public'),
  xt.add_column('salesrep', 'salesrep_crmacct_id', 'INTEGER', null, 'public'),
  xt.add_column('taxauth',  'taxauth_crmacct_id',  'INTEGER', null, 'public'),
  xt.add_column('vendinfo', 'vend_crmacct_id',     'INTEGER', null, 'public');

-- Foreign keys
SELECT 
  xt.add_constraint('custinfo', 'custinfo_crmacct_id_fkey',
                    'FOREIGN KEY (cust_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('prospect', 'prospect_crmacct_id_fkey',
                    'FOREIGN KEY (prospect_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('emp', 'emp_crmacct_id_fkey',
                    'FOREIGN KEY (emp_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('salesrep', 'salesrep_crmacct_id_fkey',
                    'FOREIGN KEY (salesrep_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('taxauth', 'taxauth_crmacct_id_fkey',
                    'FOREIGN KEY (taxauth_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('vendinfo', 'vendinfo_crmacct_id_fkey',
                    'FOREIGN KEY (vend_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');

-- Migrate the CRM Account Data
UPDATE custinfo SET cust_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_cust_id=cust_id);
UPDATE prospect SET prospect_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_prospect_id=prospect_id);
UPDATE emp SET emp_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_emp_id=emp_id);
UPDATE salesrep SET salesrep_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_salesrep_id=salesrep_id);
UPDATE taxauth SET taxauth_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_taxauth_id=taxauth_id);
UPDATE vendinfo SET vend_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_vend_id=vend_id);

-- Now set crmacct columns to NOT NULL
ALTER TABLE custinfo ALTER COLUMN cust_crmacct_id SET NOT NULL;
ALTER TABLE prospect ALTER COLUMN prospect_crmacct_id SET NOT NULL;
ALTER TABLE emp ALTER COLUMN emp_crmacct_id SET NOT NULL;
ALTER TABLE salesrep ALTER COLUMN salesrep_crmacct_id SET NOT NULL;
ALTER TABLE taxauth ALTER COLUMN taxauth_crmacct_id SET NOT NULL;
ALTER TABLE vendinfo ALTER COLUMN vend_crmacct_id SET NOT NULL;

-- And finally DROP the deprecated columns
/*
ALTER TABLE crmacct DROP COLUMN crmacct_cust_id;
ALTER TABLE crmacct DROP COLUMN crmacct_prospect_id;
ALTER TABLE crmacct DROP COLUMN crmacct_vend_id;
ALTER TABLE crmacct DROP COLUMN crmacct_cntct_id_1;
ALTER TABLE crmacct DROP COLUMN crmacct_cntct_id_2;
ALTER TABLE crmacct DROP COLUMN crmacct_taxauth_id;
ALTER TABLE crmacct DROP COLUMN crmacct_emp_id;
ALTER TABLE crmacct DROP COLUMN crmacct_salesrep_id;
*/

COMMENT ON COLUMN public.crmacct.crmacct_cust_id IS 'DEPRECATED If this is not null, this CRM Account is a Customer.';
COMMENT ON COLUMN public.crmacct.crmacct_competitor_id IS 'DEPRECATED For now, > 0 indicates this CRM Account is a competitor. Eventually this may become a foreign key to a table of competitors.';
COMMENT ON COLUMN public.crmacct.crmacct_partner_id IS 'DEPRECATED For now, > 0 indicates this CRM Account is a partner. Eventually this may become a foreign key to a table of partners.';
COMMENT ON COLUMN public.crmacct.crmacct_prospect_id IS 'DEPRECATED If this is not null, this CRM Account is a Prospect.';
COMMENT ON COLUMN public.crmacct.crmacct_vend_id IS 'DEPRECATED If this is not null, this CRM Account is a Vendor.';
COMMENT ON COLUMN public.crmacct.crmacct_cntct_id_1 IS 'DEPRECATED The primary contact for the CRM Account.';
COMMENT ON COLUMN public.crmacct.crmacct_cntct_id_2 IS 'DEPRECATED The secondary contact for the CRM Account.';
COMMENT ON COLUMN public.crmacct.crmacct_taxauth_id IS 'DEPRECATED If this is not null, this CRM Account is a Tax Authority.';
COMMENT ON COLUMN public.crmacct.crmacct_emp_id IS 'DEPRECATED If this is not null, this CRM Account is an Employee.';
COMMENT ON COLUMN public.crmacct.crmacct_salesrep_id IS 'DEPRECATED If this is not null, this CRM Account is a Sales Rep.';
