CREATE OR REPLACE FUNCTION site() RETURNS SETOF whsinfo AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _r RECORD;

BEGIN

  IF ( fetchMetricBool('MultiWhs') AND
       EXISTS (SELECT 1
                 FROM usrpref
                WHERE ((usrpref_name='selectedSites')
                  AND  (usrpref_value='t')
                  AND  (usrpref_username=getEffectiveXtUser()))) ) THEN

    RETURN QUERY SELECT whsinfo.*
                  FROM whsinfo
                  JOIN usrsite ON (warehous_id=usrsite_warehous_id)
                 WHERE (usrsite_username=getEffectiveXtUser());
  ELSE
    RETURN QUERY SELECT * FROM whsinfo;
  END IF;
  
  RETURN;
END;
$$ LANGUAGE plpgsql STABLE;
