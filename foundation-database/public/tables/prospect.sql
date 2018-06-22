SELECT xt.create_table('prospect', 'public');

ALTER TABLE public.prospect DISABLE TRIGGER ALL;

SELECT
  xt.add_column('prospect', 'prospect_id',          'INTEGER', $$DEFAULT nextval('cust_cust_id_seq'::regclass) NOT NULL$$, 'public'),
  xt.add_column('prospect', 'prospect_crmacct_id',  'INTEGER', NULL, 'public'),
  xt.add_column('prospect', 'prospect_active',      'BOOLEAN', 'DEFAULT true NOT NULL', 'public'),
  xt.add_column('prospect', 'prospect_number',         'TEXT', 'NOT NULL', 'public'),
  xt.add_column('prospect', 'prospect_name',           'TEXT', 'NOT NULL', 'public'),
  xt.add_column('prospect', 'prospect_comments',          'TEXT', NULL, 'public'),
  xt.add_column('prospect', 'prospect_owner_username',    'TEXT', NULL, 'public'),
  xt.add_column('prospect', 'prospect_assigned_username', 'TEXT', NULL, 'public'),
  xt.add_column('prospect', 'prospect_assigned',     'DATE', NULL, 'public'),
  xt.add_column('prospect', 'prospect_lasttouch',    'DATE', NULL, 'public'),
  xt.add_column('prospect', 'prospect_source_id',   'INTEGER', NULL, 'public'),
  xt.add_column('prospect', 'prospect_salesrep_id', 'INTEGER', NULL, 'public'),
  xt.add_column('prospect', 'prospect_warehous_id', 'INTEGER', NULL, 'public'),
  xt.add_column('prospect', 'prospect_taxzone_id',  'INTEGER', NULL, 'public'),
  xt.add_column('prospect', 'prospect_created',     'TIMESTAMP WITH TIME ZONE', $$DEFAULT now() NOT NULL$$, 'public'),
  xt.add_column('prospect', 'prospect_createdby',   'TEXT', 'NOT NULL DEFAULT geteffectivextuser()', 'public'),
  xt.add_column('prospect', 'prospect_lastupdated', 'TIMESTAMP WITH TIME ZONE', NULL, 'public');

SELECT
  xt.add_constraint('prospect', 'prospect_pkey', 'PRIMARY KEY (prospect_id)', 'public'),
  xt.add_constraint('prospect', 'prospect_prospect_number_check',
                    $$CHECK (prospect_number <> '')$$, 'public'),
  xt.add_constraint('prospect', 'prospect_prospect_number_key',
                    'UNIQUE (prospect_number)', 'public'),
  xt.add_constraint('prospect', 'prospect_crmacct_id_fkey',
                    'FOREIGN KEY (prospect_crmacct_id) REFERENCES crmacct(crmacct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('prospect', 'prospect_crmacct_id_key', 'UNIQUE (prospect_crmacct_id)', 'public'),
  xt.add_constraint('prospect', 'prospect_prospect_salesrep_id_fkey',
                    'FOREIGN KEY (prospect_salesrep_id) REFERENCES salesrep(salesrep_id)', 'public'),
  xt.add_constraint('prospect', 'prospect_prospect_taxzone_id_fkey',
                    'FOREIGN KEY (prospect_taxzone_id) REFERENCES taxzone(taxzone_id)', 'public'),
  xt.add_constraint('prospect', 'prospect_prospect_source_id_fkey',
                    'FOREIGN KEY (prospect_source_id) REFERENCES opsource(opsource_id)', 'public'),
  xt.add_constraint('prospect', 'prospect_prospect_warehous_id_fkey',
                    'FOREIGN KEY (prospect_warehous_id) REFERENCES whsinfo(warehous_id)', 'public');

-- Version 5.0 data migration
DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'crmacct' and column_name = 'crmacct_prospect_id') THEN
    INSERT INTO crmacct (crmacct_number, crmacct_name, crmacct_active, crmacct_type, crmacct_prospect_id)
                  SELECT prospect_number, prospect_name, prospect_active, 'O', prospect_id
                    FROM prospect
                   WHERE prospect_crmacct_id IS NULL
                     AND prospect_number NOT IN (SELECT crmacct_number FROM crmacct);

  END IF;

  UPDATE prospect SET prospect_crmacct_id = crmacct_id
    FROM crmacct
   WHERE prospect_number = crmacct_number
     AND prospect_crmacct_id IS NULL;

  IF EXISTS(SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'prospect' and column_name = 'prospect_cntct_id') THEN
    INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
                          SELECT prospect_crmacct_id, prospect_cntct_id, getcrmroleid('Primary')
                            FROM prospect 
                           WHERE prospect_crmacct_id IS NOT NULL AND prospect_cntct_id IS NOT NULL
                            AND NOT EXISTS (SELECT 1 FROM crmacctcntctass 
                                             WHERE crmacctcntctass_crmacct_id = prospect_crmacct_id 
                                               AND crmacctcntctass_cntct_id   = prospect_cntct_id);
  END IF;
END$$;

ALTER TABLE prospect DROP COLUMN IF EXISTS prospect_cntct_id CASCADE;
ALTER TABLE prospect ALTER COLUMN prospect_crmacct_id SET NOT NULL;
ALTER TABLE public.prospect ENABLE TRIGGER ALL;

COMMENT ON TABLE prospect IS 'Prospect Information';
