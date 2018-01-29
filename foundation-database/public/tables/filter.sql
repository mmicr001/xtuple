SELECT xt.create_table('filter', 'public');

ALTER TABLE public.filter DISABLE TRIGGER ALL;

SELECT
  xt.add_column('filter', 'filter_id',       'SERIAL',  'NOT NULL', 'public'),
  xt.add_column('filter', 'filter_screen',   'TEXT',    'NOT NULL', 'public'),
  xt.add_column('filter', 'filter_value',    'TEXT',    'NOT NULL', 'public'),
  xt.add_column('filter', 'filter_username', 'TEXT',     NULL,      'public'),
  xt.add_column('filter', 'filter_name',     'TEXT',    'NOT NULL', 'public'),
  xt.add_column('filter', 'filter_selected', 'boolean', 'DEFAULT false', 'public'),
  xt.add_column('filter', 'filter_columns',  'TEXT',     NULL,      'public');

SELECT
  xt.add_constraint('filter', 'filter_pkey', 'PRIMARY KEY (filter_id)', 'public');

CREATE INDEX IF NOT EXISTS filter_idx ON filter USING btree (filter_screen, filter_username, filter_name);

ALTER TABLE public.filter ENABLE TRIGGER ALL;

COMMENT ON TABLE filter IS 'Saved display parameter filters';
