SELECT xt.create_table('itemtax', 'public');

ALTER TABLE public.itemtax DISABLE TRIGGER ALL;

SELECT xt.add_column('itemtax', 'itemtax_id', 'SERIAL', 'PRIMARY KEY', 'public');
SELECT xt.add_column('itemtax', 'itemtax_item_id', 'INTEGER', 'NOT NULL', 'public');
SELECT xt.add_column('itemtax', 'itemtax_taxtype_id', 'INTEGER', 'NOT NULL', 'public');
SELECT xt.add_column('itemtax', 'itemtax_taxzone_id', 'INTEGER', 'NULL', 'public');
SELECT xt.add_column('itemtax', 'itemtax_default', 'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public');

SELECT xt.add_constraint('itemtax', 'itemtax_itemtax_item_id_fkey', 'FOREIGN KEY (itemtax_item_id) REFERENCES item(item_id)', 'public');
SELECT xt.add_constraint('itemtax', 'itemtax_itemtax_taxtype_id_fkey', 'FOREIGN KEY (itemtax_taxtype_id) REFERENCES taxtype(taxtype_id)', 'public');
SELECT xt.add_constraint('itemtax', 'itemtax_itemtax_taxzone_id_fkey', 'FOREIGN KEY (itemtax_taxzone_id) REFERENCES taxzone(taxzone_id)', 'public');

ALTER TABLE public.itemtax ENABLE TRIGGER ALL;

COMMENT ON TABLE itemtax IS 'This table associates tax types in a specified tax authority for the given item.';
