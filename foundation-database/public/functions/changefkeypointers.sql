CREATE OR REPLACE FUNCTION changeFKeyPointers(TEXT, TEXT, INTEGER, INTEGER, TEXT[], BOOLEAN) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  pSchema       ALIAS FOR $1;
  pTable        ALIAS FOR $2;
  pSourceId     ALIAS FOR $3;
  pTargetId     ALIAS FOR $4;
  pIgnore       ALIAS FOR $5;
  _purge        BOOLEAN := COALESCE($6, FALSE);  -- deprecated

  _counter      INTEGER := 0;
  _count1       INTEGER := 0;
  _fk           RECORD;
  _pk           TEXT[];

BEGIN
  -- for all foreign keys that point to pSchema.pTable
  FOR _fk IN
    EXECUTE 'SELECT fkeyns.nspname AS schemaname, fkeytab.relname AS tablename,
                    conkey, attname, typname
               FROM pg_constraint
               JOIN pg_class     basetab ON (confrelid=basetab.oid)
               JOIN pg_namespace basens  ON (basetab.relnamespace=basens.oid)
               JOIN pg_class     fkeytab ON (conrelid=fkeytab.oid)
               JOIN pg_namespace fkeyns  ON (fkeytab.relnamespace=fkeyns.oid)
               JOIN pg_attribute         ON (attrelid=conrelid AND attnum=conkey[1])
               JOIN pg_type              ON (atttypid=pg_type.oid)
              WHERE basetab.relname = ' || quote_literal(pTable)  || '
                AND basens.nspname  = ' || quote_literal(pSchema) || '
                AND fkeytab.relname NOT IN (''' || ARRAY_TO_STRING(pIgnore, ''', ''') || ''')'
  LOOP
    IF (ARRAY_UPPER(_fk.conkey, 1) > 1) THEN
      RAISE EXCEPTION 'Cannot change the foreign key in %.% that refers to %.% because the foreign key constraint has multiple columns. [xtuple: changefkeypointers, -1, %.%, %.%]',
        _fk.schemaname, _fk.tablename, pSchema, pTable,
        _fk.schemaname, _fk.tablename, pSchema, pTable;
    END IF;
    
    -- actually change the foreign keys to point to the desired base table record
    EXECUTE 'UPDATE '  || _fk.schemaname || '.' || _fk.tablename ||
              ' SET '  || _fk.attname    || '=' || pTargetId ||
            ' WHERE (' || _fk.attname    || '=' || pSourceId || ');';

    GET DIAGNOSTICS _count1 = ROW_COUNT;
    _counter := _counter + _count1;
  END LOOP;

  RETURN _counter;
END;
$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION changeFKeyPointers(TEXT, TEXT, INTEGER, INTEGER, TEXT[], BOOLEAN) IS
'Change the data in all tables with foreign key relationships so they point to the pSchema.pTable record with primary key pTargetId instead of the record with primary key pSourceId. Ignore any tables listed in pIgnore.';
