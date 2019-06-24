CREATE OR REPLACE FUNCTION aropenSense(pAropenId INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.

  SELECT CASE WHEN aropen_doctype IN ('C', 'R') THEN -1
              ELSE 1
          END
    FROM aropen
   WHERE aropen_id = pAropenId;

$$ language sql;
