select xt.create_table('coheadtax', 'public', false, 'taxhist');

ALTER TABLE public.coheadtax DISABLE TRIGGER ALL;

select xt.add_constraint('coheadtax', 'coheadtax_pkey', 'PRIMARY KEY (taxhist_id)', 'public');
select xt.add_constraint('coheadtax', 'coheadtax_taxhist_basis_tax_id_fkey', 'FOREIGN KEY (taxhist_basis_tax_id) REFERENCES tax (tax_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');
select xt.add_constraint('coheadtax', 'coheadtax_taxhist_parent_id_fkey', 'FOREIGN KEY (taxhist_parent_id) REFERENCES cohead (cohead_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public');
select xt.add_constraint('coheadtax', 'coheadtax_taxhist_tax_id_fkey', 'FOREIGN KEY (taxhist_tax_id) REFERENCES tax (tax_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');
select xt.add_constraint('coheadtax', 'coheadtax_taxhist_taxtype_id_fkey', 'FOREIGN KEY (taxhist_taxtype_id) REFERENCES taxtype (taxtype_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');

ALTER TABLE public.coheadtax ENABLE TRIGGER ALL;

COMMENT ON TABLE coheadtax
  IS 'Tax History table for Sales Orders';
