CREATE OR REPLACE FUNCTION isrecursodone(pcoheadid INTEGER) RETURNS BOOLEAN AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.

-- This function is a place holder in case there is a need for a condition
-- to stop a recurring sales order based on something other than the recurrence end date.
BEGIN
  RETURN false;
END;

$$ LANGUAGE plpgsql;
