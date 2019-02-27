CREATE OR REPLACE FUNCTION buildSimplePhoneJson(pPhone TEXT, pMobile TEXT, pFax TEXT)
RETURNS json AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.

-- Takes Legacy phone number information and builds correctly formatted Json string
  SELECT row_to_json(p)
  FROM (
    SELECT (
      SELECT array_to_json(array_agg(row_to_json(d)))
      FROM (
          SELECT 'Office' AS "role", pPhone AS "number"
          WHERE pPhone IS NOT NULL
          UNION        
          SELECT 'Mobile' AS "role", pMobile AS "number" 
          WHERE pMobile IS NOT NULL
          UNION 
          SELECT 'Fax' AS "role", pFax AS "number"
          WHERE pFax IS NOT NULL
          ) d
       ) AS phones
    ) p;

$$ LANGUAGE sql;
