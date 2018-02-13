select xt.create_view('xt.cntctinfo', $$

 SELECT cntct.cntct_id,
    cntct.cntct_addr_id,
    cntct.cntct_first_name,
    cntct.cntct_last_name,
    cntct.cntct_honorific,
    cntct.cntct_initials,
    cntct.cntct_active,
    cntct.cntct_email,
    cntct.cntct_webaddr,
    cntct.cntct_notes,
    cntct.cntct_title,
    cntct.cntct_number,
    cntct.cntct_middle,
    cntct.cntct_suffix,
    cntct.cntct_owner_username,
    cntct.cntct_name,
    cntct.cntct_created,
    cntct.cntct_lastupdated,
    cntct.obj_uuid,
    NULL::INT AS contact_crmacct,
    NULL::TEXT AS crmacct_number,
    NULL::TEXT AS crmacct_parent_number,
    getcontactphone(cntct.cntct_id, 'Office'::text) AS contact_phone,
    getcontactphone(cntct.cntct_id, 'Mobile'::text) AS contact_phone2,
    getcontactphone(cntct.cntct_id, 'Fax'::text) AS contact_fax
   FROM cntct;

$$);


-- Rules:

CREATE OR REPLACE RULE "_INSERT" AS
    ON INSERT TO xt.cntctinfo DO INSTEAD  
  INSERT INTO cntct (cntct_id, 
                     cntct_number, 
                     cntct_first_name, 
                     cntct_middle, 
                     cntct_last_name, 
                     cntct_honorific, 
                     cntct_suffix, 
                     cntct_initials, 
                     cntct_active, 
                     cntct_notes, 
                     cntct_owner_username)
  VALUES (new.cntct_id, 
          new.cntct_number, 
          new.cntct_first_name, 
          new.cntct_middle, 
          new.cntct_last_name, 
          new.cntct_honorific, 
          new.cntct_suffix, 
          new.cntct_initials, 
          new.cntct_active, 
          new.cntct_notes, 
          new.cntct_owner_username)
  RETURNING cntct.cntct_id,
    cntct.cntct_addr_id,
    cntct.cntct_first_name,
    cntct.cntct_last_name,
    cntct.cntct_honorific,
    cntct.cntct_initials,
    cntct.cntct_active,
    cntct.cntct_email,
    cntct.cntct_webaddr,
    cntct.cntct_notes,
    cntct.cntct_title,
    cntct.cntct_number::TEXT,
    cntct.cntct_middle,
    cntct.cntct_suffix,
    cntct.cntct_owner_username,
    cntct.cntct_name,
    cntct.cntct_created,
    cntct.cntct_lastupdated,
    cntct.obj_uuid, -1, ''::TEXT,''::TEXT,''::TEXT,''::TEXT,''::TEXT;

CREATE OR REPLACE RULE "_UPDATE" AS
    ON UPDATE TO xt.cntctinfo DO INSTEAD  
  UPDATE cntct SET cntct_number = new.cntct_number, 
                   cntct_first_name = new.cntct_first_name, 
                   cntct_middle = new.cntct_middle, 
                   cntct_last_name = new.cntct_last_name, 
                   cntct_honorific = new.cntct_honorific, 
                   cntct_suffix = new.cntct_suffix, 
                   cntct_initials = new.cntct_initials, 
                   cntct_active = new.cntct_active, 
                   cntct_notes = new.cntct_notes, 
                   cntct_owner_username = new.cntct_owner_username
  WHERE cntct.cntct_id = old.cntct_id;

