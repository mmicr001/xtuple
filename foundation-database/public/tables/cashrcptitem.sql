ALTER TABLE cashrcptitem DISABLE TRIGGER ALL;

SELECT xt.add_column('cashrcptitem','cashrcptitem_cust_id', 'INTEGER', NULL, 'public');

SELECT xt.add_constraint('cashrcptitem', 'cashrcptitem_cust_id_fkey',
                         'FOREIGN KEY (cashrcptitem_cust_id) REFERENCES custinfo(cust_id)', 'public');

UPDATE cashrcptitem
   SET cashrcptitem_cust_id = cashrcpt_cust_id
  FROM cashrcpt
 WHERE cashrcpt_id = cashrcptitem_cashrcpt_id
   AND cashrcpt_cust_id IS NOT NULL
   AND cashrcptitem_cust_id IS NULL;

ALTER TABLE cashrcptitem ENABLE TRIGGER ALL;
