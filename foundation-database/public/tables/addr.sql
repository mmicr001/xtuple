SELECT xt.create_table('addr', 'public');

ALTER TABLE public.addr DISABLE TRIGGER ALL;

SELECT
  xt.add_column('addr', 'addr_id',             'SERIAL',  'NOT NULL',            'public'),
  xt.add_column('addr', 'addr_active',         'BOOLEAN', 'DEFAULT true',        'public'),
  xt.add_column('addr', 'addr_line1',          'TEXT', $$NOT NULL DEFAULT ' '$$, 'public'),
  xt.add_column('addr', 'addr_line2',          'TEXT', $$NOT NULL DEFAULT ' '$$, 'public'),
  xt.add_column('addr', 'addr_line3',          'TEXT', $$NOT NULL DEFAULT ' '$$, 'public'),
  xt.add_column('addr', 'addr_city',           'TEXT', $$NOT NULL DEFAULT ' '$$, 'public'),
  xt.add_column('addr', 'addr_state',          'TEXT', $$NOT NULL DEFAULT ' '$$, 'public'),
  xt.add_column('addr', 'addr_postalcode',     'TEXT', $$NOT NULL DEFAULT ' '$$, 'public'),
  xt.add_column('addr', 'addr_country',        'TEXT', $$NOT NULL DEFAULT ' '$$, 'public'),
  xt.add_column('addr', 'addr_notes',          'TEXT', $$DEFAULT ''$$, 'public'),
  xt.add_column('addr', 'addr_number',         'TEXT', 'NOT NULL', 'public'),
  xt.add_column('addr', 'addr_lat',            'NUMERIC(9,6)', null, 'public'),
  xt.add_column('addr', 'addr_lon',            'NUMERIC(9,6)', null, 'public'),
  xt.add_column('addr', 'addr_accuracy',       'NUMERIC', null, 'public'),
  xt.add_column('addr', 'addr_allowmktg',      'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public'),
  xt.add_column('addr', 'addr_createdby',      'TEXT', 'NOT NULL DEFAULT geteffectivextuser()', 'public'),
  xt.add_column('addr', 'addr_created',      'TIMESTAMP WITH TIME ZONE', 'NOT NULL DEFAULT now()', 'public'),
  xt.add_column('addr', 'addr_lastupdated',  'TIMESTAMP WITH TIME ZONE', NULL, 'public');

SELECT
  xt.add_constraint('addr', 'addr_pkey', 'PRIMARY KEY (addr_id)', 'public'),
  xt.add_constraint('addr', 'addr_addr_number_key', 'UNIQUE (addr_number)', 'public'),
  xt.add_constraint('addr', 'addr_addr_number_check', $$CHECK (addr_number <> ''::TEXT$$, 'public');

ALTER TABLE public.addr ENABLE TRIGGER ALL;

COMMENT ON TABLE public.addr
  IS 'Detailed Address Information';
