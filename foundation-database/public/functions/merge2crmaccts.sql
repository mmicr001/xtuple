DROP FUNCTION IF EXISTS merge2crmaccts(INTEGER, INTEGER, BOOLEAN);

CREATE OR REPLACE FUNCTION public.merge2crmaccts(pSourceid integer, pTargetid integer)
  RETURNS integer AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _sourcenum  TEXT;
  _targetnum  TEXT;
  _count      INTEGER := 0;
  _mrgcol     BOOLEAN;
  _result     INTEGER := 0;
  _tblname    TEXT;
  _colname    TEXT;
  _paramsary  TEXT[];
  _paramStr   TEXT;
  _qry        TEXT;
  _tmpid      INTEGER;
  _rec        RECORD;

  _srcid      INTEGER;
  _tgtid      INTEGER;
  _keepSrc    BOOLEAN := FALSE;
  _delSql     TEXT := 'DELETE FROM %I WHERE %I_id = %L';

  _crmtbls    TEXT[] := ARRAY['prospect', 'custinfo', 'vendinfo', 'salesrep', 'taxauth', 'emp'];  -- Prospect must exist before Customer
  _crmtbl     TEXT;
  _source     RECORD;
  _debug      BOOLEAN := FALSE;
BEGIN
  -- Human Readable error values;
  _sourcenum := (SELECT crmacct_number FROM crmacct WHERE crmacct_id=pSourceId);
  _targetnum := (SELECT crmacct_number FROM crmacct WHERE crmacct_id=pTargetId);

  -- Validate
  IF (pSourceId = pTargetId) THEN
    RAISE WARNING 'Tried to merge a CRM Account with itself: %. [xtuple: merge2crmaccts, -1]', _sourcenum;
    RETURN 0;
  ELSIF (pSourceId IS NULL) THEN
    RAISE EXCEPTION 'Merge source id cannot be null [xtuple: merge2crmaccts, -1]';
  ELSIF NOT(EXISTS(SELECT 1 FROM crmacct WHERE crmacct_id=pSourceId)) THEN
    RAISE EXCEPTION 'Merge source % not found [xtuple: merge2crmaccts, -2, %]',
                    _sourcenum, pSourceId;
  ELSIF (pTargetId IS NULL) THEN
    RAISE EXCEPTION 'Merge target id cannot be null [xtuple: merge2crmaccts, -3]';
  ELSIF NOT(EXISTS(SELECT 1 FROM crmacct WHERE crmacct_id=pTargetId)) THEN
    RAISE EXCEPTION 'Merge target % not found [xtuple: merge2crmaccts, -4, %]',
                    _targetnum, pTargetId;
  ELSIF NOT(EXISTS(SELECT 1
                     FROM crmacctsel
                    WHERE (crmacctsel_src_crmacct_id=pSourceId)
                      AND (crmacctsel_dest_crmacct_id=pTargetId))) THEN
    RAISE EXCEPTION 'Source % and target % have not been selected for merging [xtuple: merge2crmaccts, -5, %, %]',
                    _sourcenum, _targetnum, pSourceId, pTargetId;
  END IF;

  -- Update CRM account foreign keys (except for CRM relation tables which are specifically handled)
  _result:= changeFkeyPointers('public', 'crmacct', pSourceId, pTargetId,
                 array_cat(ARRAY[ 'crmacctsel', 'crmacctmrgd'], _crmtbls), true)
          + changePseudoFKeyPointers('public', 'alarm', 'alarm_source_id',
                                     pSourceId, 'public', 'crmacct', pTargetId,
                                     'alarm_source', 'CRMA', true)
          + changePseudoFKeyPointers('public', 'charass', 'charass_target_id',
                                     pSourceId, 'public', 'crmacct', pTargetId,
                                     'charass_target_type', 'CRMACCT', true)
          + changePseudoFKeyPointers('public', 'comment', 'comment_source_id',
                                     pSourceId, 'public', 'crmacct', pTargetId,
                                     'comment_source', 'CRMA', true)
          + changePseudoFKeyPointers('public', 'docass', 'docass_source_id',
                                     pSourceId, 'public', 'crmacct', pTargetId,
                                     'docass_source_type', 'CRMA', true)
          + changePseudoFKeyPointers('public', 'docass', 'docass_target_id',
                                     pSourceId, 'public', 'crmacct', pTargetId,
                                     'docass_target_type', 'CRMA', true)
          + changePseudoFKeyPointers('public', 'imageass', 'imageass_source_id',
                                     pSourceId, 'public', 'crmacct', pTargetId,
                                     'imageass_source', 'CRMA', true)
          ;

  -- TODO: find a generic way to handle pseudofkeys in packages - see 9401
  IF (fetchMetricBool('EnableBatchManager') AND packageIsEnabled('xtbatch')) THEN
    _result:= _result
            + changePseudoFKeyPointers('xtbatch', 'emlassc', 'emlassc_assc_id',
                                       pSourceId, 'public', 'crmacct', pTargetId,
                                       'emlassc_type', 'CRMA', TRUE);
  END IF;

  -- Update/merge the associated CRM relations after checking existence of said relations
  -- Customer takes precedence over Prospect regardless of source/target.
  FOREACH _crmtbl IN ARRAY _crmtbls
  LOOP
    _paramsary := ARRAY[ format('"tblname": "%s"', _crmtbl),
                         format('"colname": "%s"', REPLACE(_crmtbl, 'info', '')),
                         format('"srcid": %s', pSourceId),
                         format('"destid": %s', pTargetId)];
    if (_crmtbl IN ('custinfo', 'prospect')) THEN
      _paramsary := array_append(_paramsary, '"custpspct": true');
    END IF;

    _paramStr := '{ "params": {' || array_to_string(_paramsary, ',') || '}}';
    _qry := xt.parsemetasql('crmaccountmerge', 'checkentity', _paramStr);

    RAISE NOTICE 'Processing %', _crmtbl;
    EXECUTE _qry INTO _rec;
    IF (_debug) THEN
      RAISE NOTICE $r$ s: %, t: %, _qry: % $r$, _rec.src, _rec.tgt, _qry;
    END IF;
    _srcid := _rec.src;
    _tgtid := _rec.tgt;
    _keepSrc := (_srcid IS NOT NULL AND _tgtid IS NULL);

    if (_crmtbl IN ('custinfo', 'prospect')) THEN
       _tgtid := COALESCE(_rec.tgt_cust, _rec.src_cust, _rec.tgt);
       _srcid := COALESCE(_rec.src, _rec.tgt);
       _keepSrc := COALESCE(_tgtid = _rec.src_cust, FALSE);

       -- Couple of foreign key exceptions
       EXECUTE format('UPDATE quhead SET quhead_cust_id = %L WHERE quhead_cust_id = %L', _tgtid, _srcid);
       EXECUTE format('UPDATE ipsass SET ipsass_cust_id = %L WHERE ipsass_cust_id = %L', _tgtid, _srcid);
    end if;

    IF (_srcid IS NOT NULL AND _tgtid IS NOT NULL AND _srcid <> _tgtid) THEN
      IF (_debug) THEN
        RAISE NOTICE 'Updating CRM relation %,  src: %,  tgt: %,  keepSrc: %', _crmtbl, _srcid, _tgtid, _keepSrc;
      END IF;

      SELECT source_name, source_charass, source_docass INTO _source
        FROM source
       WHERE source_table = _crmtbl;

      _result:= _result + changeFkeyPointers('public', _crmtbl, _srcid, _tgtid,
                ARRAY['wotc']::TEXT[], true)
              + changePseudoFKeyPointers('public', 'alarm', 'alarm_source_id',
                                         _srcid, 'public', _crmtbl, _tgtid,
                                         'alarm_source', _source.source_name, true)
              + changePseudoFKeyPointers('public', 'charass', 'charass_target_id',
                                         _srcid, 'public', _crmtbl, _tgtid,
                                         'charass_target_type', _source.source_charass, true)
              + changePseudoFKeyPointers('public', 'comment', 'comment_source_id',
                                         _srcid, 'public', _crmtbl, _tgtid,
                                         'comment_source', _source.source_name, true)
              + changePseudoFKeyPointers('public', 'docass', 'docass_source_id',
                                         _srcid, 'public', _crmtbl, _tgtid,
                                         'docass_source_type', _source.source_docass, true)
              + changePseudoFKeyPointers('public', 'docass', 'docass_target_id',
                                         _srcid, 'public', _crmtbl, _tgtid,
                                         'docass_target_type', _source.source_docass, true)
              + changePseudoFKeyPointers('public', 'imageass', 'imageass_source_id',
                                         _srcid, 'public', _crmtbl, _tgtid,
                                         'imageass_source', _source.source_docass, true)
              ;

      IF (fetchMetricBool('EnableBatchManager') AND packageIsEnabled('xtbatch')) THEN
        _result:= _result
                + changePseudoFKeyPointers('xtbatch', 'emlassc', 'emlassc_assc_id',
                                           _srcid, 'public', _crmtbl, _tgtid,
                                           'emlassc_type', _crmtype, TRUE);
      END IF;

      IF (_crmtbl IN ('custinfo', 'vendinfo', 'taxauth')) THEN
        EXECUTE format('UPDATE checkhead SET checkhead_recip_id = %L
                        WHERE checkhead_recip_id = %L
                        AND checkhead_recip_type = %L;', _tgtid, _srcid,
                                                         CASE _crmtbl WHEN 'custinfo' THEN 'C'
                                                                      WHEN 'vendinfo' THEN 'V'
                                                                      WHEN 'taxauth' THEN 'T'
                                                          END);
      END IF;
      IF (_crmtbl IN ('custinfo', 'vendinfo')) THEN
        EXECUTE format('UPDATE taxreg SET taxreg_rel_id = %L
                        WHERE taxreg_rel_id = %L
                        AND taxreg_rel_type = %L;', _tgtid, _srcid, _source.source_name);
      END IF;

      IF (_keepSrc And _crmtbl = 'prospect') THEN
        EXECUTE format('UPDATE custinfo SET cust_crmacct_id = %L
                        WHERE cust_crmacct_id = %L;', pTargetId, pSourceId);
      END IF;

      EXECUTE format(_delSql, _crmtbl, REPLACE(_crmtbl, 'info', ''), _srcid);
    END IF;

    EXECUTE format('UPDATE %I SET %I_crmacct_id = %L
                    WHERE %I_crmacct_id = %L;', _crmtbl, REPLACE(_crmtbl, 'info', ''),
                       pTargetId, REPLACE(_crmtbl, 'info', ''), pSourceId);

  END LOOP;

  EXECUTE format('UPDATE crmacct dest SET crmacct_notes=dest.crmacct_notes
                || E''\n'' || src.crmacct_notes
             FROM crmacct src
             JOIN crmacctsel ON (src.crmacct_id=crmacctsel_src_crmacct_id)
             WHERE ((dest.crmacct_id=crmacctsel_dest_crmacct_id)
                AND (dest.crmacct_id!=crmacctsel_src_crmacct_id))
                AND dest.crmacct_id = %L', pTargetid);

  GET DIAGNOSTICS _count = ROW_COUNT;
  _result := _result + _count;

  PERFORM postComment('ChangeLog', 'CRMA', pTargetid,
                       format('CRM Account %L merged into %L', _sourcenum,_targetnum));
  DELETE FROM crmacct WHERE crmacct_id = pSourceId;
  DELETE FROM crmacctcntctass WHERE crmacctcntctass_crmacct_id = pSourceId;
  DELETE FROM crmacctsel WHERE (crmacctsel_src_crmacct_id=pSourceId);

  RETURN _result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION merge2crmaccts(INTEGER, INTEGER) IS
'This function merges two crmacct records as decribed in crmacctsel records. The merge is executed immediately and cannot be undone as it flushes the merged records through the relevant customer/vendor documents';
