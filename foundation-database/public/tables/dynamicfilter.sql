SELECT xt.create_table('dynamicfilter', 'public');

ALTER TABLE public.dynamicfilter DISABLE TRIGGER ALL;

SELECT
  xt.add_column('dynamicfilter', 'dynamicfilter_id',      'SERIAL', null,       'public'),
  xt.add_column('dynamicfilter', 'dynamicfilter_name',    'TEXT',   'NOT NULL', 'public'),
  xt.add_column('dynamicfilter', 'dynamicfilter_descrip', 'TEXT',   null,       'public'),
  xt.add_column('dynamicfilter', 'dynamicfilter_object',  'TEXT',   'NOT NULL', 'public'),
  xt.add_column('dynamicfilter', 'dynamicfilter_filter',  'TEXT',   'NOT NULL', 'public');

SELECT
  xt.add_constraint('dynamicfilter', 'dynamicfilter_pkey', 'PRIMARY KEY (dynamicfilter_id)', 'public');

ALTER TABLE public.dynamicfilter ENABLE TRIGGER ALL;

COMMENT ON TABLE public.dynamicfilter
  IS 'Dynamic SQL Filter for building CRM Groups';
