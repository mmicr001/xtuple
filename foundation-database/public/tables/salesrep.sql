SELECT xt.create_table('salesrep', 'public');

ALTER TABLE public.salesrep DISABLE TRIGGER ALL;

SELECT
  xt.add_column('salesrep', 'salesrep_id',               'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('salesrep', 'salesrep_crmacct_id',      'INTEGER', NULL,       'public'),
  xt.add_column('salesrep', 'salesrep_active',          'BOOLEAN', NULL,       'public'),
  xt.add_column('salesrep', 'salesrep_number',             'TEXT', 'NOT NULL', 'public'),
  xt.add_column('salesrep', 'salesrep_name',               'TEXT', NULL,       'public'),
  xt.add_column('salesrep', 'salesrep_commission', 'NUMERIC(8,4)', NULL,       'public'),
  xt.add_column('salesrep', 'salesrep_method',     'CHARACTER(1)', NULL,       'public'),
  xt.add_column('salesrep', 'salesrep_created',     'TIMESTAMP WITH TIME ZONE', NULL, 'public'),
  xt.add_column('salesrep', 'salesrep_lastupdated', 'TIMESTAMP WITH TIME ZONE', NULL, 'public');

SELECT
  xt.add_constraint('salesrep', 'salesrep_pkey', 'PRIMARY KEY (salesrep_id)', 'public'),
  xt.add_constraint('salesrep', 'salesrep_salesrep_number_check',
                    $$CHECK (salesrep_number <> '')$$,                        'public'),
  xt.add_constraint('salesrep', 'salesrep_salesrep_number_key',
                    'UNIQUE (salesrep_number)',                               'public'),
  xt.add_constraint('salesrep', 'salesrep_crmacct_id_fkey',
                    'FOREIGN KEY (salesrep_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('salesrep', 'salesrep_crmacct_id_key', 'UNIQUE (salesrep_crmacct_id)', 'public');

-- Version 5.0 data migration
DO $$
BEGIN

  IF EXISTS(SELECT column_name FROM information_schema.columns 
            WHERE table_name='crmacct' and column_name='crmacct_salesrep_id') THEN

     UPDATE salesrep SET salesrep_crmacct_id=(SELECT crmacct_id FROM crmacct WHERE crmacct_salesrep_id=salesrep_id);
  END IF;
END$$;

ALTER TABLE salesrep ALTER COLUMN salesrep_crmacct_id SET NOT NULL;

ALTER TABLE public.salesrep ENABLE TRIGGER ALL;

COMMENT ON TABLE salesrep IS 'Sales Representative information';

ALTER TABLE salesrep DROP COLUMN IF EXISTS salesrep_emp_id CASCADE;
