CREATE OR REPLACE FUNCTION public.addrmerge(
    pSourceAddrId integer,
    pTargetAddrId integer)
  RETURNS boolean AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _fk		RECORD;
  _coldesc      RECORD;
  _seq  	INTEGER;
  _col		TEXT;

BEGIN
  -- Validate
  IF (pSourceAddrId IS NULL) THEN
    RAISE EXCEPTION 'Source address id can not be null';
  ELSIF (pTargetAddrId IS NULL) THEN
    RAISE EXCEPTION 'Target address id can not be null';
  END IF;
  
  -- Determine where this address is used by analyzing foreign key linkages and update each
  FOR _fk IN
    SELECT pg_namespace.nspname AS schemaname, con.relname AS tablename, conkey AS seq, conrelid AS class_id 
    FROM pg_constraint, pg_class f, pg_class con, pg_namespace
    WHERE confrelid=f.oid
    AND conrelid=con.oid
    AND f.relname = 'addr'
    AND con.relnamespace=pg_namespace.oid
    AND con.relname NOT IN ('addrsel', 'crmacctaddrass')
  LOOP
    -- Validate
    IF (ARRAY_UPPER(_fk.seq,1) > 1) THEN
      RAISE EXCEPTION 'Updates to tables where the address is one of multiple foreign key columns is not supported. Error on Table: %',
        pg_namespace.nspname || '.' || con.relname;
    END IF;
    
    _seq := _fk.seq[1];

    -- Get the specific column name
    SELECT attname INTO _col
    FROM pg_attribute, pg_class
    WHERE ((attrelid=pg_class.oid)
    AND (pg_class.oid=_fk.class_id)
    AND (attnum=_seq));

     -- Merge references
    EXECUTE format('UPDATE %I.%I SET %I=%L
                    WHERE (%I=%L);',
                    _fk.schemaname, _fk.tablename,
                    _col, pTargetAddrId, _col, pSourceAddrId);
         
  END LOOP;

  -- Merge cases with no foreign key
  UPDATE comment
  SET comment_source_id = pTargetAddrId
  WHERE ((comment_source = 'ADDR')
   AND (comment_source_id = pSourceAddrId));

  UPDATE docass
  SET docass_source_id = pTargetAddrId
  WHERE ((docass_source_type = 'ADDR')
   AND (docass_source_id = pSourceAddrId));

  UPDATE docass
  SET docass_target_id = pTargetAddrId
  WHERE ((docass_target_type = 'ADDR')
   AND (docass_target_id = pSourceAddrId));

  UPDATE vendinfo
  SET vend_addr_id = pTargetAddrId
  WHERE (vend_addr_id = pSourceAddrId);

 -- Merge field detail to target
  FOR _coldesc IN SELECT attname, typname
                    FROM pg_attribute
                    JOIN pg_type      ON (atttypid=pg_type.oid)
                    JOIN pg_class     ON (attrelid=pg_class.oid)
                    JOIN pg_namespace ON (relnamespace=pg_namespace.oid)
                   WHERE attnum >= 0
                     AND relname='addr'
                     AND nspname='public'
                     AND attname NOT IN ('addr_id', 'addr_active', 'addr_number', 'obj_uuid',
                     'addr_allowmktg', 'addr_createdby', 'addr_created', 'addr_lastupdated',
                     'addr_lat', 'addr_lon', 'addr_accuracy')
  LOOP

    IF (format('SELECT addrsel_mrg_%I FROM addrsel
                    WHERE (addrsel_addr_id=%L)', 
                    _coldesc.attname, pSourceAddrId)) THEN

      EXECUTE format('UPDATE addr dest SET %I=src.%I
                      FROM addr src
                      WHERE ((dest.addr_id=%L)
                      AND (src.addr_id=%L));',
                      _coldesc.attname, _coldesc.attname,
                      pTargetAddrId, pSourceAddrId);
    END IF;
  END LOOP;

  -- Disposition of source address
  DELETE FROM addr WHERE addr_id = pSourceAddrId;
  DELETE FROM crmacctaddrass WHERE crmacctaddrass_addr_id = pSourceAddrId;
 
  -- Clean up
  DELETE FROM addrsel WHERE (addrsel_addr_id=pSourceAddrId);

  RETURN true;
END;
$$ LANGUAGE plpgsql;

