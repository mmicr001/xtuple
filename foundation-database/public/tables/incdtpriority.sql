SELECT xt.create_table('incdtpriority', 'public');

ALTER TABLE public.incdtpriority DISABLE TRIGGER ALL;

SELECT
  xt.add_column('incdtpriority', 'incdtpriority_id',              'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('incdtpriority', 'incdtpriority_name',              'TEXT', 'NOT NULL', 'public'),
  xt.add_column('incdtpriority', 'incdtpriority_order',          'INTEGER',       NULL, 'public'),
  xt.add_column('incdtpriority', 'incdtpriority_descrip',           'TEXT',       NULL, 'public'),
  xt.add_column('incdtpriority', 'incdtpriority_default',        'BOOLEAN',       NULL, 'public');

SELECT
  xt.add_constraint('incdtpriority', 'incdtpriority_pkey', 'PRIMARY KEY (incdtpriority_id)', 'public'),
  xt.add_constraint('incdtpriority', 'incdtpriority_incdtpriority_name_key', 'UNIQUE (incdtpriority_name)', 'public'),
  xt.add_constraint('incdtpriority', 'incdtpriority_incdtpriority_name_check', $$CHECK (incdtpriority_name <> ''::text)$$, 'public');

ALTER TABLE public.incdtpriority ENABLE TRIGGER ALL;

COMMENT ON TABLE incdtpriority IS 'Priorities';

