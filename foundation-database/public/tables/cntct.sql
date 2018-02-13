SELECT xt.create_table('cntct', 'public');

ALTER TABLE public.cntct DISABLE TRIGGER ALL;

SELECT
  xt.add_column('cntct', 'cntct_id',           'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('cntct', 'cntct_addr_id',     'INTEGER', NULL,       'public'),
  xt.add_column('cntct', 'cntct_first_name',     'TEXT', NULL,       'public'),
  xt.add_column('cntct', 'cntct_last_name',      'TEXT', NULL,       'public'),
  xt.add_column('cntct', 'cntct_honorific',      'TEXT', NULL,       'public'),
  xt.add_column('cntct', 'cntct_initials',       'TEXT', NULL,       'public'),
  xt.add_column('cntct', 'cntct_active',      'BOOLEAN', 'DEFAULT true', 'public'),
  xt.add_column('cntct', 'cntct_email',          'TEXT', NULL,       'public'),
  xt.add_column('cntct', 'cntct_email_optin',    'BOOLEAN', 'NOT NULL DEFAULT TRUE', 'public'),
  xt.add_column('cntct', 'cntct_webaddr',        'TEXT', NULL,       'public'),
  xt.add_column('cntct', 'cntct_notes',          'TEXT', NULL,       'public'),
  xt.add_column('cntct', 'cntct_title',          'TEXT', NULL,       'public'),
  xt.add_column('cntct', 'cntct_number',         'TEXT', 'NOT NULL', 'public'),
  xt.add_column('cntct', 'cntct_middle',         'TEXT', NULL,       'public'),
  xt.add_column('cntct', 'cntct_suffix',         'TEXT', NULL,       'public'),
  xt.add_column('cntct', 'cntct_owner_username', 'TEXT', NULL,       'public'),
  xt.add_column('cntct', 'cntct_name',           'TEXT', NULL,       'public'),
  xt.add_column('cntct', 'cntct_created',      'TIMESTAMP WITH TIME ZONE', NULL, 'public'),
  xt.add_column('cntct', 'cntct_lastupdated',  'TIMESTAMP WITH TIME ZONE', NULL, 'public');

SELECT
  xt.add_constraint('cntct', 'cntct_pkey', 'PRIMARY KEY (cntct_id)', 'public'),
  xt.add_constraint('cntct', 'cntct_cntct_number_key', 'UNIQUE (cntct_number)', 'public'),
  xt.add_constraint('cntct', 'cntct_cntct_addr_id_fkey',
                    'FOREIGN KEY (cntct_addr_id) REFERENCES addr(addr_id)', 'public');

-- Version 5.0 data migration
DO $$
BEGIN

  IF EXISTS(SELECT column_name FROM information_schema.columns 
            WHERE table_name='cntct' and column_name='cntct_crmacct_id') THEN

     INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
     SELECT cntct_crmacct_id, cntct_id, getcrmroleid('Other')
     FROM cntct WHERE cntct_crmacct_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM crmacctcntctass 
                     WHERE crmacctcntctass_crmacct_id=cntct_crmacct_id 
                     AND crmacctcntctass_cntct_id=cntct_id);
  END IF;

  IF EXISTS(SELECT column_name FROM information_schema.columns 
            WHERE table_name='cntct' and column_name='cntct_phone') THEN
-- Copy existing contact phone records over to the new table
     INSERT INTO cntctphone (cntctphone_cntct_id, cntctphone_crmrole_id, cntctphone_phone)
     SELECT cntct_id, crmrole_id, cntct_phone
       FROM cntct, crmrole
       WHERE crmrole_name = 'Office'
       AND cntct_phone <> ''
     UNION
     SELECT cntct_id, crmrole_id, cntct_phone2
       FROM cntct, crmrole
       WHERE crmrole_name = 'Mobile'
      AND cntct_phone2 <> ''
     UNION
      SELECT cntct_id, crmrole_id, cntct_fax
      FROM cntct, crmrole
      WHERE crmrole_name = 'Fax'
      AND cntct_fax <> '';
  END IF;
END$$;

ALTER TABLE cntct DROP COLUMN IF EXISTS cntct_crmacct_id CASCADE,
                  DROP COLUMN IF EXISTS cntct_phone CASCADE, 
                  DROP COLUMN IF EXISTS cntct_phone2 CASCADE,
                  DROP COLUMN IF EXISTS cntct_fax CASCADE;

ALTER TABLE public.cntct ENABLE TRIGGER ALL;

COMMENT ON TABLE cntct IS 'Contact - information on how to reach a living person';
COMMENT ON COLUMN public.cntct.cntct_email_optin IS 'Contact email address opt in/out';
