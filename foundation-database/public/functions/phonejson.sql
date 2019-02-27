CREATE OR REPLACE FUNCTION phoneJson(pContactId INTEGER)
RETURNS json AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.

-- Takes Contact Phone data and builds correctly formatted Json string
  SELECT row_to_json(p)
  FROM (
    SELECT (
      SELECT array_to_json(array_agg(row_to_json(d)))
      FROM (
        SELECT crmrole_name AS "role", cntctphone_phone AS "number"
        FROM cntctphone
        JOIN crmrole ON crmrole_id=cntctphone_crmrole_id
        WHERE cntctphone_cntct_id=pContactId
        ORDER BY crmrole_sort) d
     ) AS phones
  ) p;

$$ LANGUAGE SQL;

