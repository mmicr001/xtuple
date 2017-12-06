CREATE OR REPLACE FUNCTION merge2crmaccts(INTEGER, INTEGER, BOOLEAN) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pSourceId ALIAS FOR $1;
  pTargetId ALIAS FOR $2;
  _purge    BOOLEAN := COALESCE($3, FALSE);

  _sourcenum  TEXT;
  _targetnum  TEXT;
  _canmerge   RECORD;
  _coldesc    RECORD;
  _count      INTEGER := 0;
  _hassubtype BOOLEAN;
  _mrgcol     BOOLEAN;
  _result     INTEGER := 0;
  _sel        RECORD;
  _tblname    TEXT;
  _colname    TEXT;
  _tmpid      INTEGER;

  _crmtbls    TEXT[] := ARRAY['custinfo', 'vendinfo', 'prospect', 'salesrep', 'taxauth', 'emp'];
  _crmtbl     TEXT;

BEGIN
  -- Human Readable values;
  _sourcenum := (SELECT crmacct_number FROM crmacct WHERE crmacct_id=pSourceId);
  _targetnum := (SELECT crmacct_number FROM crmacct WHERE crmacct_id=pTargetId);

  -- Validate
  IF (pSourceId = pTargetId) THEN
    RAISE WARNING 'Tried to merge a CRM Account with itself: %.', _sourcenum;
    RETURN 0;
  ELSIF (pSourceId IS NULL) THEN
    RAISE EXCEPTION 'Merge source id cannot be null [xtuple: merge, -1]';
  ELSIF NOT(EXISTS(SELECT 1 FROM crmacct WHERE crmacct_id=pSourceId)) THEN
    RAISE EXCEPTION 'Merge source % not found [xtuple: merge, -2, %]',
                    _sourcenum, pSourceId;
  ELSIF (pTargetId IS NULL) THEN
    RAISE EXCEPTION 'Merge target id cannot be null [xtuple: merge, -3]';
  ELSIF NOT(EXISTS(SELECT 1 FROM crmacct WHERE crmacct_id=pTargetId)) THEN
    RAISE EXCEPTION 'Merge target % not found [xtuple: merge, -4, %]',
                    _targetnum, pTargetId;
  ELSIF NOT(EXISTS(SELECT 1
                     FROM crmacctsel
                    WHERE (crmacctsel_src_crmacct_id=pSourceId)
                      AND (crmacctsel_dest_crmacct_id=pTargetId))) THEN
    RAISE EXCEPTION 'Source % and target % have not been selected for merging [xtuple: merge, -5, %, %]',
                    _sourcenum, _targetnum, pSourceId, pTargetId;
  END IF;

  -- Check whether CRM Accounts to merge both exist as customers/prospects/vendors etc. which cannot
  -- be merged if both exist. Pass human-readable message back to user.
  FOR _canmerge IN
    SELECT initcap(CASE WHEN foo.key IN ('customer','prospect') THEN 'customer or prospect' 
                        WHEN foo.key = 'salesrep' THEN 'sales rep'
                        WHEN foo.key = 'taxauth' THEn 'tax authority'
                        ELSE foo.key END) AS newkey, 
           bool_or(cust1check) AND bool_or(cust2check) AS matchingcust,
           bool_or(othercheck) AS matchingother
    FROM (       
       SELECT c1.key, 
       CASE WHEN c1.key IN ('customer','prospect') THEN (c1.value IS NOT NULL) ELSE false END AS cust1check,
       CASE WHEN c1.key IN ('customer','prospect') THEN (c2.value IS NOT NULL) ELSE false END AS cust2check,
       (c1.value IS NOT NULL) AND (c2.value IS NOT NULL) AS othercheck
       FROM (select * from json_each_text(crmaccttypes(pSourceId))) c1
       JOIN (select * from json_each_text(crmaccttypes(pTargetId))) c2 ON (c1.key=c2.key)
    WHERE c1.key NOT IN ('competitor', 'partner')      
    ) foo
    GROUP BY newkey
  LOOP
    IF (_canmerge.matchingcust OR _canmerge.matchingother) THEN
      RAISE EXCEPTION 'Cannot merge two CRM Accounts that both refer to % [xtuple: merge, -6, %, %]',
                      _canmerge.newkey, pSourceId, pTargetId;    
    END IF;
  END LOOP;

  _result:= changeFkeyPointers('public', 'crmacct', pSourceId, pTargetId,
                 array_cat(ARRAY[ 'crmacctsel', 'crmacctmrgd'], _crmtbls), _purge)
          + changePseudoFKeyPointers('public', 'alarm', 'alarm_source_id',
                                     pSourceId, 'public', 'crmacct', pTargetId,
                                     'alarm_source', 'CRMA', _purge)
          + changePseudoFKeyPointers('public', 'charass', 'charass_target_id',
                                     pSourceId, 'public', 'crmacct', pTargetId,
                                     'charass_target_type', 'CRMACCT', _purge)
          + changePseudoFKeyPointers('public', 'comment', 'comment_source_id',
                                     pSourceId, 'public', 'crmacct', pTargetId,
                                     'comment_source', 'CRMA', _purge)
          + changePseudoFKeyPointers('public', 'docass', 'docass_source_id',
                                     pSourceId, 'public', 'crmacct', pTargetId,
                                     'docass_source_type', 'CRMA', _purge)
          + changePseudoFKeyPointers('public', 'docass', 'docass_target_id',
                                     pSourceId, 'public', 'crmacct', pTargetId,
                                     'docass_target_type', 'CRMA', _purge)
          + changePseudoFKeyPointers('public', 'imageass', 'imageass_source_id',
                                     pSourceId, 'public', 'crmacct', pTargetId,
                                     'imageass_source', 'CRMA', _purge)
          ;

  -- TODO: find a generic way to handle pseudofkeys in packages - see 9401
  IF (fetchMetricBool('EnableBatchManager') AND packageIsEnabled('xtbatch')) THEN
    _result:= _result
            + changePseudoFKeyPointers('xtbatch', 'emlassc', 'emlassc_assc_id',
                                       pSourceId, 'public', 'crmacct', pTargetId,
                                       'emlassc_type', 'CRMA', _purge);
  END IF;

  -- Merge the associated CRM entities based on user selections
  FOREACH _crmtbl IN ARRAY _crmtbls
  LOOP
    -- if we're supposed to merge this table at all
    EXECUTE format('SELECT crmacctsel_mrg_%I
                    FROM crmacctsel
                    WHERE crmacctsel_src_crmacct_id = %L
                      AND crmacctsel_dest_crmacct_id = %L',
                 _crmtbl,  pSourceId, pTargetId) INTO _mrgcol;

    IF (_mrgcol) THEN
      EXECUTE format('UPDATE %I SET %I_crmacct_id = %L 
                      WHERE %I_crmacct_id = %L;', _crmtbl, REPLACE(_crmtbl, 'info', ''),
                         pTargetId, REPLACE(_crmtbl, 'info', ''), pSourceId);
    END IF;
  END LOOP;

  -- back up all of the values in the target record that are about to be changed
  FOR _coldesc IN SELECT attname, typname
                    FROM pg_attribute
                    JOIN pg_type      ON (atttypid=pg_type.oid)
                    JOIN pg_class     ON (attrelid=pg_class.oid)
                    JOIN pg_namespace ON (relnamespace=pg_namespace.oid)
                   WHERE (attnum >= 0)
                     AND (relname='crmacct')
                     AND (nspname='public')
                     AND (attname NOT IN ('crmacct_id', 'crmacct_number', 
                                  'crmacct_created', 'crmacct_lastupdated'))
  LOOP

    -- if we're supposed to merge this column at all
    EXECUTE 'SELECT ' || quote_ident('crmacctsel_mrg_' || _coldesc.attname) || '
               FROM crmacctsel
              WHERE ((crmacctsel_src_crmacct_id='  || pSourceId || ')
                 AND (crmacctsel_dest_crmacct_id=' || pTargetId || '))' INTO _mrgcol;

    IF (_mrgcol) THEN
      _colname := _coldesc.attname;

      -- optionally back up the old value from the destination
      -- we'll back up the old value from the source further down
      IF (NOT _purge) THEN
        BEGIN
          EXECUTE 'INSERT INTO mrgundo (
                       mrgundo_schema,      mrgundo_table,
                       mrgundo_pkey_col,    mrgundo_pkey_id,
                       mrgundo_col,         mrgundo_value,      mrgundo_type,
                       mrgundo_base_schema, mrgundo_base_table, mrgundo_base_id
                 ) SELECT ''public'',     ''crmacct'',
                          ''crmacct_id'', crmacct_id, '   ||
                          quote_literal(_colname)         || ', ' ||
                          quote_ident(_colname)           || ', ' ||
                          quote_literal(_coldesc.typname) || ',
                          ''public'', ''crmacct'', crmacct_id
                     FROM crmacct
                    WHERE (crmacct_id=' || pTargetId || ');' ;
        EXCEPTION WHEN unique_violation THEN
          RAISE EXCEPTION 'Could not make a backup copy of % when merging % into % [xtuple: merge, -8, %, %, public, crmacct, %]',
                       _colname, _sourcenum, _targetnum,
                       _colname, pSourceId, pTargetId;
        END;
      END IF;

      /* update the destination crmacct in one of 3 different ways:
         - crmacct_notes might be concatenated from more than one source record
	 - foreign keys to crm account subtype records
           must not leave orphaned records and must avoid uniqueness violations
         - some fields can simply be updated in place
       */
      IF (_colname = 'crmacct_notes') THEN
        EXECUTE 'UPDATE crmacct dest
                    SET '      || quote_ident(_colname) ||
                      '=dest.' || quote_ident(_colname) ||
                      E' || E''\\n'' || src.' || _colname || '
                  FROM crmacct src
                  JOIN crmacctsel ON (src.crmacct_id=crmacctsel_src_crmacct_id)
                 WHERE ((dest.crmacct_id=crmacctsel_dest_crmacct_id)
                    AND (dest.crmacct_id!=crmacctsel_src_crmacct_id));';

      ELSE
        EXECUTE 'UPDATE crmacct dest
                    SET '      || quote_ident(_colname) || '
                        =src.' || quote_ident(_colname) || '
                  FROM crmacct src
                 WHERE ((dest.crmacct_id=' || pTargetId || ')
                    AND (src.crmacct_id='  || pSourceId || '));';
      END IF;

      GET DIAGNOSTICS _count = ROW_COUNT;
      _result := _result + _count;
    END IF;

  END LOOP;

  IF (_purge) THEN
    DELETE FROM crmacct WHERE crmacct = pSourceId;
    DELETE FROM crmacctcntctass WHERE crmacctcntctass_crmacct_id = pSourceId;
  ELSE
    INSERT INTO mrgundo (
           mrgundo_schema,      mrgundo_table,
           mrgundo_pkey_col,    mrgundo_pkey_id,
           mrgundo_col,         mrgundo_value,      mrgundo_type,
           mrgundo_base_schema, mrgundo_base_table, mrgundo_base_id
    ) SELECT 'public',         'crmacct',
             'crmacct_id',     pSourceId,
             'crmacct_active', crmacct_active, 'bool',
             'public',         'crmacct',       pTargetId
        FROM crmacct
       WHERE crmacct_active AND (crmacct_id = pSourceId);
    GET DIAGNOSTICS _count = ROW_COUNT;
    IF (_count > 0) THEN
      _result := _result + _count;
      UPDATE crmacct SET crmacct_active = false WHERE (crmacct_id=pSourceId);
    END IF;

    -- make a special record of the source crm account so we can delete it later
    INSERT INTO mrgundo (
           mrgundo_schema,      mrgundo_table,
           mrgundo_pkey_col,    mrgundo_pkey_id,
           mrgundo_col,         mrgundo_value,      mrgundo_type,
           mrgundo_base_schema, mrgundo_base_table, mrgundo_base_id
     ) VALUES (
           'public',     'crmacct',
           'crmacct_id', pSourceId,
           NULL,         NULL,       NULL,
           'public',     'crmacct', pTargetId);
  END IF;

  DELETE FROM crmacctsel WHERE (crmacctsel_src_crmacct_id=pSourceId);

  RETURN _result;
END;
$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION merge2crmaccts(INTEGER, INTEGER, BOOLEAN) IS
'This function merges two crmacct records as decribed in crmacctsel records. For each field in the crmacctsel record marked TRUE, the data are copied from the crmacct record with crmacct_id=pSourceId to the record with crmacct_id=pTargetId. If the purge argument is TRUE, the source record is deleted. If it is FALSE, then mrgundo records are created so the merge can later be undone.';
