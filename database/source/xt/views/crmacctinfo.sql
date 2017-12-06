/*
 * This view is a fudge to allow the core public.crmacct table to have deprecated columns removed.
 * yet still allow the XM views to remain working
 */
select  xt.create_view('xt.crmacctinfo', $$

SELECT crmacct_id,
  crmacct_number,
  crmacct_name,
  crmacct_active,
  crmacct_type,
  getcrmaccountcontact(crmacct_id, 'Primary') AS primary_contact,
  getcrmaccountcontact(crmacct_id, 'Secondary') AS secondary_contact,
  crmacct_parent_id,
  crmacct_notes,
  crmacct_owner_username,
  crmacct_usr_username,
  crmacct_created,
  crmacct_lastupdated
FROM crmacct c 

$$);     


--Rules

CREATE OR REPLACE RULE "_INSERT" AS
    ON INSERT TO xt.crmacctinfo DO INSTEAD

INSERT INTO crmacct
	(crmacct_id,
         crmacct_number,
         crmacct_name,
         crmacct_active,
         crmacct_type,
         crmacct_parent_id,
         crmacct_notes,
         crmacct_owner_username,
         crmacct_usr_username)
        VALUES
        (NEW.crmacct_id,
         NEW.crmacct_number,
         NEW.crmacct_name,
         NEW.crmacct_active,
         NEW.crmacct_type,
         NEW.crmacct_parent_id,
         NEW.crmacct_notes,
         NEW.crmacct_owner_username,
         NEW.crmacct_usr_username);

CREATE OR REPLACE RULE "_INSERT_CNTCT1" AS
    ON INSERT TO xt.crmacctinfo DO INSTEAD INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id )
                                           SELECT new.crmacct_id, new.primary_contact, getcrmroleid('Primary')
                                            WHERE new.crmacct_id IS NOT NULL AND new.primary_contact IS NOT NULL;
CREATE OR REPLACE RULE "_INSERT_CNTCT2" AS
    ON INSERT TO xt.crmacctinfo DO INSTEAD INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id )
                                           SELECT new.crmacct_id, new.secondary_contact, getcrmroleid('Secondary')
                                            WHERE new.crmacct_id IS NOT NULL AND new.secondary_contact IS NOT NULL;
CREATE OR REPLACE RULE "_UPDATE" AS
    ON UPDATE TO xt.crmacctinfo DO INSTEAD

UPDATE crmacct SET
         crmacct_id=NEW.crmacct_id,
         crmacct_number=NEW.crmacct_number,
         crmacct_name=NEW.crmacct_name,
         crmacct_active=NEW.crmacct_active,
         crmacct_type=NEW.crmacct_type,
         crmacct_parent_id=NEW.crmacct_parent_id,
         crmacct_notes=NEW.crmacct_notes,
         crmacct_owner_username=NEW.crmacct_owner_username,
         crmacct_usr_username=NEW.crmacct_usr_username
  WHERE (crmacct_id=OLD.crmacct_id);

CREATE OR REPLACE RULE "_DELETE" AS
    ON DELETE TO xt.crmacctinfo DO INSTEAD
  DELETE FROM crmacct WHERE crmacct_id = OLD.crmacct_id;

