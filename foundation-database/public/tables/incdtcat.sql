SELECT xt.create_table('incdtcat', 'public');

ALTER TABLE public.incdtcat DISABLE TRIGGER ALL;

SELECT
  xt.add_column('incdtcat', 'incdtcat_id',              'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('incdtcat', 'incdtcat_name',              'TEXT', 'NOT NULL', 'public'),
  xt.add_column('incdtcat', 'incdtcat_order',          'INTEGER',       NULL, 'public'),
  xt.add_column('incdtcat', 'incdtcat_descrip',           'TEXT',       NULL, 'public'),
  xt.add_column('incdtcat', 'incdtcat_tasktmpl_id',    'INTEGER',       NULL, 'public'),
  xt.add_column('incdtcat', 'incdtcat_ediprofile_id',  'INTEGER',       NULL, 'public');

SELECT
  xt.add_constraint('incdtcat', 'incdtcat_pkey', 'PRIMARY KEY (incdtcat_id)', 'public'),
  xt.add_constraint('incdtcat', 'incdtcat_incdtcat_name_key', 'UNIQUE (incdtcat_name)', 'public'),
  xt.add_constraint('incdtcat', 'incdtcat_incdtcat_name_check', $$CHECK (incdtcat_name <> ''::text)$$, 'public'),
  xt.add_constraint('incdtcat', 'incdtcat_tasktmpl_id_fkey',
                    'FOREIGN KEY (incdtcat_tasktmpl_id) REFERENCES tasktmpl(tasktmpl_id)', 'public')
 ;

ALTER TABLE public.incdtcat ENABLE TRIGGER ALL;

COMMENT ON TABLE incdtcat IS 'Incident Category';

COMMENT ON COLUMN incdtcat.incdtcat_tasktmpl_id IS 'The default Tasks based on the linked Task Template';
