-- Migrate empgrp table from standalone to inherited from `groups` base table
-- must run this SQL script prior to running the `empgrpitem` scripts

DROP TABLE IF EXISTS tempgrp;
SELECT xt.create_table('tempgrp', 'public', false, 'groups');

ALTER TABLE public.empgrp DROP COLUMN IF EXISTS obj_uuid;

INSERT INTO tempgrp 
  SELECT emp_id, emp_name, emp_descrip, 'EMP' FROM empgrp;

ALTER TABLE public.empgrpitem DROP CONSTRAINT IF EXISTS empgrpitem_empgrpitem_empgrp_id_fkey;

DROP TABLE empgrp;

ALTER TABLE tempgrp RENAME TO empgrp;

SELECT
  xt.add_constraint('empgrp', 'empgrp_pkey', 'PRIMARY KEY (groups_id)', 'public'),
  xt.add_constraint('empgrp', 'empgrp_groups_name_unq', 'UNIQUE (groups_name)', 'public'),
  xt.add_constraint('empgrp', 'empgrp_groups_name_check', $$CHECK (groups_name <> ''::text)$$, 'public');

ALTER TABLE public.empgrp
   ALTER COLUMN groups_type SET DEFAULT 'EMP';

COMMENT ON TABLE public.empgrp
  IS 'Employee Groups';

