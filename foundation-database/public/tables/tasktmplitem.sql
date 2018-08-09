SELECT xt.create_table('tasktmplitem', 'public');

ALTER TABLE public.tasktmplitem DISABLE TRIGGER ALL;

SELECT
  xt.add_column('tasktmplitem', 'tasktmplitem_id',                  'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('tasktmplitem', 'tasktmplitem_tasktmpl_id',        'INTEGER', 'NOT NULL', 'public'),
  xt.add_column('tasktmplitem', 'tasktmplitem_task_id',            'INTEGER', 'NOT NULL', 'public');

SELECT
  xt.add_constraint('tasktmplitem', 'tasktmplitem_pkey', 'PRIMARY KEY (tasktmplitem_id)', 'public'),
  xt.add_constraint('tasktmplitem', 'tasktmplitem_tasktmpl_id_fkey',
                    'FOREIGN KEY (tasktmplitem_tasktmpl_id)
                     REFERENCES tasktmpl (tasktmpl_id) MATCH SIMPLE
                     ON UPDATE NO ACTION ON DELETE CASCADE', 'public'),
  xt.add_constraint('tasktmplitem', 'tasktmplitem_task_id_fkey',
                    'FOREIGN KEY (tasktmplitem_task_id)
                     REFERENCES task (task_id) MATCH SIMPLE
                     ON UPDATE NO ACTION ON DELETE CASCADE', 'public'),
  xt.add_constraint('tasktmplitem', 'tasktmplitem_unq',
                    'UNIQUE (tasktmplitem_tasktmpl_id, tasktmplitem_task_id)', 'public');

ALTER TABLE public.tasktmplitem ENABLE TRIGGER ALL;

COMMENT ON TABLE tasktmplitem IS 'Task Template Task assignment';
