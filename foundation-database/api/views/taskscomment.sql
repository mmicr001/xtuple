-- Project Task Comment
--TODO allow this view to work for all Tasks

DROP VIEW IF EXISTS api.taskcomment;

CREATE VIEW api.taskcomment
AS 
   SELECT 
     prj_number::varchar AS project_number,
     task_number::varchar AS task_number,
     cmnttype_name AS type,
     comment_date AS date,
     comment_user AS username,
     comment_text AS text
   FROM prj
   JOIN  task ON prj_id=task_parent_id AND task_parent_type = 'J'
   JOIN  comment ON comment_source='TA' AND comment_source_id=task_id
   JOIN  cmnttype ON comment_cmnttype_id=cmnttype_id;

GRANT ALL ON TABLE api.taskcomment TO xtrole;
COMMENT ON VIEW api.taskcomment IS 'Task Comment';

--Rules

CREATE OR REPLACE RULE "_INSERT" AS
    ON INSERT TO api.taskcomment DO INSTEAD

  INSERT INTO comment (
    comment_date,
    comment_source,
    comment_source_id,
    comment_user,
    comment_cmnttype_id,
    comment_text
    )
  VALUES (
    COALESCE(NEW.date,now()),
    'TA',
    getTaskId(NEW.project_number,NEW.task_number),
    COALESCE(NEW.username,getEffectiveXtUser()),
    getCmntTypeId(NEW.type),
    NEW.text);

CREATE OR REPLACE RULE "_UPDATE" AS
    ON UPDATE TO api.taskcomment DO INSTEAD NOTHING;

CREATE OR REPLACE RULE "_DELETE" AS
    ON DELETE TO api.taskcomment DO INSTEAD NOTHING;
