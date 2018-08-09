SELECT xt.create_table('crmacctaddrass', 'public');

ALTER TABLE public."crmacctaddrass" DISABLE TRIGGER ALL;

SELECT
  xt.add_column('crmacctaddrass', 'crmacctaddrass_id',             'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('crmacctaddrass', 'crmacctaddrass_crmacct_id',     'INTEGER', 'NOT NULL', 'public'),
  xt.add_column('crmacctaddrass', 'crmacctaddrass_addr_id',        'INTEGER', 'NOT NULL', 'public'),
  xt.add_column('crmacctaddrass', 'crmacctaddrass_crmrole_id',     'INTEGER', 'NOT NULL', 'public'),
  xt.add_column('crmacctaddrass', 'crmacctaddrass_default',        'BOOLEAN', 'NOT NULL DEFAULT false', 'public'),
  xt.add_column('crmacctaddrass', 'crmacctaddrass_createdby',      'TEXT', 'NOT NULL DEFAULT geteffectivextuser()', 'public'),
  xt.add_column('crmacctaddrass', 'crmacctaddrass_created',        'TIMESTAMP WITH TIME ZONE', 'NOT NULL DEFAULT now()', 'public'),
  xt.add_column('crmacctaddrass', 'crmacctaddrass_lastupdated',    'TIMESTAMP WITH TIME ZONE', null, 'public');

SELECT
  xt.add_constraint('crmacctaddrass', 'crmacctaddrass_pkey', 'PRIMARY KEY (crmacctaddrass_id)', 'public'),
  xt.add_constraint('crmacctaddrass', 'crmacctaddrass_crmacct_fk', 'FOREIGN KEY (crmacctaddrass_crmacct_id)
      REFERENCES public.crmacct (crmacct_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public'),
  xt.add_constraint('crmacctaddrass', 'crmacctaddrass_addr_fk', 'FOREIGN KEY (crmacctaddrass_addr_id)
      REFERENCES public.addr (addr_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public'),
  xt.add_constraint('crmacctaddrass', 'crmacctaddrass_crmrole_fk', 'FOREIGN KEY (crmacctaddrass_crmrole_id)
      REFERENCES public.crmrole (crmrole_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('crmacctaddrass', 'crmacctaddrass_unq', 'UNIQUE (crmacctaddrass_crmacct_id, crmacctaddrass_addr_id, crmacctaddrass_crmrole_id)', 'public');

ALTER TABLE public."crmacctaddrass" ENABLE TRIGGER ALL;

COMMENT ON TABLE "crmacctaddrass" IS 'Maps Addresses to CRM Accounts';


