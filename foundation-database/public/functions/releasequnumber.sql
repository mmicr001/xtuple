CREATE OR REPLACE FUNCTION releaseQuNumber(INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
  SELECT releaseNumber('QuNumber', $1);
$$ LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION releaseQuNumber(TEXT) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
  SELECT releaseNumber('QuNumber', $1::INTEGER);
$$ LANGUAGE 'sql';
