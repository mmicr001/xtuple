DROP FUNCTION IF EXISTS xt.pg_advisory_unlock(integer, integer);
CREATE OR REPLACE FUNCTION xt.pg_advisory_unlock(pOid INTEGER, pId INTEGER)
  RETURNS BOOLEAN AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
-- simplified version of lib/orm/source/xt/javascript/data.sql::releaseLock()
BEGIN
  PERFORM pg_catalog.pg_advisory_unlock(pOid, pId);
  DELETE FROM xt.lock
   WHERE lock_table_oid = pOid
     AND lock_record_id = pId
     AND lock_username  = geteffectivextuser();
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
