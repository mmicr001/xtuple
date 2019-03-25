CREATE OR REPLACE FUNCTION fetchTaskNumber() RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
  SELECT fetchNextNumber('TaskNumber')::INTEGER;
$$ LANGUAGE 'sql';
