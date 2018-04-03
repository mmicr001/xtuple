SELECT xt.create_table('tasktmpl', 'public');

ALTER TABLE public.tasktmpl DISABLE TRIGGER ALL;

SELECT
  xt.add_column('tasktmpl', 'tasktmpl_id',                  'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('tasktmpl', 'tasktmpl_name',                  'TEXT', 'NOT NULL', 'public'),
  xt.add_column('tasktmpl', 'tasktmpl_descrip',               'TEXT', NULL,       'public'),
  xt.add_column('tasktmpl', 'tasktmpl_assignments',         'TEXT[]', NULL,       'public');

SELECT
  xt.add_constraint('tasktmpl', 'tasktmpl_pkey', 'PRIMARY KEY (tasktmpl_id)', 'public'),
  xt.add_constraint('tasktmpl', 'tasktmpl_name_unq',
                    'UNIQUE (tasktmpl_name)', 'public');

ALTER TABLE public.tasktmpl ENABLE TRIGGER ALL;

COMMENT ON TABLE tasktmpl IS 'Task Template';
COMMENT ON COLUMN tasktmpl.tasktmpl_assignments IS 'Documents this template can be assigned to';
