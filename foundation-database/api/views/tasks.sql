-- Tasks
DROP VIEW IF EXISTS api.task;
DROP VIEW IF EXISTS api.tasks;

CREATE VIEW api.tasks
AS
   SELECT 
     CASE task_parent_type
      WHEN 'INCDT' THEN 'Incident'
      WHEN 'OPP'   THEN 'Opportunity'
      WHEN 'J'     THEN 'Project'
      WHEN 'CRMA'  THEN 'Account'
      WHEN 'T'     THEN 'Contact'
      ELSE 'Task'  END AS parent_type,
     COALESCE(prj_number, incdt_number::TEXT, ophead_name, crmacct_number, cntct_name, 'Task') AS parent,
     task_number,
     CASE task_status
       WHEN 'N' THEN 'New'
       WHEN 'D' THEN 'Deferred'
       WHEN 'P' THEN 'Pending'
       WHEN 'O' THEN 'In-Process'
       WHEN 'C' THEN 'Completed'
       ELSE          'Error' END AS status,
     task_name AS name,
     task_descrip AS description,
     incdtpriority_name AS priority,
     task_owner_username AS owner,
     taskassignment(task_id) AS assignments, 
     task_hours_budget AS hours_budgeted,
     task_hours_actual AS hours_actual,
     task_exp_budget AS expenses_budgeted,
     task_exp_actual AS expenses_actual,
     task_pct_complete AS percent_complete,
     task_due_date AS due,
     task_start_date AS started,
     task_completed_date AS completed,
     task_notes AS notes
   FROM task
    LEFT OUTER JOIN prj ON prj_id=task_parent_id AND task_parent_type = 'J'
    LEFT OUTER JOIN incdt ON incdt_id=task_parent_id AND task_parent_type = 'INCDT'
    LEFT OUTER JOIN ophead ON ophead_id=task_parent_id AND task_parent_type = 'OPP'
    LEFT OUTER JOIN crmacct ON crmacct_id=task_parent_id AND task_parent_type = 'CRMA'
    LEFT OUTER JOIN cntct ON cntct_id=task_parent_id AND task_parent_type = 'T'
    LEFT OUTER JOIN incdtpriority ON incdtpriority_id=task_priority_id;

GRANT ALL ON TABLE api.tasks TO xtrole;
COMMENT ON VIEW api.tasks IS 'Tasks';

--Rules

CREATE OR REPLACE RULE "_INSERT" AS
    ON INSERT TO api.tasks DO INSTEAD

  SELECT createtask (NEW.parent_type,
                     NEW.parent,
                     NEW.task_number,
                     NEW.status,
                     NEW.name,
                     NEW.description,
                     NEW.priority,
                     NEW.owner,
                     NEW.assignments,
                     NEW.hours_budgeted,
                     NEW.hours_actual,
                     NEW.expenses_budgeted,
                     NEW.expenses_actual,
                     NEW.percent_complete,
                     NEW.due::DATE,
                     NEW.started::DATE,
                     NEW.completed::DATE,
                     NEW.notes);

CREATE OR REPLACE RULE "_UPDATE" AS 
    ON UPDATE TO api.tasks DO INSTEAD

  SELECT updatetask (NEW.parent_type,
                     NEW.parent,
                     OLD.task_number,
                     NEW.task_number,
                     NEW.status,
                     NEW.name,
                     NEW.description,
                     NEW.priority,
                     NEW.owner,
                     NEW.assignments,
                     NEW.hours_budgeted,
                     NEW.hours_actual,
                     NEW.expenses_budgeted,
                     NEW.expenses_actual,
                     NEW.percent_complete,
                     NEW.due::DATE,
                     NEW.started::DATE,
                     NEW.completed::DATE,
                     NEW.notes);
           
CREATE OR REPLACE RULE "_DELETE" AS 
    ON DELETE TO api.tasks DO INSTEAD

  DELETE FROM task
  WHERE task_parent_type = CASE OLD.parent_type
                           WHEN 'Incident'    THEN 'INCDT'
                           WHEN 'Opportunity' THEN 'OPP'
                           WHEN 'Project'     THEN 'J'
                           WHEN 'Account'     THEN 'CRMA'
                           WHEN 'Contact'     THEN 'T'
                           ELSE 'TA'  END
    AND task_parent_id = CASE OLD.parent_type
                    WHEN 'Incident'    THEN getincidentid(OLD.parent::INTEGER)
                    WHEN 'Opportunity' THEN getopheadid(OLD.parent)
                    WHEN 'Project'     THEN getPrjId(OLD.parent)
                    WHEN 'Account'     THEN getcrmacctid(OLD.parent)
                    WHEN 'Contact'     THEN getcntctid(OLD.parent, false)
                    END
    AND task_number=OLD.task_number;
