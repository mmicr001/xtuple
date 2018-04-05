ALTER SEQUENCE IF EXISTS public.custgrp_custgrp_id_seq
  RENAME TO groups_groups_id_seq;

SELECT xt.create_table('groups', 'public');

ALTER TABLE public.groups DISABLE TRIGGER ALL;

SELECT
  xt.add_column('groups', 'groups_id', 'INTEGER', $$NOT NULL DEFAULT nextval('groups_groups_id_seq')$$, 'public'),
  xt.add_column('groups', 'groups_name', 'TEXT', 'NOT NULL', 'public'),
  xt.add_column('groups', 'groups_descrip', 'TEXT', null, 'public'),
  xt.add_column('groups', 'groups_type', 'TEXT', 'NOT NULL', 'public');

SELECT
  xt.add_constraint('groups', 'groups_pkey', 'PRIMARY KEY (groups_id)', 'public');

ALTER TABLE public.groups ENABLE TRIGGER ALL;

COMMENT ON TABLE public.groups
  IS 'Groups base table Header information';
