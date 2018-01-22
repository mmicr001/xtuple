SELECT xt.create_table('cntctgrp', 'public', false, 'groups');

SELECT
  xt.add_constraint('cntctgrp', 'cntctgrp_pkey', 'PRIMARY KEY (groups_id)', 'public'),
  xt.add_constraint('cntctgrp', 'cntctgrp_cntct_name_check', $$CHECK (groups_name <> ''::text)$$, 'public');

COMMENT ON TABLE public.cntctgrp
  IS 'Contact Groups';

