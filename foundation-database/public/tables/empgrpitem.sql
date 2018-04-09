-- Migrate empgrp table from standalone to inherited from `groups` base table
DO $$
BEGIN

  IF EXISTS (SELECT 1
    FROM information_schema.columns c
    JOIN information_schema.tables t ON c.table_name=t.table_name
    WHERE t.table_name = 'empgrpitem'
    AND column_name =  'empgrpitem_id') 
  THEN

    DROP TABLE IF EXISTS tempgrpitem;
    PERFORM xt.create_table('tempgrpitem', 'public', false, 'groupsitem');

    ALTER TABLE public.empgrpitem DROP COLUMN IF EXISTS obj_uuid CASCADE;

    INSERT INTO tempgrpitem (groupsitem_id, groupsitem_groups_id, groupsitem_reference_id)
      SELECT empgrpitem_id, empgrpitem_empgrp_id,empgrpitem_emp_id
      FROM empgrpitem;

    DROP TABLE empgrpitem;
    ALTER TABLE tempgrpitem RENAME TO empgrpitem;
  END IF;

  PERFORM
    xt.add_constraint('empgrpitem', 'empgrpitem_pkey', 'PRIMARY KEY (groupsitem_id)', 'public'),
    xt.add_constraint('empgrpitem', 'empgrpitem_empgrpitem_emp_id_fkey', 'FOREIGN KEY (groupsitem_reference_id) REFERENCES emp(emp_id)', 'public'),
    xt.add_constraint('empgrpitem', 'empgrpitem_empgrpitem_empgrp_id_fkey', $_$FOREIGN KEY (groupsitem_groups_id) 
                                            REFERENCES public.empgrp (groups_id) MATCH SIMPLE
                                            ON UPDATE NO ACTION ON DELETE CASCADE$_$, 'public');

  COMMENT ON TABLE public.empgrpitem IS 'Employee Group Item information';

END; $$;
