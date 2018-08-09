SELECT xt.create_table('ccardaud', 'public');

ALTER TABLE public.ccardaud DISABLE TRIGGER ALL;

SELECT
  xt.add_column('ccardaud', 'ccardaud_id', 'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_id', 'INTEGER', null, 'public'), 
  xt.add_column('ccardaud', 'ccardaud_ccard_seq_old', 'INTEGER', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_seq_new', 'INTEGER', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_cust_id_old', 'INTEGER', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_cust_id_new', 'INTEGER', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_active_old', 'BOOLEAN', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_active_new', 'BOOLEAN', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_name_old', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_name_new', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_address1_old', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_address1_new', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_address2_old', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_address2_new', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_city_old', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_city_new', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_state_old', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_state_new', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_zip_old', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_zip_new', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_country_old', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_country_new', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_number_old', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_number_new', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_debit_old', 'BOOLEAN', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_debit_new', 'BOOLEAN', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_month_expired_old', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_month_expired_new', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_year_expired_old', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_year_expired_new', 'bytea', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_type_old', 'character(1)', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_type_new', 'character(1)', null, 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_last_updated', 'timestamp without time zone', 'NOT NULL DEFAULT now()', 'public'),
  xt.add_column('ccardaud', 'ccardaud_ccard_last_updated_by_username', 'text', 'NOT NULL DEFAULT geteffectivextuser()', 'public');

SELECT
  xt.add_constraint('ccardaud', 'ccardaud_ccard_pkey', 'PRIMARY KEY (ccardaud_id)', 'public'),
  xt.add_constraint('ccardaud', 'ccardaud_ccard_cust_id_old_fk', 
                    'FOREIGN KEY (ccardaud_ccard_cust_id_old) REFERENCES custinfo(cust_id)', 'public'),
  xt.add_constraint('ccardaud', 'ccardaud_ccard_cust_id_new_fk', 
                    'FOREIGN KEY (ccardaud_ccard_cust_id_new) REFERENCES custinfo(cust_id)', 'public');

ALTER TABLE public.ccardaud ENABLE TRIGGER ALL;

COMMENT ON TABLE public.ccardaud
  IS 'Credit Card Information tracking data';
