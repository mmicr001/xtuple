SELECT xt.create_table('cntctgrp', 'public', false, 'groups');

SELECT
  xt.add_constraint('cntctgrp', 'cntctgrp_pkey', 'PRIMARY KEY (groups_id)', 'public'),
  xt.add_constraint('cntctgrp', 'cntctgrp_groups_name_check', $$CHECK (groups_name <> ''::text)$$, 'public');

ALTER TABLE public.cntctgrp
   ALTER COLUMN groups_type SET DEFAULT 'T';

COMMENT ON TABLE public.cntctgrp
  IS 'Contact Groups';

