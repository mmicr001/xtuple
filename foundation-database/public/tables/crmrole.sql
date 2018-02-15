SELECT xt.create_table('crmrole', 'public');

ALTER TABLE public."crmrole" DISABLE TRIGGER ALL;

SELECT
  xt.add_column('crmrole', 'crmrole_id',             'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('crmrole', 'crmrole_name',           'TEXT', 'NOT NULL', 'public'),
  xt.add_column('crmrole', 'crmrole_cntct',          'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public'),
  xt.add_column('crmrole', 'crmrole_addr',           'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public'),
  xt.add_column('crmrole', 'crmrole_crmacct',        'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public'),
  xt.add_column('crmrole', 'crmrole_phone',          'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public'),
  xt.add_column('crmrole', 'crmrole_sort',           'INTEGER', 'NOT NULL DEFAULT 99',    'public'),
  xt.add_column('crmrole', 'crmrole_system',         'BOOLEAN', 'NOT NULL DEFAULT false', 'public');

SELECT
  xt.add_constraint('crmrole', 'crmrole_pkey', 'PRIMARY KEY (crmrole_id)', 'public'),
  xt.add_constraint('crmrole', 'crmrole_crmrole_name_check', $$CHECK (crmrole_name <> '')$$, 'public'),
  xt.add_constraint('crmrole', 'crmrole_crmrole_name_key', 'UNIQUE (crmrole_name)', 'public');

ALTER TABLE public."crmrole" ENABLE TRIGGER ALL;

COMMENT ON TABLE "crmrole" IS 'CRM Roles';

COMMENT ON COLUMN public."crmrole".crmrole_addr IS 'Can be used with with target type ADDR';
COMMENT ON COLUMN public."crmrole".crmrole_cntct IS 'Can be used with target type CNTCT';
COMMENT ON COLUMN public."crmrole".crmrole_crmacct IS 'Can be used with target type CRM Account';
COMMENT ON COLUMN public."crmrole".crmrole_phone IS 'Can be used with target type PHONE';


-- Default System information
INSERT INTO crmrole (crmrole_name, crmrole_cntct, crmrole_addr, crmrole_sort, crmrole_system)
SELECT 'Primary', true, true, 10, true
WHERE NOT EXISTS(SELECT 1 FROM crmrole WHERE crmrole_name='Primary');

INSERT INTO crmrole (crmrole_name, crmrole_cntct, crmrole_sort, crmrole_system)
SELECT 'Secondary', true, 20, true
WHERE NOT EXISTS(SELECT 1 FROM crmrole WHERE crmrole_name='Secondary');

INSERT INTO crmrole (crmrole_name, crmrole_cntct, crmrole_addr, crmrole_sort, crmrole_system)
SELECT 'Billing', true, true, 15, true
WHERE NOT EXISTS(SELECT 1 FROM crmrole WHERE crmrole_name='Billing');

INSERT INTO crmrole (crmrole_name, crmrole_cntct, crmrole_addr, crmrole_sort, crmrole_system)
SELECT 'Correspondence', true, true, 25, true
WHERE NOT EXISTS(SELECT 1 FROM crmrole WHERE crmrole_name='Correspondence');

INSERT INTO crmrole (crmrole_name, crmrole_addr, crmrole_sort, crmrole_system)
SELECT 'Ship To', true, 50, true
WHERE NOT EXISTS(SELECT 1 FROM crmrole WHERE crmrole_name='Ship To');

INSERT INTO crmrole (crmrole_name, crmrole_phone, crmrole_sort, crmrole_system)
SELECT 'Home', true, 20, true
WHERE NOT EXISTS(SELECT 1 FROM crmrole WHERE crmrole_name='Home');

INSERT INTO crmrole (crmrole_name, crmrole_phone, crmrole_sort, crmrole_system)
SELECT 'Office', true, 10, true
WHERE NOT EXISTS(SELECT 1 FROM crmrole WHERE crmrole_name='Office');

INSERT INTO crmrole (crmrole_name, crmrole_phone, crmrole_sort, crmrole_system)
SELECT 'Mobile', true, 30, true
WHERE NOT EXISTS(SELECT 1 FROM crmrole WHERE crmrole_name='Mobile');

INSERT INTO crmrole (crmrole_name, crmrole_phone, crmrole_sort, crmrole_system)
SELECT 'Fax', true, 40, true
WHERE NOT EXISTS(SELECT 1 FROM crmrole WHERE crmrole_name='Fax');

INSERT INTO crmrole (crmrole_name, crmrole_cntct, crmrole_addr, crmrole_phone, crmrole_sort, crmrole_system)
SELECT 'Other', true, true, true, 99, true
WHERE NOT EXISTS(SELECT 1 FROM crmrole WHERE crmrole_name='Other');

INSERT INTO crmrole (crmrole_name, crmrole_crmacct, crmrole_sort, crmrole_system)
SELECT 'Competitor', true, 10, true
WHERE NOT EXISTS(SELECT 1 FROM crmrole WHERE crmrole_name='Competitor');

INSERT INTO crmrole (crmrole_name, crmrole_crmacct, crmrole_sort, crmrole_system)
SELECT 'Partner', true, 20, true
WHERE NOT EXISTS(SELECT 1 FROM crmrole WHERE crmrole_name='Partner');
