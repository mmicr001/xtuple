SELECT xt.create_table('cmhead', 'public');

ALTER TABLE public.cmhead DISABLE TRIGGER ALL;

SELECT xt.add_column('cmhead', 'cmhead_id', 'SERIAL', 'PRIMARY KEY', 'public');
SELECT xt.add_column('cmhead', 'cmhead_number', 'TEXT', 'NOT NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_posted', 'BOOLEAN', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_invcnumber', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_custponumber', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_cust_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_docdate', 'DATE', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_shipto_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_shipto_name', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_shipto_address1', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_shipto_address2', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_shipto_address3', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_shipto_city', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_shipto_state', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_shipto_zipcode', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_salresrep_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_freight', 'NUMERIC(16,4)', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_misc', 'NUMERIC(16,4)', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_comments', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_printed', 'BOOLEAN', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_billtoname', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_billtoaddress1', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_billtoaddress2', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_billtoaddress3', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_billtocity', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_billtostate', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_billtozip', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_hold', 'BOOLEAN', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_commission', 'NUMERIC(8,4)', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_misc_accnt_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_misc_descrip', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_rsncode_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_curr_id', 'INTEGER', 'DEFAULT basecurrid()', 'public');
SELECT xt.add_column('cmhead', 'cmhead_gldistdate', 'DATE', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_billtocountry', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_shipto_country', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_rahead_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_taxzone_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_prj_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_void', 'BOOLEAN', 'DEFAULT FALSE', 'public');
SELECT xt.add_column('cmhead', 'cmhead_saletype_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_shipzone_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_calcfreight', 'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public');
SELECT xt.add_column('cmhead', 'cmhead_shipvia', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_warehous_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cmhead', 'cmhead_freight_taxtype_id', 'INTEGER', 'NOT NULL DEFAULT getFreightTaxtypeId()', 'public');
SELECT xt.add_column('cmhead', 'cmhead_misc_taxtype_id', 'INTEGER', 'NOT NULL DEFAULT getMiscTaxtypeId()', 'public');
SELECT xt.add_column('cmhead', 'cmhead_misc_discount', 'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public');

SELECT xt.add_constraint('cmhead', 'cmhead_cmhead_cust_id_fkey', 'FOREIGN KEY (cmhead_cust_id) REFERENCES custinfo(cust_id)', 'public');
SELECT xt.add_constraint('cmhead', 'cmhead_cmhead_prj_id_fkey', 'FOREIGN KEY (cmhead_prj_id) REFERENCES prj(prj_id)', 'public');
SELECT xt.add_constraint('cmhead', 'cmhead_cmhead_salesrep_id_fkey', 'FOREIGN KEY (cmhead_salesrep_id) REFERENCES salesrep(salesrep_id)', 'public');
SELECT xt.add_constraint('cmhead', 'cmhead_cmhead_saletype_id_fkey', 'FOREIGN KEY (cmhead_saletype_id) REFERENCES saletype(saletype_id)', 'public');
SELECT xt.add_constraint('cmhead', 'cmhead_cmhead_shipzone_id_fkey', 'FOREIGN KEY (cmhead_shipzone_id) REFERENCES shipzone(shipzone_id)', 'public');
SELECT xt.add_constraint('cmhead', 'cmhead_cmhead_taxzone_id_fkey', 'FOREIGN KEY (cmhead_taxzone_id) REFERENCES taxzone(taxzone_id)', 'public');
SELECT xt.add_constraint('cmhead', 'cmhead_to_curr_symbol', 'FOREIGN KEY (cmhead_curr_id) REFERENCES curr_symbol(curr_id)', 'public');
SELECT xt.add_constraint('cmhead', 'cmhead_cmhead_warehous_id_fkey', 'FOREIGN KEY (cmhead_warehous_id) REFERENCES whsinfo(warehous_id)', 'public');
SELECT xt.add_constraint('cmhead', 'cmhead_cmhead_freight_taxtype_id_fkey', 'FOREIGN KEY (cmhead_freight_taxtype_id) REFERENCES taxtype(taxtype_id)', 'public');
SELECT xt.add_constraint('cmhead', 'cmhead_cmhead_misc_taxtype_id_fkey', 'FOREIGN KEY (cmhead_misc_taxtype_id) REFERENCES taxtype(taxtype_id)', 'public');
SELECT xt.add_constraint('cmhead', 'cmhead_cmhead_number_key', 'UNIQUE (cmhead_number)', 'public');
SELECT xt.add_constraint('cmhead', 'cmhead_cmhead_number_check', $$CHECK (cmhead_number != '')$$, 'public');

ALTER TABLE cmhead DROP COLUMN IF EXISTS cmhead_freighttaxtype_id;

ALTER TABLE public.cmhead ENABLE TRIGGER ALL;

COMMENT ON TABLE cmhead IS 'S/O Credit Memo header information';

COMMENT ON COLUMN cmhead.cmhead_saletype_id IS 'Associated sale type for credit memo.';
COMMENT ON COLUMN cmhead.cmhead_shipzone_id IS 'Associated shipping zone for credit memo.';
