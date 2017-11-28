SELECT xt.create_table('crmacctsel', 'public');

ALTER TABLE public.cntct DISABLE TRIGGER ALL;

SELECT
  xt.add_column('cntct', 'crmacctsel_src_crmacct_id', 'integer', 'NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_dest_crmacct_id', 'integer', 'NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_active', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_cntct_id_1', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_cntct_id_2', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_competitor_id', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_cust_id', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_emp_id', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_name', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_notes', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_owner_username', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_parent_id', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_partner_id', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_prospect_id', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_salesrep_id', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_taxauth_id', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_type', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_usr_username', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_vend_id', 'boolean', 'DEFAULT false NOT NULL', 'public'),
  xt.add_column('cntct', 'crmacctsel_mrg_crmacct_number', 'boolean', 'DEFAULT false NOT NULL', 'public');

COMMENT ON TABLE crmacctsel IS 'This table records the proposed conditions of a CRM Account merge. When this merge is performed, the BOOLEAN columns in this table indicate which values in the crmacct table will be copied to the target record. Data in this table are temporary and will be removed by a purge.';
COMMENT ON COLUMN crmacctsel.crmacctsel_src_crmacct_id IS 'This is the internal ID of the CRM Account record the data will come from during the merge.';
COMMENT ON COLUMN crmacctsel.crmacctsel_dest_crmacct_id IS 'This is the internal ID of the CRM Account record the data will go to during the merge. If crmacctsel_src_crmacct_id = crmacctsel_dest_crmacct_id, they indicate which crmacct record is the destination of the merge, meaning this is the record that will remain in the database after the merge has been completed and the intermediate data have been purged.';


