SELECT xt.create_table('prjtype', 'public');

ALTER TABLE public.prjtype DISABLE TRIGGER ALL;

SELECT
  xt.add_column('prjtype', 'prjtype_id',              'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('prjtype', 'prjtype_code',              'TEXT', 'NOT NULL', 'public'),
  xt.add_column('prjtype', 'prjtype_descr',             'TEXT', NULL      , 'public'),
  xt.add_column('prjtype', 'prjtype_active',         'BOOLEAN', 'NOT NULL DEFAULT TRUE', 'public'),
  xt.add_column('prjtype', 'prjtype_tasktmpl_id',    'INTEGER', NULL, 'public');

SELECT
  xt.add_constraint('prjtype', 'pk_prjtype', 'PRIMARY KEY (prjtype_id)', 'public'),
  xt.add_constraint('prjtype', 'unq_prjtype_code', 'UNIQUE (prjtype_code)', 'public'),
  xt.add_constraint('prjtype', 'prjtype_tasktmpl_id_fkey',
                    'FOREIGN KEY (prjtype_tasktmpl_id) REFERENCES tasktmpl(tasktmpl_id)', 'public')
 ;

ALTER TABLE public.prjtype ENABLE TRIGGER ALL;

COMMENT ON TABLE prjtype IS 'Project Type';

COMMENT ON COLUMN prjtype.prjtype_tasktmpl_id IS 'The default Project Tasks based on the linked Task Template';
