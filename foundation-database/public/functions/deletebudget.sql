
CREATE OR REPLACE FUNCTION deleteBudget(INTEGER) RETURNS INTEGER AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  pBudgheadid ALIAS FOR $1;

BEGIN
  DELETE FROM budgitem WHERE (budgitem_budghead_id=pBudgheadid);
  DELETE FROM budghead WHERE (budghead_id=pBudgheadid);

  RETURN pBudgheadid;
END;
' LANGUAGE 'plpgsql';

