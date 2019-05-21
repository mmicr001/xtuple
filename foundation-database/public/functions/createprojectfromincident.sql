CREATE OR REPLACE FUNCTION createProjectFromIncident(pIncdtId INTEGER)
RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  prjid   INTEGER;
BEGIN
  INSERT INTO prj (prj_number, prj_name, prj_descrip, prj_status,
                   prj_crmacct_id, prj_cntct_id,
                   prj_owner_username, prj_username, prj_assigned_date,
                   prj_priority_id)
  SELECT 'INCIDENT'||incdt_number, incdt_summary, incdt_descrip, 'N',
         incdt_crmacct_id, incdt_cntct_id,   
         incdt_owner_username,  incdt_assigned_username, CURRENT_DATE,
         COALESCE(incdt_incdtpriority_id,
                  (SELECT incdtpriority_id
                     FROM incdtpriority
                    ORDER BY incdtpriority_default DESC, incdtpriority_order
                    LIMIT 1))
  FROM incdt 
  WHERE incdt_id = pIncdtId
  ON CONFLICT DO NOTHING
  RETURNING prj_id INTO prjid;

  IF (prjid IS NULL) THEN
    RAISE EXCEPTION 'There was an error creating the project [xtuple: createProjectFromIncident, -1]';
  END IF;  

-- Create document link between Opportunity and Project (including reverse link)
  INSERT INTO docass (docass_source_id, docass_source_type, docass_target_type, docass_target_id,
                      docass_purpose, docass_username)
  VALUES (prjid, 'J', 'INCDT', pIncdtId, 'S', geteffectivextuser());                      
  INSERT INTO docass (docass_source_id, docass_source_type, docass_target_type, docass_target_id,
                      docass_purpose, docass_username)
  VALUES (pIncdtId, 'INCDT', 'J', prjid, 'S', geteffectivextuser());                      

-- Link new Project back to Incident 
  UPDATE incdt SET incdt_prj_id=prjid
  WHERE incdt_id=pIncdtId;

  RETURN prjid;
END;
$$ LANGUAGE 'plpgsql';
