SELECT xt.create_table('addrgrpitem', 'public', false, 'groupsitem');

SELECT
  xt.add_constraint('addrgrpitem', 'addrgrpitem_pkey', 'PRIMARY KEY (groupsitem_id)', 'public'),
  xt.add_constraint('addrgrpitem', 'addrgrpitem_addr_id_fk', 'FOREIGN KEY (groupsitem_reference_id) REFERENCES addr(addr_id)', 'public'),
  xt.add_constraint('addrgrpitem', 'addrgrpitem_groups_fkey', $$FOREIGN KEY (groupsitem_groups_id) 
                                            REFERENCES public.addrgrp (groups_id) MATCH SIMPLE
                                            ON UPDATE NO ACTION ON DELETE CASCADE$$, 'public');

COMMENT ON TABLE public.addrgrpitem
  IS 'Address Group Item information';
