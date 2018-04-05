-- Migrate custgrp table from standalone to inherited from `groups` base table

DROP TABLE IF EXISTS tempgrpitem;
SELECT xt.create_table('tempgrpitem', 'public', false, 'groupsitem');

ALTER TABLE public.custgrpitem DROP COLUMN IF EXISTS obj_uuid CASCADE;

INSERT INTO tempgrpitem
  SELECT * FROM custgrpitem;

DROP TABLE custgrpitem;
ALTER TABLE tempgrpitem RENAME TO custgrpitem;

SELECT
  xt.add_constraint('custgrpitem', 'custgrpitem_pkey', 'PRIMARY KEY (groupsitem_id)', 'public'),
  xt.add_constraint('custgrpitem', 'custgrpitem_cust_id_fk', 'FOREIGN KEY (groupsitem_reference_id) REFERENCES custinfo(cust_id)', 'public'),
  xt.add_constraint('custgrpitem', 'custgrpitem_groups_fkey', $$FOREIGN KEY (groupsitem_groups_id) 
                                            REFERENCES public.custgrp (groups_id) MATCH SIMPLE
                                            ON UPDATE NO ACTION ON DELETE CASCADE$$, 'public');

COMMENT ON TABLE public.custgrpitem
  IS 'Customer Group Item information';
