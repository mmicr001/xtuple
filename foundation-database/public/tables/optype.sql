SELECT xt.create_table('optype', 'public');

ALTER TABLE public.optype DISABLE TRIGGER ALL;

SELECT
  xt.add_column('optype', 'optype_id',              'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('optype', 'optype_name',              'TEXT', 'NOT NULL', 'public'),
  xt.add_column('optype', 'optype_descrip',             'TEXT',     NULL, 'public'),
  xt.add_column('optype', 'optype_tasktmpl_id',    'INTEGER',       NULL, 'public');

SELECT
  xt.add_constraint('optype', 'optype_pkey', 'PRIMARY KEY (optype_id)', 'public'),
  xt.add_constraint('optype', 'optype_optype_name_key', 'UNIQUE (optype_name)', 'public'),
  xt.add_constraint('optype', 'optype_optype_name_check', $$CHECK (optype_name <> ''::text)$$, 'public'),
  xt.add_constraint('optype', 'optype_tasktmpl_id_fkey',
                    'FOREIGN KEY (optype_tasktmpl_id) REFERENCES tasktmpl(tasktmpl_id)', 'public')
 ;

ALTER TABLE public.optype ENABLE TRIGGER ALL;

COMMENT ON TABLE optype IS 'Opportunity Type';

COMMENT ON COLUMN optype.optype_tasktmpl_id IS 'The default Tasks based on the linked Task Template';
