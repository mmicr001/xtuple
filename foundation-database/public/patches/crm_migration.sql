-- =================================================================================================
-- Migrate Contact Links from CRM Accounts into assignment table
-- =================================================================================================
INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
SELECT crmacct_id, crmacct_cntct_id_1, getcrmroleid('Primary')
FROM crmacct WHERE crmacct_cntct_id_1 IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM crmacctcntctass WHERE crmacctcntctass_crmacct_id=crmacct_id AND crmacctcntctass_cntct_id=crmacct_cntct_id_1);

INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
SELECT crmacct_id, crmacct_cntct_id_2, getcrmroleid('Secondary')
FROM crmacct WHERE crmacct_cntct_id_2 IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM crmacctcntctass WHERE crmacctcntctass_crmacct_id=crmacct_id AND crmacctcntctass_cntct_id=crmacct_cntct_id_2);

INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
SELECT cntct_crmacct_id, cntct_id, getcrmroleid('Other')
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
-- Migrate CRM Account Links from CRM Accounts to other entities
-- =================================================================================================
-- Add CRM Account link to tables (apply NOT NULL after populating)
SELECT 
  xt.add_column('custinfo', 'cust_crmacct_id',     'INTEGER', 'NOT NULL UNIQUE', 'public'),
  xt.add_column('prospect', 'prospect_crmacct_id', 'INTEGER', 'NOT NULL UNIQUE', 'public'),
  xt.add_column('emp',      'emp_crmacct_id',      'INTEGER', 'NOT NULL UNIQUE', 'public'),
  xt.add_column('salesrep', 'salesrep_crmacct_id', 'INTEGER', 'NOT NULL UNIQUE', 'public'),
  xt.add_column('taxauth',  'taxauth_crmacct_id',  'INTEGER', 'NOT NULL UNIQUE', 'public'),
  xt.add_column('vendinfo', 'vend_crmacct_id',     'INTEGER', 'NOT NULL UNIQUE', 'public');

-- Foreign keys and Unique constraints
SELECT 
  xt.add_constraint('custinfo', 'custinfo_crmacct_id_fkey',
                    'FOREIGN KEY (cust_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('custinfo', 'cust_crmacct_id_key', 'UNIQUE (cust_crmacct_id)', 'public'),
  xt.add_constraint('prospect', 'prospect_crmacct_id_fkey',
                    'FOREIGN KEY (prospect_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('prospect', 'prospect_crmacct_id_key', 'UNIQUE (prospect_crmacct_id)', 'public'),
  xt.add_constraint('emp', 'emp_crmacct_id_fkey',
                    'FOREIGN KEY (emp_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('emp', 'emp_crmacct_id_key', 'UNIQUE (emp_crmacct_id)', 'public'),
  xt.add_constraint('salesrep', 'salesrep_crmacct_id_fkey',
                    'FOREIGN KEY (salesrep_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('salesrep', 'salesrep_crmacct_id_key', 'UNIQUE (salesrep_crmacct_id)', 'public'),
  xt.add_constraint('taxauth', 'taxauth_crmacct_id_fkey',
                    'FOREIGN KEY (taxauth_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('taxauth', 'taxauth_crmacct_id_key', 'UNIQUE (taxauth_crmacct_id)', 'public'),
  xt.add_constraint('vendinfo', 'vendinfo_crmacct_id_fkey',
                    'FOREIGN KEY (vend_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('vendinfo', 'vend_crmacct_id_key', 'UNIQUE (vend_crmacct_id)', 'public');

-- Migrate the CRM Account Data
UPDATE custinfo SET cust_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_cust_id=cust_id);
UPDATE prospect SET prospect_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_prospect_id=prospect_id);
UPDATE emp SET emp_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_emp_id=emp_id);
UPDATE salesrep SET salesrep_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_salesrep_id=salesrep_id);
UPDATE taxauth SET taxauth_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_taxauth_id=taxauth_id);
UPDATE vendinfo SET vend_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_vend_id=vend_id);

-- Migrate Prospect Contacts to CRM Contact assignment
INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
SELECT prospect_crmacct_id, prospect_cntct_id, getcrmroleid('Primary')
FROM prospect 
WHERE prospect_crmacct_id IS NOT NULL AND prospect_cntct_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM crmacctcntctass WHERE crmacctcntctass_crmacct_id=prospect_crmacct_id AND crmacctcntctass_cntct_id=prospect_cntct_id);

-- and DROP prospect_cntct column
ALTER TABLE prospect DROP COLUMN IF EXISTS prospect_cntct_id CASCADE;

-- Now set crmacct columns to NOT NULL
ALTER TABLE custinfo ALTER COLUMN cust_crmacct_id SET NOT NULL;
ALTER TABLE prospect ALTER COLUMN prospect_crmacct_id SET NOT NULL;
ALTER TABLE emp ALTER COLUMN emp_crmacct_id SET NOT NULL;
ALTER TABLE salesrep ALTER COLUMN salesrep_crmacct_id SET NOT NULL;
ALTER TABLE taxauth ALTER COLUMN taxauth_crmacct_id SET NOT NULL;
ALTER TABLE vendinfo ALTER COLUMN vend_crmacct_id SET NOT NULL;

-- And finally DROP the deprecated columns
ALTER TABLE crmacct DROP COLUMN IF EXISTS crmacct_cntct_id_1;
ALTER TABLE crmacct DROP COLUMN IF EXISTS crmacct_cntct_id_2;
ALTER TABLE crmacct DROP COLUMN IF EXISTS crmacct_cust_id CASCADE;
ALTER TABLE crmacct DROP COLUMN IF EXISTS crmacct_prospect_id CASCADE;
ALTER TABLE crmacct DROP COLUMN IF EXISTS crmacct_vend_id CASCADE;
ALTER TABLE crmacct DROP COLUMN IF EXISTS crmacct_taxauth_id CASCADE;
ALTER TABLE crmacct DROP COLUMN IF EXISTS crmacct_emp_id CASCADE;
ALTER TABLE crmacct DROP COLUMN IF EXISTS crmacct_salesrep_id CASCADE;

ALTER TABLE cntct DROP COLUMN IF EXISTS cntct_crmacct_id CASCADE;
ALTER TABLE cntct DROP COLUMN IF EXISTS cntct_phone CASCADE;
ALTER TABLE cntct DROP COLUMN IF EXISTS cntct_phone2 CASCADE;
ALTER TABLE cntct DROP COLUMN IF EXISTS cntct_fax CASCADE;


