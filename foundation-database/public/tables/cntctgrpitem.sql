SELECT xt.create_table('cntctgrpitem', 'public', false, 'groupsitem');

SELECT
  xt.add_constraint('cntctgrpitem', 'cntctgrpitem_pkey', 'PRIMARY KEY (groupsitem_id)', 'public'),
  xt.add_constraint('cntctgrpitem', 'cntctgrpitem_cntct_id_fk', 'FOREIGN KEY (groupsitem_reference_id) REFERENCES cntct(cntct_id)', 'public'),
  xt.add_constraint('cntctgrpitem', 'cntctgrpitem_groups_fkey', $$FOREIGN KEY (groupsitem_groups_id) 
                                            REFERENCES public.cntctgrp (groups_id) MATCH SIMPLE
                                            ON UPDATE NO ACTION ON DELETE CASCADE$$, 'public');

COMMENT ON TABLE public.cntctgrpitem
  IS 'Contact Group Item information';
