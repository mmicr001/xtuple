SELECT xt.create_table('crmacctcntctass', 'public');

ALTER TABLE public."crmacctcntctass" DISABLE TRIGGER ALL;

SELECT
  xt.add_column('crmacctcntctass', 'crmacctcntctass_id',             'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('crmacctcntctass', 'crmacctcntctass_crmacct_id',     'INTEGER', 'NOT NULL', 'public'),
  xt.add_column('crmacctcntctass', 'crmacctcntctass_cntct_id',       'INTEGER', 'NOT NULL', 'public'),
  xt.add_column('crmacctcntctass', 'crmacctcntctass_crmrole_id',     'INTEGER', 'NOT NULL', 'public'),
  xt.add_column('crmacctcntctass', 'crmacctcntctass_active',         'BOOLEAN', 'NOT NULL DEFAULT true', 'public'),
  xt.add_column('crmacctcntctass', 'crmacctcntctass_default',        'BOOLEAN', 'NOT NULL DEFAULT false', 'public'),
  xt.add_column('crmacctcntctass', 'crmacctcntctass_createdby',      'TEXT', 'NOT NULL DEFAULT geteffectivextuser()', 'public'),
  xt.add_column('crmacctcntctass', 'crmacctcntctass_created',        'TIMESTAMP WITH TIME ZONE', 'NOT NULL DEFAULT now()', 'public'),
  xt.add_column('crmacctcntctass', 'crmacctcntctass_lastupdated',    'TIMESTAMP WITH TIME ZONE', null, 'public');

SELECT
  xt.add_constraint('crmacctcntctass', 'crmacctcntctass_pkey', 'PRIMARY KEY (crmacctcntctass_id)', 'public'),
  xt.add_constraint('crmacctcntctass', 'crmacctcntctass_crmacct_fk', 'FOREIGN KEY (crmacctcntctass_crmacct_id)
      REFERENCES public.crmacct (crmacct_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public'),
  xt.add_constraint('crmacctcntctass', 'crmacctcntctass_cntct_fk', 'FOREIGN KEY (crmacctcntctass_cntct_id)
      REFERENCES public.cntct (cntct_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public'),
  xt.add_constraint('crmacctcntctass', 'crmacctcntctass_crmrole_fk', 'FOREIGN KEY (crmacctcntctass_crmrole_id)
      REFERENCES public.crmrole (crmrole_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('crmacctcntctass', 'crmacctcntctass_unq', 'UNIQUE (crmacctcntctass_crmacct_id, 
                                                                       crmacctcntctass_cntct_id, 
                                                                       crmacctcntctass_crmrole_id)', 'public');

ALTER TABLE public."crmacctcntctass" ENABLE TRIGGER ALL;

COMMENT ON TABLE "crmacctcntctass" IS 'Maps Contacts to CRM Accounts';


