SELECT xt.create_table('pspctgrpitem', 'public', false, 'groupsitem');


SELECT
  xt.add_constraint('pspctgrpitem', 'pspctgrpitem_pkey', 'PRIMARY KEY (groupsitem_id)', 'public'),
  xt.add_constraint('pspctgrpitem', 'pspctgrpitem_prospect_id_fk', 'FOREIGN KEY (groupsitem_reference_id) REFERENCES prospect(prospect_id)', 'public'),
  xt.add_constraint('pspctgrpitem', 'pspctgrpitem_groups_fkey', $$FOREIGN KEY (groupsitem_groups_id) 
                                            REFERENCES public.pspctgrp (groups_id) MATCH SIMPLE
                                            ON UPDATE NO ACTION ON DELETE CASCADE$$, 'public');

COMMENT ON TABLE public.pspctgrpitem
  IS 'Prospect Group Item information';
