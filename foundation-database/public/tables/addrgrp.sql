SELECT xt.create_table('addrgrp', 'public', false, 'groups');

SELECT
  xt.add_constraint('addrgrp', 'addrgrp_pkey', 'PRIMARY KEY (groups_id)', 'public'),
  xt.add_constraint('addrgrp', 'addrgrp_groups_name_check', $$CHECK (groups_name <> ''::text)$$, 'public');

ALTER TABLE public.addrgrp
   ALTER COLUMN groups_type SET DEFAULT 'ADDR';

COMMENT ON TABLE public.addrgrp
  IS 'Address Groups';

