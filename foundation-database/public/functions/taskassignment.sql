CREATE OR REPLACE FUNCTION public.taskassignment(pTaskid integer)
  RETURNS json AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.

-- Takes Contact Phone data and builds correctly formatted Json string
  SELECT row_to_json(ta)
  FROM (
    SELECT (
      SELECT array_to_json(array_agg(row_to_json(d)))
      FROM (
        SELECT crmrole_name AS "role", taskass_username AS "username", taskass_assigned_date AS "assigned_date"
        FROM taskass
        JOIN crmrole ON crmrole_id=taskass_crmrole_id
        WHERE taskass_task_id=pTaskid
        ORDER BY crmrole_sort
      ) d
    ) AS assigned
  ) ta;

$$ LANGUAGE sql;
