CREATE OR REPLACE FUNCTION changePseudoFKeyPointers(TEXT, TEXT, TEXT, INTEGER, TEXT, TEXT, INTEGER, TEXT, TEXT, BOOLEAN) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  pSchema       ALIAS FOR $1;
  pTable        ALIAS FOR $2;
  pFkeyCol      ALIAS FOR $3;
  pSourceId     ALIAS FOR $4;
  pBaseSchema   ALIAS FOR $5;
  pBaseTable    ALIAS FOR $6;
  pTargetId     ALIAS FOR $7;
  pTypeCol      ALIAS FOR $8;
  pType         ALIAS FOR $9;
  _purge        BOOLEAN := COALESCE($10, FALSE); -- deprecated

  _counter      INTEGER := 0;
  _coltype      TEXT;
  _pk           TEXT[];

BEGIN
  -- Change the foreign keys to point to the desired base table record
  EXECUTE 'UPDATE '  || quote_ident(pSchema)  || '.' || quote_ident(pTable) ||
            ' SET '  || quote_ident(pFkeyCol) || '=' || pTargetId ||
          ' WHERE ((' || quote_ident(pFkeyCol) || '=' || pSourceId || ')
               AND (' || quote_ident(pTypeCol) || '=' || quote_literal(pType) || '));';

  GET DIAGNOSTICS _counter = ROW_COUNT;

  RETURN _counter;
END;
$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION changePseudoFKeyPointers(TEXT, TEXT, TEXT, INTEGER, TEXT, TEXT, INTEGER, TEXT, TEXT, BOOLEAN) IS
'Change the data in pSchema.pTable with a pseudo-foreign key relationship to another (unnamed) table. Make pSchema.pTable point to the record with primary key pTargetId instead of the record with primary key pSourceId. pSchema.pTable cannot have a true foreign key relationship because it holds data that can point to any of several tables. The pType value in the pTypeCol column describes which table the data refer to (e.g. "T" may indicate that the current record refers to a "cntct").';
