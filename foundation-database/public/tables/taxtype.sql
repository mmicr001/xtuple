SELECT xt.create_table('taxtype', 'public');

SELECT xt.add_column('taxtype', 'taxtype_id', 'SERIAL', 'PRIMARY KEY', 'public');
SELECT xt.add_column('taxtype', 'taxtype_name', 'TEXT', 'NOT NULL', 'public');
SELECT xt.add_column('taxtype', 'taxtype_descrip', 'TEXT', 'NULL', 'public');
SELECT xt.add_column('taxtype', 'taxtype_sys', 'BOOLEAN', 'NOT NULL DEFAULT FALSE', 'public');
SELECT xt.add_column('taxtype', 'taxtype_external_code', 'TEXT', 'NULL', 'public');

SELECT xt.add_constraint('taxtype', 'taxtype_taxtype_name_key', 'UNIQUE (taxtype_name)', 'public');
SELECT xt.add_constraint('taxtype', 'taxtype_taxtype_name_check', $$CHECK (trim(taxtype_name) != '')$$, 'public');

COMMENT ON TABLE taxtype IS 'The list of Tax Types';

UPDATE taxtype
   SET taxtype_descrip = 'Default Freight Tax Type'
 WHERE taxtype_name = 'Freight';

DO $$
BEGIN
  IF (SELECT NOT EXISTS(SELECT 1
                          FROM taxtype
                         WHERE taxtype_name = 'Misc')) THEN
    INSERT INTO taxtype
    (taxtype_name, taxtype_descrip, taxtype_sys)
    VALUES ('Misc', 'Default Misc Tax Type', true);
  END IF;
END
$$ LANGUAGE plpgsql;
