SELECT xt.create_table('cntcteml', 'public');

ALTER TABLE public.cntcteml DISABLE TRIGGER ALL;

SELECT
  xt.add_column('cntcteml', 'cntcteml_id',             'SERIAL',  'NOT NULL',            'public'),
  xt.add_column('cntcteml', 'cntcteml_cntct_id',       'INTEGER', 'NOT NULL',            'public'),
  xt.add_column('cntcteml', 'cntcteml_primary',        'BOOLEAN', 'NOT NULL DEFAULT FALSE',            'public'),
  xt.add_column('cntcteml', 'cntcteml_email',          'TEXT',    'NOT NULL',               'public'),
  xt.add_column('cntcteml', 'cntcteml_invalid',      'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public'),
  xt.add_column('cntcteml', 'cntcteml_created',      'TIMESTAMP WITH TIME ZONE', 'NOT NULL DEFAULT now()', 'public'),
  xt.add_column('cntcteml', 'cntcteml_lastupdated',  'TIMESTAMP WITH TIME ZONE', NULL, 'public');

SELECT
  xt.add_constraint('cntcteml', 'cntcteml_pkey', 'PRIMARY KEY (cntcteml_id)', 'public'),
  xt.add_constraint('cntcteml', 'cntcteml_cntcteml_cntct_id_fkey',
                    'FOREIGN KEY (cntcteml_cntct_id) REFERENCES cntct(cntct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public');

ALTER TABLE public.cntcteml ENABLE TRIGGER ALL;

COMMENT ON TABLE public.cntcteml
  IS 'Stores email addresses for contacts';
COMMENT ON COLUMN public.cntcteml.cntcteml_id IS 'Primary key';
COMMENT ON COLUMN public.cntcteml.cntcteml_cntct_id IS 'Reference to contact table';
COMMENT ON COLUMN public.cntcteml.cntcteml_primary IS 'Flags whether this is the primary email address';
COMMENT ON COLUMN public.cntcteml.cntcteml_email IS 'Alternate information';
COMMENT ON COLUMN public.cntcteml.cntcteml_invalid IS 'Email address is marked as invalid';
