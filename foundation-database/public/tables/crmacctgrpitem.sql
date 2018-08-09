SELECT xt.create_table('crmacctgrpitem', 'public', false, 'groupsitem');

SELECT
  xt.add_constraint('crmacctgrpitem', 'crmacctgrpitem_pkey', 'PRIMARY KEY (groupsitem_id)', 'public'),
  xt.add_constraint('crmacctgrpitem', 'crmacctgrpitem_crmacct_id_fk', 'FOREIGN KEY (groupsitem_reference_id) REFERENCES crmacct(crmacct_id)', 'public'),
  xt.add_constraint('crmacctgrpitem', 'crmacctgrpitem_groups_fkey', $$FOREIGN KEY (groupsitem_groups_id) 
                                            REFERENCES public.crmacctgrp (groups_id) MATCH SIMPLE
                                            ON UPDATE NO ACTION ON DELETE CASCADE$$, 'public');

COMMENT ON TABLE public.crmacctgrpitem
  IS 'CRM Account Group Item information';
