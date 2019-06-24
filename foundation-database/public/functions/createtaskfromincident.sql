CREATE OR REPLACE FUNCTION createTaskFromIncident(pIncdtId INTEGER, pTaskName TEXT)
RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  taskid   INTEGER;
BEGIN
  taskid := (SELECT createtask('Incident'::TEXT, incdt_number::TEXT, NULL::TEXT, 'N'::TEXT, pTaskName, pTaskName,
                   (SELECT incdtpriority_id FROM incdtpriority WHERE incdtpriority_default)::TEXT,
                   incdt_owner_username,
                   CASE WHEN LENGTH(incdt_assigned_username) > 0 THEN ('{"assigned": [{"role": "primary", "username": "'||incdt_assigned_username||'","assigned_date":"'||current_date||'"}]}')::json ELSE NULL::json END,
                   0, 0, 0, 0, 0,
                   CURRENT_DATE + 5,
                   CURRENT_DATE,
                   NULL::DATE, incdt_descrip)
            FROM incdt
            WHERE incdt_id=pIncdtId);

  IF (taskid IS NULL) THEN
    RAISE EXCEPTION 'There was an error creating the task [xtuple: createTaskFromIncident, -1]';
  END IF;  

  RETURN taskid;
END;
$$ LANGUAGE 'plpgsql';
