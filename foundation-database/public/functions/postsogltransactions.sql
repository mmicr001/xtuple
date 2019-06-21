CREATE OR REPLACE FUNCTION postSoGLTransactions() RETURNS BOOLEAN AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN

  UPDATE gltrans
  SET gltrans_exported=TRUE
  WHERE ( (NOT gltrans_exported)
   AND (gltrans_source=''A/R'')
   AND (gltrans_doctype IN (''IN'', ''CM'')) );

  RETURN TRUE;

END;
' LANGUAGE 'plpgsql';
