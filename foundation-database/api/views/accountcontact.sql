
-- Account - Contact Assignment

SELECT dropIfExists('VIEW', 'accountcontact', 'api');

CREATE OR REPLACE VIEW api.accountcontact AS 

  SELECT crmacct_number AS account_number,
         cntct_number   AS contact_number,
         crmrole_name   AS crm_role
  FROM crmacctcntctass
  JOIN crmacct ON crmacct_id=crmacctcntctass_crmacct_id
  JOIN cntct ON cntct_id=crmacctcntctass_cntct_id
  JOIN crmrole ON crmrole_id=crmacctcntctass_crmrole_id;

GRANT ALL ON TABLE api.accountcontact TO xtrole;
COMMENT ON VIEW api.accountcontact IS 'Account to Contact assignment';

-- Rules

CREATE OR REPLACE RULE "_INSERT" AS 
    ON INSERT TO api.accountcontact DO INSTEAD

  INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, 
                               crmacctcntctass_cntct_id, 
                               crmacctcntctass_crmrole_id)
  VALUES (getCrmAcctId(NEW.account_number),
          getCntctId(NEW.contact_number),
          getCrmRoleId(NEW.crm_role));

CREATE OR REPLACE RULE "_UPDATE" AS
    ON UPDATE TO api.accountcontact DO INSTEAD

    UPDATE crmacctcntctass SET crmacctcntctass_cntct_id =  getCntctId(NEW.contact_number)
    WHERE crmacctcntctass_crmacct_id=getCrmAcctId(NEW.account_number)
    AND   crmacctcntctass_crmrole_id=getCrmRoleId(NEW.crm_role);

CREATE OR REPLACE RULE "_DELETE" AS
    ON DELETE TO api.accountcontact DO INSTEAD

    DELETE FROM crmacctcntctass 
    WHERE crmacctcntctass_crmacct_id=getCrmAcctId(OLD.account_number)
    AND   crmacctcntctass_cntct_id=getCntctId(OLD.contact_number)
    AND   crmacctcntctass_crmrole_id=getCrmRoleId(OLD.crm_role);
