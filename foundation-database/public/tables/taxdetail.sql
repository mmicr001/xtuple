DO $$
BEGIN
  IF compareVersion(fetchMetricText('ServerVersion'), '5.0.0-alpha') = -1 THEN
    DROP TYPE IF EXISTS taxdetail CASCADE;
  END IF;
END
$$ language plpgsql;

SELECT xt.create_table('taxdetail', 'public');

ALTER TABLE public.taxdetail DISABLE TRIGGER ALL;

SELECT xt.add_column('taxdetail', 'taxdetail_id', 'SERIAL', 'PRIMARY KEY', 'public'),
       xt.add_column('taxdetail', 'taxdetail_taxline_id', 'INTEGER', 'NOT NULL', 'public'),
       xt.add_column('taxdetail', 'taxdetail_taxable', 'NUMERIC', 'NOT NULL DEFAULT 0.0', 'public'),
       xt.add_column('taxdetail', 'taxdetail_tax_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('taxdetail', 'taxdetail_tax_code', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxdetail', 'taxdetail_taxclass_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('taxdetail', 'taxdetail_sequence', 'INTEGER', 'NULL', 'public'),
       xt.add_column('taxdetail', 'taxdetail_basis_tax_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('taxdetail', 'taxdetail_amount', 'NUMERIC', 'NULL', 'public'),
       xt.add_column('taxdetail', 'taxdetail_percent', 'NUMERIC', 'NULL', 'public'),
       xt.add_column('taxdetail', 'taxdetail_tax', 'NUMERIC', 'NOT NULL DEFAULT 0.0', 'public'),
       xt.add_column('taxdetail', 'taxdetail_tax_owed', 'NUMERIC', 'NOT NULL DEFAULT 0.0', 'public'),
       xt.add_column('taxdetail', 'taxdetail_paydate', 'DATE', 'NULL', 'public'),
       xt.add_column('taxdetail', 'taxdetail_tax_paid', 'NUMERIC', 'NULL', 'public'),
       xt.add_column('taxdetail', 'taxdetail_vat', 'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public');

SELECT xt.add_constraint('taxdetail', 'taxdetail_taxline_id_fkey', 'FOREIGN KEY (taxdetail_taxline_id) REFERENCES taxline (taxline_id) ON DELETE CASCADE', 'public'),
       xt.add_constraint('taxdetail', 'taxdetail_tax_id_fkey', 'FOREIGN KEY (taxdetail_tax_id) REFERENCES tax (tax_id)', 'public'),
       xt.add_constraint('taxdetail', 'taxdetail_taxclass_id_fkey', 'FOREIGN KEY (taxdetail_taxclass_id) REFERENCES taxclass (taxclass_id)', 'public'),
       xt.add_constraint('taxdetail', 'taxdetail_basis_tax_id_fkey', 'FOREIGN KEY (taxdetail_basis_tax_id) REFERENCES tax (tax_id)', 'public'),
       xt.add_constraint('taxdetail', 'taxdetail_taxdetail_tax_key', 'UNIQUE (taxdetail_taxline_id, taxdetail_tax_id, taxdetail_tax_code)', 'public');

ALTER TABLE public.taxdetail ENABLE TRIGGER ALL;
