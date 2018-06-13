select xt.create_table('coitemtax', 'public', false, 'taxhist');

ALTER TABLE public.coitemtax DISABLE TRIGGER ALL;

select xt.add_constraint('coitemtax', 'coitemtax_pkey', 'PRIMARY KEY (taxhist_id)', 'public');
select xt.add_constraint('coitemtax', 'coitemtax_taxhist_basis_tax_id_fkey', 'FOREIGN KEY (taxhist_basis_tax_id) REFERENCES tax (tax_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');
select xt.add_constraint('coitemtax', 'coitemtax_taxhist_parent_id_fkey', 'FOREIGN KEY (taxhist_parent_id) REFERENCES coitem (coitem_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public');
select xt.add_constraint('coitemtax', 'coitemtax_taxhist_tax_id_fkey', 'FOREIGN KEY (taxhist_tax_id) REFERENCES tax (tax_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');
select xt.add_constraint('coitemtax', 'coitemtax_taxhist_taxtype_id_fkey', 'FOREIGN KEY (taxhist_taxtype_id) REFERENCES taxtype (taxtype_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');

ALTER TABLE public.coitemtax ENABLE TRIGGER ALL;

COMMENT ON TABLE coitemtax
  IS 'Tax History table for Sales Order Items';
