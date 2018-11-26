SELECT xt.create_table('cobill', 'public');

SELECT xt.add_column('cobill', 'cobill_id', 'SERIAL', 'PRIMARY KEY', 'public'),
       xt.add_column('cobill', 'cobill_coitem_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('cobill', 'cobill_selectdate', 'TIMESTAMP WITH TIME ZONE', 'NULL', 'public'),
       xt.add_column('cobill', 'cobill_qty', 'NUMERIC(18,6)', 'NULL', 'public'),
       xt.add_column('cobill', 'cobill_invcnum', 'INTEGER', 'NULL', 'public'),
       xt.add_column('cobill', 'cobill_toclose', 'BOOLEAN', 'NULL', 'public'),
       xt.add_column('cobill', 'cobill_cobmisc_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('cobill', 'cobill_select_username', 'TEXT', 'NULL', 'public'),
       xt.add_column('cobill', 'cobill_invcitem_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('cobill', 'cobill_taxtype_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('cobill', 'cobill_tax_exemption', 'TEXT', 'NULL', 'public');

SELECT xt.add_constraint('cobill', 'cobill_cobill_invcitem_id_fkey', 'FOREIGN KEY (cobill_invcitem_id) REFERENCES invcitem(invcitem_id)', 'public'),
       xt.add_constraint('cobill', 'cobill_cobill_taxtype_id_fkey', 'FOREIGN KEY (cobill_taxtype_id) REFERENCES taxtype(taxtype_id)', 'public');

COMMENT ON TABLE cobill IS 'Billing Selection Line Item information';
