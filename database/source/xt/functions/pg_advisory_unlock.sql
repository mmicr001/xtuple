DROP FUNCTION IF EXISTS xt.pg_advisory_unlock(integer, integer);
CREATE OR REPLACE FUNCTION xt.pg_advisory_unlock(pOid INTEGER, pId INTEGER)
  RETURNS BOOLEAN AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
-- simplified version of lib/orm/source/xt/javascript/data.sql::releaseLock()
DECLARE
  _rows INTEGER;
  _unlocked BOOLEAN := pg_catalog.pg_advisory_unlock(pOid, pId);
BEGIN
  DELETE FROM xt.lock
   WHERE lock_table_oid = pOid
     AND lock_record_id = pId
     AND lock_username  = geteffectivextuser()
     AND lock_pid       = pg_backend_pid();
  GET DIAGNOSTICS _rows = ROW_COUNT;
  RETURN _rows > 0 OR _unlocked;
END;
$$ LANGUAGE plpgsql;
