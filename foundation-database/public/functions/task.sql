DROP FUNCTION IF EXISTS prjtask();
DROP FUNCTION IF EXISTS task();

CREATE OR REPLACE FUNCTION task() RETURNS SETOF task AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _priv TEXT;
  _grant BOOLEAN;

BEGIN

  CREATE TEMPORARY TABLE temptaskpriv (LIKE public.task) ON COMMIT DROP;

  -- Non-Project Task Privileges
  _priv := (SELECT array_to_string(array_agg(privilege),',') 
              FROM privgranted
             WHERE privilege IN ('MaintainAllProjects', 'ViewAllProjects', 'MaintainAllTaskItems', 'ViewAllTaskItems',
                                 'MaintainPersonalProjects', 'ViewPersonalProjects', 'MaintainPersonalTaskItems','ViewPersonalTaskItems')
               AND granted);

  IF (_priv ~ 'AllTask') THEN 
     INSERT INTO temptaskpriv
     SELECT task.* 
       FROM task
      WHERE NOT task_istemplate;
  ELSIF (_priv ~ 'AllProject') THEN
     INSERT INTO temptaskpriv
     SELECT task.* 
       FROM task
      WHERE task_parent_type = 'J'
        AND NOT task_istemplate;
  END IF;

  IF (_priv !~ 'AllTask' AND _priv ~ 'PersonalTask') THEN
     INSERT INTO temptaskpriv
     SELECT task.* 
       FROM task
      WHERE (getEffectiveXtUser() = task_owner_username
         OR task_id IN (SELECT taskass_task_id
                          FROM taskass
                         WHERE taskass_username = getEffectiveXtUser()))
        AND NOT task_istemplate;
  END IF;

  IF (_priv !~ 'All' AND _priv ~ 'PersonalProject') THEN
     INSERT INTO temptaskpriv
     SELECT task.* 
       FROM task
       JOIN prj ON prj_id = task_parent_id AND task_parent_type = 'J'
      WHERE getEffectiveXtUser() IN (prj_owner_username, prj_username)
        AND NOT task_istemplate;
  END IF;

  RETURN QUERY SELECT DISTINCT ON (task_id) * FROM temptaskpriv ORDER BY task_id;

  RETURN;

END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION task() IS 'A table function that returns Task results according to privilege settings.';
