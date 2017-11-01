SELECT xt.create_table('cntctaddrass', 'public');

ALTER TABLE public."cntctaddrass" DISABLE TRIGGER ALL;

SELECT
  xt.add_column('cntctaddrass', 'cntctaddrass_id',             'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('cntctaddrass', 'cntctaddrass_cntct_id',       'INTEGER', 'NOT NULL', 'public'),
  xt.add_column('cntctaddrass', 'cntctaddrass_addr_id',        'INTEGER', 'NOT NULL', 'public'),
  xt.add_column('cntctaddrass', 'cntctaddrass_crmrole_id',     'INTEGER', 'NOT NULL', 'public'),
  xt.add_column('cntctaddrass', 'cntctaddrass_default',        'BOOLEAN', 'NOT NULL DEFAULT false', 'public'),
  xt.add_column('cntctaddrass', 'cntctaddrass_createdby',      'TEXT', 'NOT NULL DEFAULT geteffectivextuser()', 'public'),
  xt.add_column('cntctaddrass', 'cntctaddrass_created',        'TIMESTAMP WITH TIME ZONE', 'NOT NULL DEFAULT now()', 'public'),
  xt.add_column('cntctaddrass', 'cntctaddrass_lastupdated',    'TIMESTAMP WITH TIME ZONE', null, 'public');

SELECT
  xt.add_constraint('cntctaddrass', 'cntctaddrass_pkey', 'PRIMARY KEY (cntctaddrass_id)', 'public'),
  xt.add_constraint('cntctaddrass', 'cntctaddrass_cntct_fk', 'FOREIGN KEY (cntctaddrass_cntct_id)
      REFERENCES public.cntct (cntct_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public'),
  xt.add_constraint('cntctaddrass', 'cntctaddrass_addr_fk', 'FOREIGN KEY (cntctaddrass_addr_id)
      REFERENCES public.addr (addr_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public'),
  xt.add_constraint('cntctaddrass', 'cntctaddrass_crmrole_fk', 'FOREIGN KEY (cntctaddrass_crmrole_id)
      REFERENCES public.crmrole (crmrole_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');


ALTER TABLE public."cntctaddrass" ENABLE TRIGGER ALL;

COMMENT ON TABLE "cntctaddrass" IS 'Maps Addresses to CRM Accounts';


