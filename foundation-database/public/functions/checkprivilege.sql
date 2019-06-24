DROP FUNCTION IF EXISTS checkPrivilege(text);
DROP FUNCTION IF EXISTS checkPrivilege(text, text);

CREATE OR REPLACE FUNCTION checkPrivilege(pPrivilege text, pUsername text DEFAULT getEffectiveXtUser())
RETURNS BOOLEAN STABLE AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _priv     TEXT[];
  _privAnd  TEXT[];
  _andCount INTEGER;
  _r        RECORD;
  _result   INTEGER;
BEGIN
/*
  if pPrivilege contains #superuser then check for isDBA() privilege
  if pPrivileges are separated by a space then return TRUE if ANY privileges are assigned
  if pPrivileges are separated by a plus then return TRUE only if ALL privileges are assigned
*/
  IF (pPrivilege = '#superuser') THEN
    RETURN isDBA();
  END IF;

  _priv := string_to_array(pPrivilege, ' ');

  FOR _r IN
    SELECT unnest(_priv) AS priv
  LOOP
    IF (NOT _r.priv LIKE '%+%') THEN
   -- Check OR
      SELECT SUM(count) INTO _result
      FROM (
        SELECT COUNT(*)
          FROM priv, grppriv, usrgrp
         WHERE usrgrp_grp_id=grppriv_grp_id
           AND grppriv_priv_id=priv_id
           AND priv_name = _r.priv
           AND usrgrp_username=pUsername
        UNION ALL
        SELECT COUNT(*)
          FROM priv, usrpriv
         WHERE priv_id=usrpriv_priv_id
           AND priv_name = _r.priv
           AND usrpriv_username=pUsername) foo;

      IF (_result > 0) THEN
        RETURN true;
      END IF;

    ELSE
  -- Check AND
      _privAnd := string_to_array(_r.priv, '+');
      _andCount := array_length(_privAnd, 1);

      SELECT SUM(count) INTO _result
      FROM (
        SELECT COUNT(*)
          FROM priv, grppriv, usrgrp
         WHERE usrgrp_grp_id=grppriv_grp_id
           AND grppriv_priv_id=priv_id
           AND priv_name IN (SELECT unnest(_privAnd))
           AND usrgrp_username=pUsername
        UNION ALL
        SELECT COUNT(*)
          FROM priv, usrpriv
         WHERE priv_id=usrpriv_priv_id
           AND priv_name IN (SELECT unnest(_privAnd))
           AND usrpriv_username=pUsername) foo;

      IF (_result = _andCount) THEN
        RETURN true;
      END IF;

    END IF;
  END LOOP;

  RETURN false;
END;
$$ LANGUAGE 'plpgsql';
