CREATE OR REPLACE FUNCTION getFreightTaxTypeId() RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  RETURN taxtype_id
    FROM taxtype
   WHERE taxtype_name='Freight';

END
$$ language plpgsql;
