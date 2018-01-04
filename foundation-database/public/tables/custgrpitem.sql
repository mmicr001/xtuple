SELECT xt.create_table('custgrpitem', 'public');

ALTER TABLE public.custgrpitem DISABLE TRIGGER ALL;

SELECT
  xt.add_column('custgrpitem', 'custgrpitem_id', 'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('custgrpitem', 'custgrpitem_custgrp_id', 'integer', null, 'public'),
  xt.add_column('custgrpitem', 'custgrpitem_cust_id', 'integer', null, 'public');

SELECT
  xt.add_constraint('custgrpitem', 'custgrpitem_pkey', 'PRIMARY KEY (custgrpitem_id)', 'public'),
  xt.add_constraint('custgrpitem', 'custgrpitem_cust_id_fk', 'FOREIGN KEY (custgrpitem_cust_id) REFERENCES custinfo(cust_id)', 'public'),
  xt.add_constraint('custgrpitem', 'custgrpitem_custgrp_id_fk', 'FOREIGN KEY (custgrpitem_custgrp_id) REFERENCES custgrp(custgrp_id)', 'public');

ALTER TABLE public.custgrpitem ENABLE TRIGGER ALL;

COMMENT ON TABLE public.custgrpitem
  IS 'Customer Group Item information';
