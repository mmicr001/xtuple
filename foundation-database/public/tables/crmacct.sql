SELECT xt.create_table('crmacct', 'public');

ALTER TABLE public.crmacct DISABLE TRIGGER ALL;

SELECT
  xt.add_column('crmacct', 'crmacct_id',             'SERIAL', 'NOT NULL',     'public'),
  xt.add_column('crmacct', 'crmacct_number',           'TEXT', 'NOT NULL',     'public'),
  xt.add_column('crmacct', 'crmacct_name',             'TEXT', NULL,           'public'),
  xt.add_column('crmacct', 'crmacct_active',        'BOOLEAN', 'DEFAULT true', 'public'),
  xt.add_column('crmacct', 'crmacct_type',     'CHARACTER(1)', NULL,      'public'),
  xt.add_column('crmacct', 'crmacct_parent_id',     'INTEGER', NULL,      'public'),
  xt.add_column('crmacct', 'crmacct_notes',            'TEXT', NULL,      'public'),
  xt.add_column('crmacct', 'crmacct_owner_username',   'TEXT', NULL,      'public'),
  xt.add_column('crmacct', 'crmacct_usr_username',     'TEXT', NULL,      'public'),
  xt.add_column('crmacct', 'crmacct_created',     'TIMESTAMP WITH TIME ZONE', NULL, 'public'),
  xt.add_column('crmacct', 'crmacct_lastupdated', 'TIMESTAMP WITH TIME ZONE', NULL, 'public');

SELECT
  xt.add_constraint('crmacct', 'crmacct_pkey', 'PRIMARY KEY (crmacct_id)', 'public'),
  xt.add_constraint('crmacct', 'crmacct_crmacct_number_key', 'UNIQUE (crmacct_number)', 'public'),
  xt.add_constraint('crmacct', 'crmacct_crmacct_number_check',
                    $$CHECK (crmacct_number <> '')$$, 'public'),
  xt.add_constraint('crmacct', 'crmacct_crmacct_type_check',
                    $$CHECK (crmacct_type IN ('I', 'O'))$$, 'public'),
  xt.add_constraint('crmacct', 'crmacct_crmacct_usr_username_check',
                    $$CHECK (btrim(crmacct_usr_username) <> '')$$, 'public'),
  xt.add_constraint('crmacct', 'crmacct_owner_username_check',
                    $$CHECK (btrim(crmacct_owner_username) <> '')$$, 'public'),
  xt.add_constraint('crmacct', 'crmacct_crmacct_parent_id_fkey',
                    'FOREIGN KEY (crmacct_parent_id) REFERENCES crmacct(crmacct_id)', 'public');

-- Version 5.0 data migration
DO $$
BEGIN

  IF EXISTS(SELECT column_name FROM information_schema.columns 
            WHERE table_name='crmacct' and column_name='crmacct_cntct_id_1') THEN

     INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
                           SELECT crmacct_id, crmacct_cntct_id_1, getcrmroleid('Primary')
                             FROM crmacct
                            WHERE EXISTS(SELECT 1 FROM cntct WHERE cntct_id = crmacct_cntct_id_1)
                              AND NOT EXISTS (SELECT 1 FROM crmacctcntctass 
                                               WHERE crmacctcntctass_crmacct_id = crmacct_id 
                                                 AND crmacctcntctass_cntct_id   = crmacct_cntct_id_1);

     INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
                           SELECT crmacct_id, crmacct_cntct_id_2, getcrmroleid('Secondary')
                             FROM crmacct
                            WHERE EXISTS(SELECT 1 FROM cntct WHERE cntct_id = crmacct_cntct_id_2)
                              AND NOT EXISTS (SELECT 1 FROM crmacctcntctass 
                                               WHERE crmacctcntctass_crmacct_id = crmacct_id 
                                                 AND crmacctcntctass_cntct_id   = crmacct_cntct_id_2);

  END IF;

  IF EXISTS(SELECT column_name FROM information_schema.columns 
            WHERE table_name='crmacct' and column_name='crmacct_competitor_id') THEN
    INSERT INTO crmacctrole (crmacctrole_crmacct_id, crmacctrole_crmrole_id)
    SELECT crmacct_id, getcrmroleid('Competitor')
      FROM crmacct 
      WHERE crmacct_competitor_id IS NOT NULL
    UNION
    SELECT crmacct_id, getcrmroleid('Partner')
      FROM crmacct 
      WHERE crmacct_partner_id IS NOT NULL;

  END IF;
END$$;

ALTER TABLE crmacct DROP COLUMN IF EXISTS crmacct_cntct_id_1 CASCADE,
                    DROP COLUMN IF EXISTS crmacct_cntct_id_2 CASCADE,
                    DROP COLUMN IF EXISTS crmacct_cust_id CASCADE,
                    DROP COLUMN IF EXISTS crmacct_prospect_id CASCADE,
                    DROP COLUMN IF EXISTS crmacct_vend_id CASCADE,
                    DROP COLUMN IF EXISTS crmacct_taxauth_id CASCADE,
                    DROP COLUMN IF EXISTS crmacct_emp_id CASCADE,
                    DROP COLUMN IF EXISTS crmacct_competitor_id CASCADE,
                    DROP COLUMN IF EXISTS crmacct_partner_id CASCADE,
                    DROP COLUMN IF EXISTS crmacct_salesrep_id CASCADE;

ALTER TABLE public.crmacct ENABLE TRIGGER ALL;

COMMENT ON TABLE crmacct IS 'CRM Accounts are umbrella records that tie together people and organizations with whom we have business relationships.';

COMMENT ON COLUMN crmacct.crmacct_id IS 'Internal ID of this CRM Account.';
COMMENT ON COLUMN crmacct.crmacct_number IS 'Abbreviated human-readable identifier for this CRM Account.';
COMMENT ON COLUMN crmacct.crmacct_name IS 'Long name of this CRM Account.';
COMMENT ON COLUMN crmacct.crmacct_active IS 'This CRM Account is available for new activity.';
COMMENT ON COLUMN crmacct.crmacct_type IS 'This indicates whether the CRM Account represents an organization or an individual person.';
COMMENT ON COLUMN crmacct.crmacct_parent_id IS 'The internal ID of an (optional) parent CRM Account. For example, if the current CRM Account is a subsidiary of another company, the crmacct_parent_id points to the CRM Account representing that parent company.';
COMMENT ON COLUMN crmacct.crmacct_notes IS 'Free-form comments pertaining to the CRM Account.';
COMMENT ON COLUMN crmacct.crmacct_owner_username IS 'The application User responsible for this CRM Account.';
COMMENT ON COLUMN crmacct.crmacct_usr_username IS 'If this is not null, this CRM Account is an application User.';


