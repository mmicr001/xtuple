SELECT xt.create_table('task', 'public');

ALTER TABLE public.task DISABLE TRIGGER ALL;

SELECT
  xt.add_column('task', 'task_id',                  'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('task', 'task_number',                'TEXT', 'NOT NULL', 'public'),
  xt.add_column('task', 'task_name',                  'TEXT', 'NOT NULL', 'public'),
  xt.add_column('task', 'task_descrip',               'TEXT', NULL,       'public'),
  xt.add_column('task', 'task_active',             'BOOLEAN', 'NOT NULL DEFAULT true', 'public'),
  xt.add_column('task', 'task_parent_type',           'TEXT', 'NOT NULL', 'public'),
  xt.add_column('task', 'task_parent_id',          'INTEGER', NULL,       'public'),
  xt.add_column('task', 'task_prj_id',             'INTEGER', NULL,       'public'),
  xt.add_column('task', 'task_status',        'CHARACTER(1)', $$NOT NULL DEFAULT 'N' $$, 'public'),
  xt.add_column('task', 'task_owner_username',        'TEXT', NULL,       'public'),
  xt.add_column('task', 'task_priority_id',  'INTEGER', 'REFERENCES incdtpriority (incdtpriority_id)', 'public'),
  xt.add_column('task', 'task_start_date',            'DATE', NULL,       'public'),
  xt.add_column('task', 'task_due_date',              'DATE', NULL,       'public'),
  xt.add_column('task', 'task_completed_date',        'DATE', NULL,       'public'),
  xt.add_column('task', 'task_hours_budget', 'NUMERIC(18,6)', 'NOT NULL DEFAULT 0.00', 'public'),
  xt.add_column('task', 'task_hours_actual', 'NUMERIC(18,6)', 'NOT NULL DEFAULT 0.00', 'public'),
  xt.add_column('task', 'task_exp_budget',   'NUMERIC(16,4)', 'NOT NULL DEFAULT 0.00', 'public'),
  xt.add_column('task', 'task_exp_actual',   'NUMERIC(16,4)', 'NOT NULL DEFAULT 0.00', 'public'),
  xt.add_column('task', 'task_pct_complete',       'NUMERIC', NULL,       'public'),
  xt.add_column('task', 'task_notes',                 'TEXT', NULL,       'public'),
  xt.add_column('task', 'task_recurring_task_id',  'INTEGER', NULL,       'public'),
  xt.add_column('task', 'task_istemplate',         'BOOLEAN', 'NOT NULL DEFAULT false',   'public'),
  xt.add_column('task', 'task_created',      'TIMESTAMP WITH TIME ZONE', 'DEFAULT now()', 'public'),
  xt.add_column('task', 'task_created_by',      'TEXT', 'DEFAULT geteffectivextuser()', 'public'),
  xt.add_column('task', 'task_lastupdated',  'TIMESTAMP WITH TIME ZONE', NULL, 'public');


SELECT
  xt.add_constraint('task', 'task_pkey', 'PRIMARY KEY (task_id)', 'public'),
  xt.add_constraint('task', 'task_task_parent_id_unq',
                    'UNIQUE (task_parent_type, task_parent_id, task_number)', 'public'),
  xt.add_constraint('task', 'task_task_status_check',
                    $$CHECK (task_status IN ('N', 'D', 'P', 'O', 'C'))$$, 'public'),
  xt.add_constraint('task', 'task_recurring_task_id_fkey',
                    'FOREIGN KEY (task_recurring_task_id)
                     REFERENCES task (task_id) MATCH SIMPLE
                     ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('task', 'task_prj_id_fkey',
                    'FOREIGN KEY (task_prj_id)
                     REFERENCES prj (prj_id) MATCH SIMPLE
                     ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');


ALTER TABLE public.task ENABLE TRIGGER ALL;

COMMENT ON TABLE task IS 'Task information';

COMMENT ON COLUMN task.task_parent_type   IS 'Task Parent CRM type';
COMMENT ON COLUMN task.task_parent_id   IS 'Task Parent CRM entity';
COMMENT ON COLUMN task.task_priority_id   IS 'Task Priority';
COMMENT ON COLUMN task.task_pct_complete  IS 'Task Percent Complete';
COMMENT ON COLUMN task.task_istemplate  IS 'Indicates this task is used as a template';
COMMENT ON COLUMN task.task_prj_id   IS 'Task Project relationship';
