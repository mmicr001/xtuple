CREATE OR REPLACE FUNCTION copyproject(integer, text, text, date)
  RETURNS integer AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  pPrjId ALIAS FOR $1;
  pPrjNumber ALIAS FOR $2;
  pPrjName ALIAS FOR $3;
  pDueDate ALIAS FOR $4;
  _prjid INTEGER;
  _tasks RECORD;
  _offset INTEGER;
  _newTaskid INTEGER;
  _teExists BOOLEAN;
BEGIN

  IF (COALESCE(pPrjNumber, '') = '') THEN
    RETURN -1;
  END IF;

  IF (COALESCE(pPrjName, '') = '') THEN
    RETURN -1;
  END IF;

  IF (EXISTS(SELECT prj_id FROM prj WHERE UPPER(prj_number)=UPPER(pPrjNumber))) THEN
    RETURN -2;
  END IF;

  IF (NOT EXISTS(SELECT prj_id FROM prj WHERE prj_id=pPrjId)) THEN
    RETURN -3;
  END IF;

  IF (pDueDate IS NULL) THEN
    RETURN -4;
  END IF;

  SELECT (pDueDate - prj_due_date) INTO _offset
   FROM prj
   WHERE (prj_id=pPrjId);

  _teExists := EXISTS(SELECT 1 FROM pkghead WHERE pkghead_name='te');

  INSERT INTO prj
  ( prj_number, prj_name,
    prj_descrip, prj_status, prj_prjtype_id,
    prj_so, prj_wo, prj_po,
    prj_owner_username, prj_start_date,
    prj_due_date, prj_assigned_date, prj_completed_date,
    prj_username, prj_recurring_prj_id,
    prj_crmacct_id, prj_cntct_id )
  SELECT UPPER(pPrjNumber), pPrjName,
         prj_descrip, 'P', prj_prjtype_id,
         prj_so, prj_wo, prj_po,
         prj_owner_username, NULL,
         (prj_due_date + COALESCE(_offset, 0)),
         CASE WHEN (prj_username IS NULL) THEN NULL ELSE CURRENT_DATE END, NULL,
         prj_username, prj_recurring_prj_id,
         prj_crmacct_id, prj_cntct_id
  FROM prj
  WHERE (prj_id=pPrjId)
  RETURNING prj_id INTO _prjid;

  IF (_teExists) THEN
  -- Also insert TE billing information (if pkg exists)
    INSERT INTO te.teprj
      (teprj_prj_id, teprj_cust_id,
       teprj_rate, teprj_curr_id)
     SELECT _prjid, teprj_cust_id,
       teprj_rate, teprj_curr_id
     FROM te.teprj
     WHERE (teprj_prj_id = pPrjId);
  END IF;

  FOR _tasks IN
      SELECT task_id, task_due_date
        FROM task
       WHERE (task_parent_type='J' AND task_parent_id=pPrjId)
  LOOP
    SELECT copytask(_tasks.task_id, _tasks.task_due_date::DATE+COALESCE(_offset, 0)::INT,
                    'J', _prjid) INTO _newTaskid;

    IF (_teExists) THEN
    -- Also insert TE billing information (if pkg exists)
      INSERT INTO te.teprjtask
        ( teprjtask_cust_id, teprjtask_rate,
          teprjtask_item_id, teprjtask_prjtask_id,
          teprjtask_curr_id)
      SELECT teprjtask_cust_id, teprjtask_rate,       
             teprjtask_item_id, _newTaskid,
             teprjtask_curr_id
      FROM te.teprjtask
      WHERE (teprjtask_prjtask_id=_tasks.task_id);
      
    END IF; 
  END LOOP;          
   
  INSERT INTO docass
  ( docass_source_id, docass_source_type,
    docass_target_id, docass_target_type,
    docass_purpose )
  SELECT _prjid, docass_source_type,
         docass_target_id, docass_target_type,
         docass_purpose
  FROM docass
  WHERE ((docass_source_id=pPrjId)
    AND  (docass_source_type='J'));

  RETURN _prjid;

END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION copyproject(integer, text, text, date) OWNER TO admin;

