
CREATE OR REPLACE FUNCTION fetchGLSequence() RETURNS INTEGER AS '
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _sequence INTEGER;

BEGIN

    SELECT NEXTVAL(''gltrans_sequence_seq'') INTO _sequence;
    RETURN _sequence;

END;
' LANGUAGE 'plpgsql';

