DROP FUNCTION IF EXISTS checkPrivilege(text);
DROP FUNCTION IF EXISTS checkPrivilege(text, text);

CREATE OR REPLACE FUNCTION checkPrivilege(pPrivilege text, pUsername text DEFAULT getEffectiveXtUser())
RETURNS BOOLEAN STABLE AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _priv   TEXT[];
  _all    BOOLEAN := false;
  _count  INTEGER;
  _result INTEGER;
BEGIN
/*
  if pPrivilege contains #superuser then check for isDBA() privilege
  if pPrivileges are separated by a space then return TRUE if ANY privileges are assigned
  if pPrivileges are separated by a plus then return TRUE only if ALL privileges are assigned
*/

  IF (pPrivilege = '#superuser') THEN
    RETURN isDBA();
  END IF;

  _priv := string_to_array(REPLACE(pPrivilege,'+',' '), ' ');

  IF (POSITION('+' IN pPrivilege) > 0) THEN
    _all := true;
    _count := array_length(_priv, 1);
  END IF;

  SELECT COUNT(*) INTO _result
    FROM priv, grppriv, usrgrp
   WHERE((usrgrp_grp_id=grppriv_grp_id)
     AND (grppriv_priv_id=priv_id)
     AND (priv_name IN (SELECT unnest(_priv)))
     AND (usrgrp_username=pUsername));

  IF ((_all AND _result =_count) OR (NOT(_all) AND _result > 0)) THEN
    RETURN true;  
  END IF;

  SELECT COUNT(*) INTO _result
  FROM priv, usrpriv
  WHERE ((priv_id=usrpriv_priv_id)
  AND (priv_name IN (SELECT unnest(_priv)))
  AND (usrpriv_username=pUsername));

  IF ((_all AND _result =_count) OR (NOT(_all) AND _result > 0)) THEN
    RETURN true;  
  END IF;
  
  RETURN false;
END;
$$ LANGUAGE 'plpgsql';
