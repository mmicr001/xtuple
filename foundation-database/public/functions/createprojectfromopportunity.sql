CREATE OR REPLACE FUNCTION createProjectFromOpportunity(pOpheadId INTEGER)
RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  prjid   INTEGER;
BEGIN
  INSERT INTO prj (prj_number, prj_name, prj_descrip, prj_status,
                   prj_crmacct_id, prj_cntct_id,
                   prj_owner_username, prj_username,
                   prj_start_date, prj_due_date, prj_assigned_date,
                   prj_priority_id)
  SELECT ophead_name, ophead_name, ophead_notes, 'N',
         ophead_crmacct_id, ophead_cntct_id,   
         ophead_owner_username,  ophead_username,
         ophead_start_date, ophead_target_date, CURRENT_DATE,
         COALESCE((SELECT incdtpriority_id FROM incdtpriority WHERE incdtpriority_default),1)
  FROM ophead 
  WHERE ophead_id = pOpHeadId
  ON CONFLICT DO NOTHING
  RETURNING prj_id INTO prjid;

  IF (prjid IS NULL) THEN
    RAISE EXCEPTION 'There was an error creating the project [xtuple: createProjectFromOpportunity, -1]';
  END IF;  

-- Create document link between Opportunity and Project (including reverse link)
  INSERT INTO docass (docass_source_id, docass_source_type, docass_target_type, docass_target_id,
                      docass_purpose, docass_username)
  VALUES (prjid, 'J', 'OPP', pOpHeadId, 'S', geteffectivextuser());                      
  INSERT INTO docass (docass_source_id, docass_source_type, docass_target_type, docass_target_id,
                      docass_purpose, docass_username)
  VALUES (pOpHeadId, 'OPP', 'J', prjid, 'S', geteffectivextuser());                      

-- Link new Project back to opportunity 
  UPDATE ophead SET ophead_prj_id=prjid
  WHERE ophead_id=pOpHeadId;

  RETURN prjid;
END;
$$ LANGUAGE 'plpgsql';
