CREATE OR REPLACE FUNCTION public.addrselectcol(
    pAddrId integer,
    pCol text)
  RETURNS boolean AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  if (pAddrId IS NOT NULL AND pCol IS NOT NULL) THEN
    EXECUTE format('UPDATE addrsel SET %1$I=false WHERE (%1$I AND addrsel_addr_id != %L)', 
                   'addrsel_mrg_addr_'||pCol,
                   pAddrId);
    EXECUTE format('UPDATE addrsel SET %I=true WHERE (addrsel_addr_id = %L)',
                   'addrsel_mrg_addr_'||pCol,
                   pAddrId);
    RETURN true;
  END IF;

  RETURN false;
END;
$$ LANGUAGE plpgsql;
