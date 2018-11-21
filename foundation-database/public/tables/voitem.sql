SELECT xt.create_table('voitem', 'public');

SELECT xt.add_column('voitem', 'voitem_id', 'SERIAL', 'PRIMARY KEY', 'public'),
       xt.add_column('voitem', 'voitem_vohead_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('voitem', 'voitem_poitem_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('voitem', 'voitem_close', 'BOOLEAN', 'NULL', 'public'),
       xt.add_column('voitem', 'voitem_qty', 'NUMERIC(18,6)', 'NULL', 'public'),
       xt.add_column('voitem', 'voitem_freight', 'NUMERIC(16,4)', 'NOT NULL DEFAULT 0.0', 'public'),
       xt.add_column('voitem', 'voitem_taxtype_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('voitem', 'voitem_tax_exemption', 'TEXT', 'NULL', 'public');

SELECT xt.add_constraint('voitem', 'voitem_voitem_taxtype_id_fkey', 'FOREIGN KEY (voitem_taxtype_id) REFERENCES taxtype(taxtype_id)', 'public');

COMMENT ON TABLE voitem IS 'Voucher Line Item information';
