CREATE OR REPLACE FUNCTION fetchCashRcptNumber() RETURNS TEXT AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
  SELECT fetchNextNumber('CashRcptNumber');
$$ LANGUAGE 'sql';

