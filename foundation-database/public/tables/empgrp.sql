-- Migrate empgrp table from standalone to inherited from `groups` base table
-- must run this SQL script prior to running the `empgrpitem` scripts

DO $$
BEGIN

  IF EXISTS (SELECT 1
    FROM information_schema.columns c
    JOIN information_schema.tables t ON c.table_name=t.table_name
    WHERE t.table_name = 'empgrp'
    AND column_name =  'empgrp_id') THEN

    DROP TABLE IF EXISTS tempgrp;
    PERFORM xt.create_table('tempgrp', 'public', false, 'groups');

    ALTER TABLE public.empgrp DROP COLUMN IF EXISTS obj_uuid;

    INSERT INTO tempgrp (groups_id, groups_name, groups_descrip, groups_type)
      SELECT empgrp_id, empgrp_name, empgrp_descrip, 'EMP' 
      FROM empgrp;

    ALTER TABLE public.empgrpitem DROP CONSTRAINT IF EXISTS empgrpitem_empgrpitem_empgrp_id_fkey;
    DROP TABLE empgrp;
    ALTER TABLE tempgrp RENAME TO empgrp;
  END IF;

  PERFORM
    xt.add_constraint('empgrp', 'empgrp_pkey', 'PRIMARY KEY (groups_id)', 'public'),
    xt.add_constraint('empgrp', 'empgrp_groups_name_unq', 'UNIQUE (groups_name)', 'public'),
    xt.add_constraint('empgrp', 'empgrp_groups_name_check', $_$CHECK (groups_name <> ''::text)$_$, 'public');

  ALTER TABLE public.empgrp
     ALTER COLUMN groups_type SET DEFAULT 'EMP';

  COMMENT ON TABLE public.empgrp IS 'Employee Groups';

END; $$;

