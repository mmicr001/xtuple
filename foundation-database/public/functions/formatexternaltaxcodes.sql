CREATE OR REPLACE FUNCTION formatExternalTaxCodes(pRequest JSON) 
   RETURNS TABLE(id INTEGER, taxcode TEXT, description TEXT) AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license
DECLARE
  _r   RECORD;

BEGIN
  IF (fetchMetricText('TaxService') = 'A') THEN -- Avalara
    FOR _r IN
      SELECT value
        FROM json_array_elements(pRequest->'value')
    LOOP
      id = _r.value->'id';
      taxcode = _r.value->>'taxCode';
      description = _r.value->>'description';
      RETURN NEXT; 
    END LOOP;
  END IF;
END;
$$ LANGUAGE plpgsql;
