-- Migrate custgrp table from standalone to inherited from `groups` base table
-- must run this SQL script prior to running the `cashrcpt` and `custgrpitem` scripts

DROP TABLE IF EXISTS tempgrp;
SELECT xt.create_table('tempgrp', 'public', false, 'groups');

INSERT INTO tempgrp 
  SELECT custgrp_id, custgrp_name, custgrp_descrip, 'C' FROM custgrp;

ALTER TABLE public.cashrcpt DROP CONSTRAINT IF EXISTS fk_cashrcpt_custgrp_id;
ALTER TABLE public.custgrpitem DROP CONSTRAINT IF EXISTS custgrpitem_custgrp_id_fk;

DROP TABLE custgrp;

ALTER TABLE tempgrp RENAME TO custgrp;

SELECT
  xt.add_constraint('custgrp', 'custgrp_pkey', 'PRIMARY KEY (groups_id)', 'public'),
  xt.add_constraint('custgrp', 'custgrp_groups_name_check', $$CHECK (groups_name <> ''::text)$$, 'public');

ALTER TABLE public.custgrp
   ALTER COLUMN groups_type SET DEFAULT 'C';

COMMENT ON TABLE public.custgrp
  IS 'Customer Groups';

