SELECT xt.create_table('vendtype', 'public');

ALTER TABLE public.vendtype DISABLE TRIGGER ALL;

SELECT
  xt.add_column('vendtype', 'vendtype_id',        'SERIAL',  'NOT NULL', 'public'),
  xt.add_column('vendtype', 'vendtype_code',      'TEXT',    'NOT NULL', 'public'),
  xt.add_column('vendtype', 'vendtype_descrip',   'TEXT',          NULL, 'public'),
  xt.add_column('vendtype', 'vendtype_default',   'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public');

SELECT
  xt.add_constraint('vendtype', 'vendtype_pkey', 'PRIMARY KEY (vendtype_id)', 'public'),
  xt.add_constraint('vendtype', 'vendtype_vendtype_code_key', 'UNIQUE (vendtype_code)', 'public'),
  xt.add_constraint('vendtype', 'vendtype_vendtype_code_check', 'CHECK (vendtype_code <> ''::text)', 'public');

ALTER TABLE public.vendtype ENABLE TRIGGER ALL;

COMMENT ON TABLE vendtype IS 'Vendor Type information';
