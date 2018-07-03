SELECT xt.create_table('taxlog', 'public');

SELECT xt.add_column('taxlog', 'taxlog_id', 'SERIAL', 'PRIMARY KEY', 'public');
SELECT xt.add_column('taxlog', 'taxlog_service', 'TEXT', 'NOT NULL', 'public');
SELECT xt.add_column('taxlog', 'taxlog_order_type', 'TEXT', 'NOT NULL', 'public');
SELECT xt.add_column('taxlog', 'taxlog_order_id', 'INTEGER', 'NOT NULL', 'public');
SELECT xt.add_column('taxlog', 'taxlog_type', 'TEXT', 'NOT NULL', 'public');
SELECT xt.add_column('taxlog', 'taxlog_request', 'JSONB', 'NOT NULL', 'public');
SELECT xt.add_column('taxlog', 'taxlog_response', 'JSONB', 'NOT NULL', 'public');
SELECT xt.add_column('taxlog', 'taxlog_start', 'TIMESTAMP WITH TIME ZONE', 'NOT NULL', 'public');
SELECT xt.add_column('taxlog', 'taxlog_time', 'INTEGER', 'NOT NULL', 'public');

SELECT xt.add_constraint('taxlog', 'taxlog_taxlog_service_check', $$CHECK (taxlog_service IN ('A'))$$, 'public');
SELECT xt.add_constraint('taxlog', 'taxlog_taxlog_order_type_check', $$CHECK (taxlog_order_type IN ('Q', 'S', 'COB', 'INV'))$$, 'public');
SELECT xt.add_constraint('taxlog', 'taxlog_taxlog_time_check', 'CHECK (taxlog_time > 0)', 'public');

COMMENT ON TABLE taxlog IS 'Log of tax service requests';
