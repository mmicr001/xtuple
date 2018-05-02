CREATE OR REPLACE FUNCTION fetchProjectNumber() RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
  SELECT fetchNextNumber('ProjectNumber')::INTEGER;
$$ LANGUAGE 'sql';

