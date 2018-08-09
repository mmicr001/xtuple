-- Migrate custgrp table from standalone to inherited from `groups` base table
-- must run this SQL script prior to running the `cashrcpt` and `custgrpitem` scripts

DO $$
BEGIN
  IF EXISTS (SELECT 1
    FROM information_schema.columns c
    JOIN information_schema.tables t ON c.table_name=t.table_name
    WHERE t.table_name = 'custgrp'
    AND column_name =  'custgrp_id') THEN
    
    DROP TABLE IF EXISTS tempgrp;
    PERFORM xt.create_table('tempgrp', 'public', false, 'groups');

    INSERT INTO tempgrp (groups_id, groups_name, groups_descrip, groups_type)
      SELECT custgrp_id, custgrp_name, custgrp_descrip, 'C' FROM custgrp;

    ALTER TABLE public.cashrcpt DROP CONSTRAINT IF EXISTS fk_cashrcpt_custgrp_id;
    ALTER TABLE public.custgrpitem DROP CONSTRAINT IF EXISTS custgrpitem_custgrp_id_fk;

    DROP TABLE custgrp;
    ALTER TABLE tempgrp RENAME TO custgrp;
  END IF;

  PERFORM
    xt.add_constraint('custgrp', 'custgrp_pkey', 'PRIMARY KEY (groups_id)', 'public'),
    xt.add_constraint('custgrp', 'custgrp_groups_name_check', $_$CHECK (groups_name <> ''::text)$_$, 'public');

  ALTER TABLE public.custgrp
    ALTER COLUMN groups_type SET DEFAULT 'C';

  COMMENT ON TABLE public.custgrp IS 'Customer Groups';
END; $$;
