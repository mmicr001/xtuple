CREATE OR REPLACE FUNCTION postBankReconciliation(pBankrecid INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN
  RETURN bankReconciliation(pBankrecid, 'post');
END;
$$ LANGUAGE 'plpgsql';

