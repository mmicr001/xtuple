CREATE OR REPLACE FUNCTION formatExternalTaxCodes(pRequest JSON) 
   RETURNS TABLE(id INTEGER, taxcode TEXT, description TEXT, parent TEXT, type TEXT, path TEXT[],
                 level INTEGER) AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license
DECLARE
  _r   RECORD;

BEGIN
  IF (fetchMetricText('TaxService') = 'A') THEN -- Avalara
    FOR _r IN
    WITH RECURSIVE _taxcodes AS
    (
     WITH taxcodes AS
     (
      SELECT value
        FROM json_array_elements(pRequest->'value')
     ),
     alltaxcodes AS
     (
      SELECT value
        FROM taxcodes
      UNION ALL
      SELECT DISTINCT ON (taxcodes.value->>'parentTaxCode')
             json_build_object('taxCode', taxcodes.value->>'parentTaxCode',
                               'taxCodeTypeId', taxcodes.value->>'taxCodeTypeId',
                               'parentTaxCode', taxcodes.value->>'taxCodeTypeId' ||
                                                CASE WHEN taxcodes.value->>'taxCodeTypeId' = 'F'
                                                     THEN 'R'
                                                     ELSE '0'
                                                 END || '000000')
        FROM taxcodes
        LEFT OUTER JOIN taxcodes parent
                     ON taxcodes.value->>'parentTaxCode' = parent.value->>'taxCode'
       WHERE parent.value IS NULL
     )
     SELECT value, ARRAY[value->>'taxCode'] AS path, 0 AS level
       FROM alltaxcodes
      WHERE value->'parentTaxCode' IS NULL
     UNION ALL
     SELECT child.value, _taxcodes.path || (child.value->>'taxCode') AS path,
            _taxcodes.level + 1 AS level
       FROM _taxcodes
       JOIN alltaxcodes child
         ON child.value->>'parentTaxCode'=_taxcodes.value->>'taxCode'
    )
    SELECT value, _taxcodes.path, _taxcodes.level
      FROM _taxcodes
    LOOP
      id = _r.value->'id';
      taxcode = _r.value->>'taxCode';
      description = _r.value->>'description';
      parent = _r.value->>'parentTaxCode';
      type = _r.value->>'taxCodeTypeId';
      path = _r.path;
      level = _r.level;
      RETURN NEXT; 
    END LOOP;
  END IF;
END;
$$ LANGUAGE plpgsql;
