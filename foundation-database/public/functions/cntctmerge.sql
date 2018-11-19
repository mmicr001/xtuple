CREATE OR REPLACE FUNCTION cntctmerge(integer, integer, boolean) RETURNS boolean AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pSourceCntctId ALIAS FOR $1;
  pTargetCntctId ALIAS FOR $2;
  pPurge ALIAS FOR $3;
  _fk		RECORD;
  _pk   	RECORD;
  _coldesc      RECORD;
  _mrgcol       BOOLEAN;
  _seq  	INTEGER;
  _col		TEXT;
  _pkcol  	TEXT;
  _qry  	TEXT;
  _colname      TEXT;
  _multi	BOOLEAN;
  _created      TIMESTAMP WITH TIME ZONE;

BEGIN
  -- Validate
  IF (pSourceCntctId IS NULL) THEN
    RAISE EXCEPTION 'Source contact id can not be null';
  ELSIF (pTargetCntctId IS NULL) THEN
    RAISE EXCEPTION 'Target contact id can not be null';
  ELSIF (pPurge IS NULL) THEN
    RAISE EXCEPTION 'Purge flag can not be null';
  END IF;
  
  -- Determine where this contact is used by analyzing foreign key linkages and update each
  FOR _fk IN
    SELECT pg_namespace.nspname AS schemaname, con.relname AS tablename, conkey AS seq, conrelid AS class_id 
    FROM pg_constraint, pg_class f, pg_class con, pg_namespace
    WHERE confrelid=f.oid
    AND conrelid=con.oid
    AND f.relname = 'cntct'
    AND con.relnamespace=pg_namespace.oid
    AND con.relname NOT IN ('cntctsel', 'cntctmrgd', 'mrghist','trgthist', 'crmacctcntctass')
  LOOP
    -- Validate
    IF (ARRAY_UPPER(_fk.seq,1) > 1) THEN
      RAISE EXCEPTION 'Updates to tables where the contact is one of multiple foreign key columns is not supported. Error on Table: %',
        pg_namespace.nspname || '.' || con.relname;
    END IF;
    
    _seq := _fk.seq[1];

    -- Get the specific column name
    SELECT attname INTO _col
    FROM pg_attribute, pg_class
    WHERE ((attrelid=pg_class.oid)
    AND (pg_class.oid=_fk.class_id)
    AND (attnum=_seq));

    IF (NOT pPurge) THEN
    -- Cache what we're going to do so we can restore if need be.
    -- Start by determining the primary key column for this table.
      _multi := false;
      _qry := format('SELECT pg_attribute.attname AS key
               FROM pg_attribute, pg_class 
               WHERE pg_class.relnamespace = (
                 SELECT oid 
                 FROM pg_namespace 
                 WHERE pg_namespace.nspname = %L) 
                AND  pg_class.oid IN (
                 SELECT indexrelid 
                 FROM pg_index 
                 WHERE indisprimary = true 
                  AND indrelid IN (
                    SELECT oid 
                    FROM pg_class 
                    WHERE lower(relname) = %L)) 
                AND pg_attribute.attrelid = pg_class.oid 
                AND pg_attribute.attisdropped = false 
               ORDER BY pg_attribute.attnum;', _fk.schemaname, _fk.tablename);

      FOR _pk IN 
        EXECUTE _qry
      LOOP
        IF (_multi) THEN
          RAISE EXCEPTION 'Reference tables with composite primary keys not supported.  Try the merge and purge option.';
        END IF;
        _pkcol := _pk.key;
        _multi := true;
      END LOOP;

      -- Gather and store the history
      _qry := format($f$INSERT INTO mrghist 
                      SELECT %s, '%s.%s', '%s', %s, '%s'
                      FROM %I.%I
                      WHERE ( %I = %L);$f$,
                      pSourceCntctId, _fk.schemaname, _fk.tablename,
                      _pkcol, _pkcol, _col,
                      _fk.schemaname, _fk.tablename,
                      _col, pSourceCntctId);    
      EXECUTE _qry;
      
    END IF;

    -- Merge references
    _qry := format('UPDATE %I.%I SET %I=%L
                    WHERE (%I=%L);',
                    _fk.schemaname, _fk.tablename,
                    _col, pTargetCntctId, _col, pSourceCntctId);
    EXECUTE _qry;
         
  END LOOP;

  -- Merge cases with no foreign key
  IF (NOT pPurge) THEN
    INSERT INTO mrghist 
    SELECT pSourceCntctId,
      'comment',
      'comment_id', 
      comment_id,
      'comment_source_id'
    FROM comment
    WHERE ((comment_source_id= pSourceCntctId)
    AND (comment_source='T'));

    INSERT INTO mrghist 
    SELECT pSourceCntctId,
      'docass',
      'docass_id', 
      docass_id,
      'docass_source_id'
    FROM docass
    WHERE ((docass_source_id= pSourceCntctId)
    AND (docass_source_type='T'));

    INSERT INTO mrghist 
    SELECT pSourceCntctId,
      'docass',
      'docass_id', 
      docass_id,
      'docass_target_id'
    FROM docass
    WHERE ((docass_target_id= pSourceCntctId)
    AND (docass_target_type='T'));

    INSERT INTO mrghist 
    SELECT pSourceCntctId,
      'vendinfo',
      'vend_id', 
      vend_id,
      'vend_cntct1_id'
    FROM vendinfo
    WHERE (vend_cntct1_id=pSourceCntctId);

    INSERT INTO mrghist 
    SELECT pSourceCntctId,
      'vendinfo',
      'vend_id', 
      vend_id,
      'vend_cntct2_id'
    FROM vendinfo
    WHERE (vend_cntct2_id=pSourceCntctId);

    IF (fetchMetricBool('EnableBatchManager') AND packageIsEnabled('xtbatch')) THEN
      INSERT INTO mrghist 
      SELECT pSourceCntctId,
      'xtbatch.emlassc',
      'emlassc_id', 
      emlassc_id,
      'emlassc_assc_id'
      FROM xtbatch.emlassc
      WHERE ((emlassc_assc_id= pSourceCntctId)
      AND (emlassc_type='T'));
    END IF;
  END IF;

  UPDATE comment
  SET comment_source_id = pTargetCntctId
  WHERE ((comment_source = 'T')
   AND (comment_source_id = pSourceCntctId));

  UPDATE docass
  SET docass_source_id = pTargetCntctId
  WHERE ((docass_source_type = 'T')
   AND (docass_source_id = pSourceCntctId));

  UPDATE docass
  SET docass_target_id = pTargetCntctId
  WHERE ((docass_target_type = 'T')
   AND (docass_target_id = pSourceCntctId));

  UPDATE vendinfo
  SET vend_cntct1_id = pTargetCntctId
  WHERE (vend_cntct1_id = pSourceCntctId);

  UPDATE vendinfo
  SET vend_cntct2_id = pTargetCntctId
  WHERE (vend_cntct2_id = pSourceCntctId);

  IF (fetchMetricBool('EnableBatchManager') AND packageIsEnabled('xtbatch')) THEN
    UPDATE xtbatch.emlassc
    SET emlassc_assc_id = pTargetCntctId
    WHERE ((emlassc_type = 'T')
     AND (emlassc_assc_id = pSourceCntctId));
  END IF;

  IF (NOT pPurge) THEN
  -- Record that this has been merged if not already
    IF (SELECT (COUNT(cntctmrgd_cntct_id) = 0) 
        FROM cntctmrgd
        WHERE (cntctmrgd_cntct_id=pSourceCntctId)) THEN
      INSERT INTO cntctmrgd (cntctmrgd_cntct_id, cntctmrgd_error) VALUES (pSourceCntctId,false);
    END IF;
  END IF;

 -- TODO Switch the following logic to also use changefkeypointers().  That requires a rewrite
 --      of the undo functionality but will also deprecate trgthist table
 -- Merge field detail to target
  FOR _coldesc IN SELECT attname, typname
                    FROM pg_attribute
                    JOIN pg_type      ON (atttypid=pg_type.oid)
                    JOIN pg_class     ON (attrelid=pg_class.oid)
                    JOIN pg_namespace ON (relnamespace=pg_namespace.oid)
                   WHERE (attnum >= 0)
                     AND (relname='cntct')
                     AND (nspname='public')
                     AND (attname NOT IN ('cntct_id', 'cntct_number', 'cntct_name', 
                                  'cntct_created', 'cntct_lastupdated', 'cntct_active', 'obj_uuid'))
  LOOP

    -- if we're supposed to merge this column at all
    EXECUTE format('SELECT cntctsel_mrg_%I FROM cntctsel
                    WHERE (cntctsel_cntct_id=%L)', 
                    _coldesc.attname, pSourceCntctId)
            INTO _mrgcol;

    IF (_mrgcol) THEN
      _colname := _coldesc.attname;

      IF (NOT pPurge) THEN
        _qry = format('INSERT INTO trgthist
                        SELECT %s, %s, %L, ''%s::%s''
                        FROM cntct WHERE (cntct_id=%s)',
                        pSourceCntctId, pTargetCntctId,
                        _colname, _colname, _coldesc.typname,
                        pTargetCntctId);
        EXECUTE _qry;
      END IF;

      EXECUTE format('UPDATE cntct dest SET %I=src.%I
                      FROM cntct src
                      WHERE ((dest.cntct_id=%L)
                      AND (src.cntct_id=%L));',
                      _colname, _colname,
                      pTargetCntctId, pSourceCntctId);
    END IF;
  END LOOP;

  -- Separately check for CRM Acct merge criteria
  -- TODO there is no history saved for these combinations
  SELECT cntctsel_mrg_cntct_crmacct_id INTO _mrgcol
  FROM cntctsel
   WHERE (cntctsel_cntct_id=pSourceCntctId);

  IF (_mrgcol) THEN
    INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
    SELECT crmacctcntctass_crmacct_id, pTargetCntctId, crmacctcntctass_crmrole_id
    FROM crmacctcntctass WHERE crmacctcntctass_cntct_id=pSourceCntctId
    ON CONFLICT (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
    DO NOTHING;
  END IF;

  -- Separately check for Contact Phones merge criteria
  -- TODO there is no history saved for these combinations
  SELECT cntctsel_mrg_cntct_phones INTO _coldesc
  FROM cntctsel
   WHERE (cntctsel_cntct_id=pSourceCntctId);

  IF (_mrgcol) THEN
    INSERT INTO cntctphone (cntctphone_cntct_id, cntctphone_crmrole_id, cntctphone_phone)
    SELECT pTargetCntctId, cntctphone_crmrole_id, cntctphone_phone
    FROM cntctphone WHERE cntctphone_cntct_id=pSourceCntctId
    ON CONFLICT (cntctphone_cntct_id, cntctphone_crmrole_id, cntctphone_phone)
    DO NOTHING;
  END IF;

  -- Use oldest create date
  SELECT MIN(cntct_created) INTO _created
    FROM cntct
   WHERE cntct_id IN (pSourceCntctId, pTargetCntctId);

  UPDATE cntct
     SET cntct_created = _created
   WHERE cntct_id = pTargetCntctId;

  -- Disposition source contact
  IF (pPurge) THEN
    DELETE FROM cntct WHERE cntct_id = pSourceCntctId;
    DELETE FROM cntctphone WHERE cntctphone_cntct_id = pSourceCntctId;
    DELETE FROM crmacctcntctass WHERE crmacctcntctass_cntct_id = pSourceCntctId;
  END IF;

  -- Deactivate contact
  UPDATE cntct SET cntct_active = false WHERE (cntct_id=pSourceCntctId);
  
  -- Clean up
  DELETE FROM cntctsel WHERE (cntctsel_cntct_id=pSourceCntctId);

  RETURN true;
END;
$$ LANGUAGE plpgsql;
