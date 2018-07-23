select xt.create_table('voheadtax', 'public', false, 'taxhist');

ALTER TABLE public.voheadtax DISABLE TRIGGER ALL;

select xt.add_constraint('voheadtax', 'voheadtax_pkey', 'PRIMARY KEY (taxhist_id)', 'public');
select xt.add_constraint('voheadtax', 'voheadtax_taxhist_basis_tax_id_fkey', 'FOREIGN KEY (taxhist_basis_tax_id) REFERENCES tax (tax_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');
select xt.add_constraint('voheadtax', 'voheadtax_taxhist_parent_id_fkey', 'FOREIGN KEY (taxhist_parent_id) REFERENCES vohead (vohead_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public');
select xt.add_constraint('voheadtax', 'voheadtax_taxhist_tax_id_fkey', 'FOREIGN KEY (taxhist_tax_id) REFERENCES tax (tax_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');
select xt.add_constraint('voheadtax', 'voheadtax_taxhist_taxtype_id_fkey', 'FOREIGN KEY (taxhist_taxtype_id) REFERENCES taxtype (taxtype_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');

ALTER TABLE public.voheadtax ENABLE TRIGGER ALL;

COMMENT ON TABLE voheadtax
  IS 'Tax History table for Vouchers';
