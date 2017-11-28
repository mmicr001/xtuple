SELECT xt.create_table('cntctphone', 'public');

ALTER TABLE public.cntctphone DISABLE TRIGGER ALL;

SELECT
  xt.add_column('cntctphone', 'cntctphone_id',         'SERIAL',  'NOT NULL',        'public'),
  xt.add_column('cntctphone', 'cntctphone_cntct_id',   'INTEGER', 'NOT NULL',        'public'),
  xt.add_column('cntctphone', 'cntctphone_crmrole_id', 'INTEGER', 'NOT NULL',        'public'),
  xt.add_column('cntctphone', 'cntctphone_phone',      'TEXT',    'NOT NULL',        'public'),
  xt.add_column('cntctphone', 'cntctphone_createdby',    'TEXT', 'NOT NULL DEFAULT geteffectivextuser()', 'public'),
  xt.add_column('cntctphone', 'cntctphone_created',      'TIMESTAMP WITH TIME ZONE', 'NOT NULL DEFAULT now()', 'public'),
  xt.add_column('cntctphone', 'cntctphone_lastupdated',  'TIMESTAMP WITH TIME ZONE', NULL, 'public');

SELECT
  xt.add_constraint('cntctphone', 'cntctphone_pkey', 'PRIMARY KEY (cntctphone_id)', 'public'),
  xt.add_constraint('cntctphone', 'cntctphone_cntct_id_fkey',
                    'FOREIGN KEY (cntctphone_cntct_id) REFERENCES cntct(cntct_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('cntctphone', 'cntctphone_crmrole_id_fkey',
                    'FOREIGN KEY (cntctphone_crmrole_id) REFERENCES crmrole(crmrole_id)
                     MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION', 'public'),
  xt.add_constraint('cntctphone', 'cntctphone_unq',
                    'UNIQUE (cntctphone_cntct_id, cntctphone_crmrole_id, cntctphone_phone)', 'public');


ALTER TABLE public.cntctphone ENABLE TRIGGER ALL;

COMMENT ON TABLE public.cntctphone
  IS 'Contact Phone Information';
COMMENT ON COLUMN public.cntctphone.cntctphone_crmrole_id IS 'Reference to CRM Role';


/* =================================================================================================
 * Migrate Phone Data from Contact to new table
 * ================================================================================================= */
DO $$
BEGIN
-- First check contact phone column still exists
  IF (EXISTS (SELECT 1
              FROM pg_attribute a
              JOIN pg_class c ON a.attrelid=c.oid
              JOIN pg_namespace n ON c.relnamespace=n.oid
              WHERE c.relname = 'cntct'
              AND n.nspname = 'public'
              AND a.attname = 'cntct_phone'
              AND a.attnum > 0)) THEN
  
-- Copy existing contact phone records over to the new table
  INSERT INTO cntctphone (cntctphone_cntct_id, cntctphone_crmrole_id, cntctphone_phone)
    SELECT cntct_id, crmrole_id, cntct_phone
    FROM cntct, crmrole
    WHERE crmrole_name = 'Office'
    AND cntct_phone <> ''
    UNION
    SELECT cntct_id, crmrole_id, cntct_phone2
    FROM cntct, crmrole
    WHERE crmrole_name = 'Mobile'
    AND cntct_phone2 <> ''
    UNION
    SELECT cntct_id, crmrole_id, cntct_fax
    FROM cntct, crmrole
    WHERE crmrole_name = 'Fax'
    AND cntct_fax <> '';

--  Drop the legacy Contact Phone columns
   ALTER TABLE cntct DROP COLUMN IF EXISTS cntct_phone CASCADE, 
                     DROP COLUMN IF EXISTS cntct_phone2 CASCADE,
                     DROP COLUMN IF EXISTS cntct_fax CASCADE;

  END IF;
END;
$$ LANGUAGE plpgsql;
