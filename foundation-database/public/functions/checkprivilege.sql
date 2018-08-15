DROP FUNCTION IF EXISTS checkPrivilege(text);
DROP FUNCTION IF EXISTS checkPrivilege(text, text);

CREATE OR REPLACE FUNCTION checkPrivilege(pPrivilege text, pUsername text DEFAULT getEffectiveXtUser())
RETURNS BOOLEAN STABLE AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _result TEXT;
BEGIN
  SELECT priv_id INTO _result
    FROM priv, grppriv, usrgrp
   WHERE((usrgrp_grp_id=grppriv_grp_id)
     AND (grppriv_priv_id=priv_id)
     AND (priv_name IN (SELECT unnest(string_to_array(pPrivilege, ' '))))
     AND (usrgrp_username=pUsername));
  IF (FOUND) THEN
    RETURN true;
  END IF;

  SELECT priv_id INTO _result
  FROM priv, usrpriv
  WHERE ((priv_id=usrpriv_priv_id)
  AND (priv_name IN (SELECT unnest(string_to_array(pPrivilege, ' '))))
  AND (usrpriv_username=pUsername));

  IF (FOUND) THEN
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE 'plpgsql';
