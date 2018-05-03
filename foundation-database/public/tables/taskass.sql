SELECT xt.create_table('taskass', 'public');

ALTER TABLE public.taskass DISABLE TRIGGER ALL;

SELECT
  xt.add_column('taskass', 'taskass_id',             'SERIAL',  'NOT NULL', 'public'),
  xt.add_column('taskass', 'taskass_task_id',        'INTEGER', 'NOT NULL', 'public'),
  xt.add_column('taskass', 'taskass_username',       'TEXT',    'NOT NULL', 'public'),
  xt.add_column('taskass', 'taskass_crmrole_id',     'INTEGER', NULL,       'public'),
  xt.add_column('taskass', 'taskass_assigned_date',  'TIMESTAMP WITH TIME ZONE',    NULL,         'public'),
  xt.add_column('taskass', 'taskass_created',        'TIMESTAMP WITH TIME ZONE', 'DEFAULT now()', 'public'),
  xt.add_column('taskass', 'taskass_created_by',     'TEXT', 'DEFAULT geteffectivextuser()',      'public'),
  xt.add_column('taskass', 'taskass_lastupdated',    'TIMESTAMP WITH TIME ZONE', NULL,            'public');


SELECT
  xt.add_constraint('taskass', 'taskass_pkey', 'PRIMARY KEY (taskass_id)', 'public'),
  xt.add_constraint('taskass', 'taskass_unq', 'UNIQUE (taskass_task_id, taskass_username)', 'public'),
  xt.add_constraint('taskass', 'taskass_task_id_fkey',
                    'FOREIGN KEY (taskass_task_id)
                     REFERENCES task (task_id) MATCH SIMPLE
                     ON UPDATE NO ACTION ON DELETE CASCADE', 'public'),
  xt.add_constraint('taskass', 'taskass_crmrole_id_fkey',
                    'FOREIGN KEY (taskass_crmrole_id)
                     REFERENCES crmrole (crmrole_id) MATCH SIMPLE
                     ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');

ALTER TABLE public.taskass ENABLE TRIGGER ALL;

COMMENT ON TABLE taskass IS 'Task Assignment information';

