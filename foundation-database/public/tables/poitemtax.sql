select xt.create_table('poitemtax', 'public', false, 'taxhist');

ALTER TABLE public.poitemtax DISABLE TRIGGER ALL;

select xt.add_constraint('poitemtax', 'poitemtax_pkey', 'PRIMARY KEY (taxhist_id)', 'public');
select xt.add_constraint('poitemtax', 'poitemtax_taxhist_basis_tax_id_fkey', 'FOREIGN KEY (taxhist_basis_tax_id) REFERENCES tax (tax_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');
select xt.add_constraint('poitemtax', 'poitemtax_taxhist_parent_id_fkey', 'FOREIGN KEY (taxhist_parent_id) REFERENCES poitem (poitem_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public');
select xt.add_constraint('poitemtax', 'poitemtax_taxhist_tax_id_fkey', 'FOREIGN KEY (taxhist_tax_id) REFERENCES tax (tax_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');
select xt.add_constraint('poitemtax', 'poitemtax_taxhist_taxtype_id_fkey', 'FOREIGN KEY (taxhist_taxtype_id) REFERENCES taxtype (taxtype_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');

ALTER TABLE public.poitemtax ENABLE TRIGGER ALL;

COMMENT ON TABLE poitemtax
  IS 'Tax History table for Purchase Order Items';
