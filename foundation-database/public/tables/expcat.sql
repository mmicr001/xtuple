SELECT xt.create_table('expcat', 'public');

ALTER TABLE public.expcat DISABLE TRIGGER ALL;

SELECT xt.add_column('expcat', 'expcat_id', 'SERIAL', 'PRIMARY KEY', 'public'),
       xt.add_column('expcat', 'expcat_code', 'TEXT', 'NOT NULL', 'public'),
       xt.add_column('expcat', 'expcat_descrip', 'TEXT', 'NULL', 'public'),
       xt.add_column('expcat', 'expcat_exp_accnt_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('expcat', 'expcat_liability_accnt_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('expcat', 'expcat_active', 'BOOLEAN', 'NULL', 'public'),
       xt.add_column('expcat', 'expcat_purchprice_accnt_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('expcat', 'expcat_freight_accnt_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('expcat', 'expcat_tax_accnt_id', 'INTEGER', 'NULL', 'public');

SELECT xt.add_constraint('expcat', 'expcat_expcat_code_key', 'UNIQUE (expcat_code)', 'public'),
       xt.add_constraint('expcat', 'expcat_expcat_code_check', 'CHECK ((expcat_code <> ''::text))', 'public');

ALTER TABLE public.expcat ENABLE TRIGGER ALL;

COMMENT ON TABLE expcat IS 'Expense Category information';

UPDATE expcat
   SET expcat_tax_accnt_id = expcat_exp_accnt_id;
