DROP TABLE IF EXISTS public.addrsel;

SELECT xt.create_table('addrsel', 'public');

ALTER TABLE public.addrsel DISABLE TRIGGER ALL;

SELECT
  xt.add_column('addrsel', 'addrsel_addr_id',              'integer', 'NOT NULL',      'public'),
  xt.add_column('addrsel', 'addrsel_target',               'boolean', null,            'public'), 
  xt.add_column('addrsel', 'addrsel_mrg_addr_line1',       'boolean', 'DEFAULT false', 'public'),
  xt.add_column('addrsel', 'addrsel_mrg_addr_line2',       'boolean', 'DEFAULT false', 'public'),
  xt.add_column('addrsel', 'addrsel_mrg_addr_line3',       'boolean', 'DEFAULT false', 'public'),
  xt.add_column('addrsel', 'addrsel_mrg_addr_city',        'boolean', 'DEFAULT false', 'public'),
  xt.add_column('addrsel', 'addrsel_mrg_addr_state',       'boolean', 'DEFAULT false', 'public'),
  xt.add_column('addrsel', 'addrsel_mrg_addr_postalcode',  'boolean', 'DEFAULT false', 'public'),
  xt.add_column('addrsel', 'addrsel_mrg_addr_country',     'boolean', 'DEFAULT false', 'public'),
  xt.add_column('addrsel', 'addrsel_mrg_addr_notes',       'boolean', 'DEFAULT false', 'public');

SELECT
  xt.add_constraint('addrsel', 'addrsel_pkey', 'PRIMARY KEY (addrsel_addr_id)', 'public'),
  xt.add_constraint('addrsel', 'addrsel_addr_id_fkey',
                    'FOREIGN KEY (addrsel_addr_id) REFERENCES public.addr (addr_id) 
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public');
  
ALTER TABLE public.addrsel ENABLE TRIGGER ALL;

COMMENT ON TABLE public.crmacctsel
  IS 'This table records the proposed conditions of aa Address merge. When this merge is performed, 
      the BOOLEAN columns in this table indicate which values in the addr table will be copied to the target record.';
COMMENT ON COLUMN public.addrsel.addrsel_addr_id IS 'This is the internal ID of the Address record the data will come from during the merge.';

