SELECT xt.create_table('cobmisc', 'public');

SELECT xt.add_column('cobmisc', 'cobmisc_id', 'SERIAL', 'PRIMARY KEY', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_cohead_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_shipvia', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_freight', 'NUMERIC(16,4)', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_misc', 'NUMERIC(16,4)', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_payment', 'NUMERIC(16,4)', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_paymentref', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_notes', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_shipdate', 'DATE', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_invcnumber', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_invcdate', 'DATE', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_posted', 'BOOLEAN', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_misc_accnt_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_misc_descrip', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_closeorder', 'BOOLEAN', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_curr_id', 'INTEGER', 'NULL DEFAULT basecurrid()', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_invchead_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_taxzone_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_freight_taxtype_id', 'INTEGER', 'NOT NULL DEFAULT getFreightTaxtypeId()', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_misc_taxtype_id', 'INTEGER', 'NOT NULL DEFAULT getMiscTaxtypeId()', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_misc_discount', 'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public');
SELECT xt.add_column('cobmisc', 'cobmisc_tax_exemption', 'TEXT', 'NULL', 'public');

SELECT xt.add_constraint('cobmisc', 'cobmisc_cobmisc_invchead_id_fkey', 'FOREIGN KEY (cobmisc_invchead_id) REFERENCES invchead(invchead_id)', 'public');
SELECT xt.add_constraint('cobmisc', 'cobmisc_cobmisc_taxzone_id_fkey', 'FOREIGN KEY (cobmisc_taxzone_id) REFERENCES taxzone(taxzone_id)', 'public');
SELECT xt.add_constraint('cobmisc', 'cobmisc_to_curr_symbol', 'FOREIGN KEY (cobmisc_curr_id) REFERENCES curr_symbol(curr_id)', 'public');
SELECT xt.add_constraint('cobmisc', 'cobmisc_cobmisc_freight_taxtype_id_fkey', 'FOREIGN KEY (cobmisc_freight_taxtype_id) REFERENCES taxtype(taxtype_id)', 'public');
SELECT xt.add_constraint('cobmisc', 'cobmisc_cobmisc_misc_taxtype_id_fkey', 'FOREIGN KEY (cobmisc_misc_taxtype_id) REFERENCES taxtype(taxtype_id)', 'public');

ALTER TABLE cobmisc DROP COLUMN IF EXISTS cobmisc_taxtype_id;

COMMENT ON TABLE cobmisc IS 'General information about Billing Selections';
