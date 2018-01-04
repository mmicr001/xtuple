SELECT xt.create_table('vendaddrinfo', 'public');

ALTER TABLE public.vendaddrinfo DISABLE TRIGGER ALL;

SELECT
  xt.add_column('vendaddrinfo', 'vendaddrinfo_id',         'SERIAL', 'NOT NULL', 'public'),
  xt.add_column('vendaddrinfo', 'vendaddr_vend_id',        'INTEGER',      null, 'public'),
  xt.add_column('vendaddrinfo', 'vendaddr_code',           'TEXT',         null, 'public'),
  xt.add_column('vendaddrinfo', 'vendaddr_name',           'TEXT',         null, 'public'),
  xt.add_column('vendaddrinfo', 'vendaddr_comments',       'TEXT',         null, 'public'),
  xt.add_column('vendaddrinfo', 'vendaddr_cntct_id',       'INTEGER',      null, 'public'),
  xt.add_column('vendaddrinfo', 'vendaddr_addr_id',        'INTEGER',      null, 'public'),
  xt.add_column('vendaddrinfo', 'vendaddr_taxzone_id',     'INTEGER',      null, 'public');

SELECT
  xt.add_constraint('vendaddrinfo', 'vendaddr_pkey', 'PRIMARY KEY (vendaddr_id)', 'public'),
  xt.add_constraint('vendaddrinfo', 'vendaddrinfo_vendaddr_addr_id_fkey', 
                    'FOREIGN KEY (vendaddr_addr_id) REFERENCES public.addr (addr_id) MATCH SIMPLE
                      ON UPDATE NO ACTION ON DELETE NO ACTION,', 'public'),
  xt.add_constraint('vendaddrinfo', 'vendaddrinfo_vendaddr_cntct_id_fkey',
                    'FOREIGN KEY (vendaddr_cntct_id) REFERENCES public.cntct(cntct_id) MATCH SIMPLE
                      ON UPDATE NO ACTION ON DELETE NO ACTION,', 'public'),
  xt.add_constraint('vendaddrinfo', 'vendaddrinfo_vendaddr_taxzone_id_fkey',
                    'FOREIGN KEY (vendaddr_taxzone_id) REFERENCES public.taxzone(taxzone_id) MATCH SIMPLE
                      ON UPDATE NO ACTION ON DELETE NO ACTION,', 'public'),
  xt.add_constraint('vendaddrinfo', 'vendaddr_vend_id_fk', 
                    'FOREIGN KEY (vendaddr_vend_id) REFERENCES vendinfo(vend_id)', 'public');

ALTER TABLE public.vendaddrinfo ENABLE TRIGGER ALL;

COMMENT ON TABLE public.vendaddrinfo
  IS 'Vendor Address information';
