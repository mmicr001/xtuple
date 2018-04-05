ALTER SEQUENCE IF EXISTS public.custgrpitem_custgrpitem_id_seq
  RENAME TO groupsitem_groupsitem_id_seq;

SELECT xt.create_table('groupsitem', 'public');

ALTER TABLE public.groupsitem DISABLE TRIGGER ALL;

SELECT
  xt.add_column('groupsitem', 'groupsitem_id', 'INTEGER', $$NOT NULL DEFAULT nextval('groupsitem_groupsitem_id_seq')$$, 'public'),
  xt.add_column('groupsitem', 'groupsitem_groups_id', 'INTEGER', 'NOT NULL', 'public'),
  xt.add_column('groupsitem', 'groupsitem_reference_id', 'INTEGER', 'NOT NULL', 'public');

SELECT
  xt.add_constraint('groupsitem', 'groupsitem_pkey', 'PRIMARY KEY (groupsitem_id)', 'public'),
  xt.add_constraint('groupsitem', 'groupsitem_groups_fkey', $$FOREIGN KEY (groupsitem_groups_id) 
                                            REFERENCES public.groups (groups_id) MATCH SIMPLE
                                            ON UPDATE NO ACTION ON DELETE CASCADE$$, 'public');

ALTER TABLE public.groupsitem ENABLE TRIGGER ALL;

COMMENT ON TABLE public.groupsitem
  IS 'Groups base table item information';
