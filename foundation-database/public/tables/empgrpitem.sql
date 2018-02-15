-- Migrate empgrp table from standalone to inherited from `groups` base table

DROP TABLE IF EXISTS tempgrpitem;
SELECT xt.create_table('tempgrpitem', 'public', false, 'groupsitem');

ALTER TABLE public.empgrpitem DROP COLUMN IF EXISTS obj_uuid CASCADE;

INSERT INTO tempgrpitem
  SELECT * FROM empgrpitem;

DROP TABLE empgrpitem;
ALTER TABLE tempgrpitem RENAME TO empgrpitem;

SELECT
  xt.add_constraint('empgrpitem', 'empgrpitem_pkey', 'PRIMARY KEY (groupsitem_id)', 'public'),
  xt.add_constraint('empgrpitem', 'empgrpitem_empgrpitem_emp_id_fkey', 'FOREIGN KEY (groupsitem_reference_id) REFERENCES emp(emp_id)', 'public'),
  xt.add_constraint('empgrpitem', 'empgrpitem_empgrpitem_empgrp_id_fkey', $$FOREIGN KEY (groupsitem_groups_id) 
                                            REFERENCES public.empgrp (groups_id) MATCH SIMPLE
                                            ON UPDATE NO ACTION ON DELETE CASCADE$$, 'public');

COMMENT ON TABLE public.empgrpitem
  IS 'Employee Group Item information';
