
CREATE OR REPLACE FUNCTION public.addrselect(pAddrId integer, pTarget boolean)
  RETURNS boolean AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  CREATE TEMPORARY TABLE IF NOT EXISTS addrsel
    (LIKE public.addrsel INCLUDING ALL)
    ON COMMIT PRESERVE ROWS;

  -- If target, delete any other targets
  IF (pTarget) THEN
    DELETE FROM addrsel WHERE addrsel_target;
  END IF;
  
  -- Delete any previous selection of this address
  DELETE FROM addrsel WHERE addrsel_addr_id=pAddrId;

  -- Add this address in appropriate selection state
  INSERT INTO addrsel (addrsel_addr_id, addrsel_target) VALUES (pAddrId, pTarget);

  RETURN true;
END;
$$ LANGUAGE plpgsql;

