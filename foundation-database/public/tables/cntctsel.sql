DROP TABLE IF EXISTS public.cntctsel;

SELECT xt.create_table('cntctsel', 'public');

ALTER TABLE public.cntctsel DISABLE TRIGGER ALL;

SELECT
  xt.add_column('cntctsel', 'cntctsel_cntct_id',            'integer',  'NOT NULL',      'public'),
  xt.add_column('cntctsel', 'cntctsel_target',              'boolean',  null,            'public'), 
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_crmacct_id', 'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_addr_id',    'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_first_name', 'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_last_name',  'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_honorific',  'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_initials',   'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_phones',     'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_email',      'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_webaddr',    'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_notes',      'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_title',      'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_middle',     'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_suffix',     'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_companyname', 'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_email_optin', 'boolean', 'DEFAULT false', 'public'),
  xt.add_column('cntctsel', 'cntctsel_mrg_cntct_owner_username', 'boolean', 'DEFAULT false', 'public');

SELECT
  xt.add_constraint('cntctsel', 'cntctsel_pkey', 'PRIMARY KEY (cntctsel_cntct_id)', 'public'),
  xt.add_constraint('cntctsel', 'cntctsel_cntct_id_fkey',
                    'FOREIGN KEY (cntctsel_cntct_id) REFERENCES public.cntct (cntct_id) 
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public');

ALTER TABLE public.cntctsel ENABLE TRIGGER ALL;

COMMENT ON TABLE public.cntctsel
  IS 'This table records the proposed conditions of a CRM Contact merge. When this merge is performed, 
      the BOOLEAN columns in this table indicate which values in the cntct table will be copied to the target record. 
      Data in this table is temporary and will be removed by a purge.';
COMMENT ON COLUMN public.cntctsel.cntctsel_cntct_id IS 'This is the internal ID of the CRM Contact record the data will come from during the merge.';

