select xt.create_table('voitemtax', 'public', false, 'taxhist');

ALTER TABLE public.voitemtax DISABLE TRIGGER ALL;

select xt.add_constraint('voitemtax', 'voitemtax_pkey', 'PRIMARY KEY (taxhist_id)', 'public');
select xt.add_constraint('voitemtax', 'voitemtax_taxhist_basis_tax_id_fkey', 'FOREIGN KEY (taxhist_basis_tax_id) REFERENCES tax (tax_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');
select xt.add_constraint('voitemtax', 'voitemtax_taxhist_parent_id_fkey', 'FOREIGN KEY (taxhist_parent_id) REFERENCES voitem (voitem_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE', 'public');
select xt.add_constraint('voitemtax', 'voitemtax_taxhist_tax_id_fkey', 'FOREIGN KEY (taxhist_tax_id) REFERENCES tax (tax_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');
select xt.add_constraint('voitemtax', 'voitemtax_taxhist_taxtype_id_fkey', 'FOREIGN KEY (taxhist_taxtype_id) REFERENCES taxtype (taxtype_id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public');

ALTER TABLE public.voitemtax ENABLE TRIGGER ALL;

COMMENT ON TABLE voitemtax
  IS 'Tax History table for Voucher Items';
