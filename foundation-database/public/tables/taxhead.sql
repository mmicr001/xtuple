SELECT xt.create_table('taxhead', 'public');

ALTER TABLE public.taxhead DISABLE TRIGGER ALL;

SELECT xt.add_column('taxhead', 'taxhead_id', 'SERIAL', 'PRIMARY KEY', 'public'),
       xt.add_column('taxhead', 'taxhead_service', 'TEXT', 'NOT NULL DEFAULT ''N''', 'public'),
       xt.add_column('taxhead', 'taxhead_status', 'TEXT', 'NOT NULL DEFAULT ''O''', 'public'),
       xt.add_column('taxhead', 'taxhead_valid', 'BOOLEAN', 'NOT NULL DEFAULT TRUE', 'public'),
       xt.add_column('taxhead', 'taxhead_doc_type', 'TEXT', 'NOT NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_doc_id', 'INTEGER', 'NOT NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_cust_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_exemption_code', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_date', 'DATE', 'NOT NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_orig_doc_type', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_orig_doc_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_orig_date', 'DATE', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_curr_id', 'INTEGER', 'NOT NULL DEFAULT baseCurrId()', 'public'),
       xt.add_column('taxhead', 'taxhead_curr_rate', 'NUMERIC', 'NOT NULL DEFAULT 1.0', 'public'),
       xt.add_column('taxhead', 'taxhead_taxzone_id', 'INTEGER', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_shiptoaddr_line1', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_shiptoaddr_line2', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_shiptoaddr_line3', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_shiptoaddr_city', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_shiptoaddr_region', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_shiptoaddr_postalcode', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_shiptoaddr_country', 'TEXT', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_discount', 'NUMERIC', 'NOT NULL DEFAULT 0.0', 'public'),
       xt.add_column('taxhead', 'taxhead_tax_paid', 'NUMERIC', 'NOT NULL DEFAULT 0.0', 'public'),
       xt.add_column('taxhead', 'taxhead_distdate', 'DATE', 'NULL', 'public'),
       xt.add_column('taxhead', 'taxhead_journalnumber', 'INTEGER', 'NULL', 'public');

SELECT xt.add_constraint('taxhead', 'taxhead_curr_id_fkey', 'FOREIGN KEY (taxhead_curr_id) REFERENCES curr_symbol (curr_id)', 'public'),
       xt.add_constraint('taxhead', 'taxhead_taxzone_id_fkey', 'FOREIGN KEY (taxhead_taxzone_id) REFERENCES taxzone (taxzone_id)', 'public'),
       xt.add_constraint('taxhead', 'taxhead_taxhead_doc_key', 'UNIQUE (taxhead_doc_type, taxhead_doc_id)', 'public'),
       xt.add_constraint('taxhead', 'taxhead_taxhead_service_check', $$CHECK (taxhead_service IN ('N', 'A'))$$, 'public'),
       xt.add_constraint('taxhead', 'taxhead_taxhead_status_check', $$CHECK (taxhead_status IN ('O', 'P', 'V'))$$, 'public'),
       xt.add_constraint('taxhead', 'taxhead_taxhead_status_check', $$CHECK (taxhead_status IN ('O', 'P', 'V'))$$, 'public'),
       xt.add_constraint('taxhead', 'taxhead_taxhead_orig_doc_check', $$CHECK ((taxhead_orig_doc_type IS NULL) = (taxhead_orig_doc_id IS NULL) AND (taxhead_orig_doc_type IS NULL) = (taxhead_orig_date IS NULL))$$, 'public'),
       xt.add_constraint('taxhead', 'taxhead_taxhead_addr_check', $$CHECK ((taxhead_service != 'N') = (taxhead_shiptoaddr_line1 IS NOT NULL OR taxhead_shiptoaddr_line2 IS NOT NULL OR taxhead_shiptoaddr_line3 IS NOT NULL OR taxhead_shiptoaddr_city IS NOT NULL OR taxhead_shiptoaddr_region IS NOT NULL OR taxhead_shiptoaddr_postalcode IS NOT NULL OR taxhead_shiptoaddr_country IS NOT NULL))$$, 'public');

ALTER TABLE public.taxhead ENABLE TRIGGER ALL;
