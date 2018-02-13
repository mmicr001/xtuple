SELECT xt.create_table('cntctphone', 'public');

ALTER TABLE public.cntctphone DISABLE TRIGGER ALL;

SELECT
  xt.add_column('cntctphone', 'cntctphone_id',         'SERIAL',  'NOT NULL',        'public'),
  xt.add_column('cntctphone', 'cntctphone_cntct_id',   'INTEGER', 'NOT NULL',        'public'),
  xt.add_column('cntctphone', 'cntctphone_crmrole_id', 'INTEGER', 'NOT NULL',        'public'),
  xt.add_column('cntctphone', 'cntctphone_phone',      'TEXT',    'NOT NULL',        'public'),
  xt.add_column('cntctphone', 'cntctphone_createdby',    'TEXT', 'NOT NULL DEFAULT geteffectivextuser()', 'public'),
  xt.add_column('cntctphone', 'cntctphone_created',      'TIMESTAMP WITH TIME ZONE', 'NOT NULL DEFAULT now()', 'public'),
  xt.add_column('cntctphone', 'cntctphone_lastupdated',  'TIMESTAMP WITH TIME ZONE', NULL, 'public');

SELECT
  xt.add_constraint('cntctphone', 'cntctphone_pkey', 'PRIMARY KEY (cntctphone_id)', 'public'),
  xt.add_constraint('cntctphone', 'cntctphone_cntct_id_fkey',
                    'FOREIGN KEY (cntctphone_cntct_id) REFERENCES cntct(cntct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('cntctphone', 'cntctphone_crmrole_id_fkey',
                    'FOREIGN KEY (cntctphone_crmrole_id) REFERENCES crmrole(crmrole_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('cntctphone', 'cntctphone_unq',
                    'UNIQUE (cntctphone_cntct_id, cntctphone_crmrole_id, cntctphone_phone)', 'public');


ALTER TABLE public.cntctphone ENABLE TRIGGER ALL;

COMMENT ON TABLE public.cntctphone
  IS 'Contact Phone Information';
COMMENT ON COLUMN public.cntctphone.cntctphone_crmrole_id IS 'Reference to CRM Role';
