select xt.create_table('poheadtax', 'public', false, 'taxhist');

ALTER TABLE public.poheadtax DISABLE TRIGGER ALL;

select xt.add_constraint('poheadtax', 'poheadtax_pkey', 'PRIMARY KEY (taxhist_id)', 'public');
select xt.add_constraint('poheadtax', 'poheadtax_taxhist_basis_tax_id_fkey', 'FOREIGN KEY (taxhist_basis_tax_id) REFERENCES tax (tax_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');
select xt.add_constraint('poheadtax', 'poheadtax_taxhist_parent_id_fkey', 'FOREIGN KEY (taxhist_parent_id) REFERENCES pohead (pohead_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public');
select xt.add_constraint('poheadtax', 'poheadtax_taxhist_tax_id_fkey', 'FOREIGN KEY (taxhist_tax_id) REFERENCES tax (tax_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');
select xt.add_constraint('poheadtax', 'poheadtax_taxhist_taxtype_id_fkey', 'FOREIGN KEY (taxhist_taxtype_id) REFERENCES taxtype (taxtype_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');

ALTER TABLE public.poheadtax ENABLE TRIGGER ALL;

COMMENT ON TABLE poheadtax
  IS 'Tax History table for Purchase Orders';
