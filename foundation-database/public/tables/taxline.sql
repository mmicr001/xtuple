SELECT xt.create_table('taxline', 'public');

ALTER TABLE public.taxline DISABLE TRIGGER ALL;

SELECT xt.add_column('taxline', 'taxline_id', 'SERIAL', 'PRIMARY KEY', 'public'),
       xt.add_column('taxline', 'taxline_taxhead_id', 'INTEGER', 'NOT NULL', 'public'),
       xt.add_column('taxline', 'taxline_line_type', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_line_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_linenumber', 'INTEGER', 'NOT NULL DEFAULT 1', 'public'),
       xt.add_column('taxline', 'taxline_subnumber', 'INTEGER', 'NOT NULL DEFAULT 0', 'public'),
       xt.add_column('taxline', 'taxline_number', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_item_number', 'TEXT', 'NOT NULL DEFAULT ''''', 'public'),
       xt.add_column('taxline', 'taxline_shipfromaddr_line1', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_shipfromaddr_line2', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_shipfromaddr_line3', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_shipfromaddr_city', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_shipfromaddr_region', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_shipfromaddr_postalcode', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_shipfromaddr_country', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_taxtype_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_taxtype_external_code', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_qty', 'NUMERIC', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_amount', 'NUMERIC', 'NULL', 'public'),
       xt.add_column('taxline', 'taxline_extended', 'NUMERIC', 'NULL', 'public');

SELECT xt.add_constraint('taxline', 'taxline_taxhead_id_fkey', 'FOREIGN KEY (taxline_taxhead_id) REFERENCES taxhead (taxhead_id) ON DELETE CASCADE', 'public'),
       xt.add_constraint('taxline', 'taxline_taxtype_id_fkey', 'FOREIGN KEY (taxline_taxtype_id) REFERENCES taxtype (taxtype_id)', 'public'),
       xt.add_constraint('taxline', 'taxline_taxline_line_key', 'UNIQUE (taxline_taxhead_id, taxline_line_type, taxline_line_id, taxline_number)', 'public'),
       xt.add_constraint('taxline', 'taxline_taxline_line_type_check', $$CHECK (taxline_line_type IN ('L', 'F', 'M', 'A'))$$, 'public'),
       xt.add_constraint('taxline', 'taxline_taxline_line_id_check', $$CHECK ((taxline_line_type = 'L') = (taxline_line_id IS NOT NULL))$$, 'public'),
       xt.add_constraint('taxline', 'taxline_taxline_qty_check', $$CHECK ((taxline_line_type = 'L') = (taxline_qty IS NOT NULL))$$, 'public'),
       xt.add_constraint('taxline', 'taxline_taxline_amount_check', $$CHECK ((taxline_line_type = 'L') = (taxline_amount IS NOT NULL))$$, 'public'),
       xt.add_constraint('taxline', 'taxline_taxline_extended_check', $$CHECK ((taxline_line_type = 'A') = (taxline_extended IS NULL))$$, 'public');

ALTER TABLE public.taxline ENABLE TRIGGER ALL;
