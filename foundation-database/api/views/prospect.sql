  DROP VIEW IF EXISTS api.prospect;

  CREATE OR REPLACE VIEW api.prospect AS
 
  SELECT 
    prospect_number::VARCHAR AS prospect_number,
    prospect_name AS prospect_name,
    prospect_active AS active,
    salesrep_number AS sales_rep,
    warehous_code AS site_code,
    taxzone_code AS default_tax_zone,
    prospect_comments AS notes,
    opsource_name AS source,
    cntct_number AS contact_number,
    cntct_honorific AS contact_honorific,
    cntct_first_name AS contact_first,
    cntct_middle AS contact_middle,
    cntct_last_name AS contact_last,
    cntct_suffix AS contact_suffix,
    cntct_title AS contact_job_title,
    getContactPhone(cntct_id, 'Office') AS contact_voice,
    getContactPhone(cntct_id, 'Mobile') AS contact_alternate,
    getContactPhone(cntct_id, 'Fax') AS contact_fax,
    cntct_email AS contact_email,
    cntct_webaddr AS contact_web,
    (''::TEXT) AS contact_change,
    addr_number AS contact_address_number,
    addr_line1 AS contact_address1,
    addr_line2 AS contact_address2,
    addr_line3 AS contact_address3,
    addr_city AS contact_city,
    addr_state AS contact_state,
    addr_postalcode AS contact_postalcode,
    addr_country AS contact_country,
    (''::TEXT) AS contact_address_change
  FROM
    prospect
      LEFT OUTER JOIN cntct ON (cntct_id=getcrmaccountcontact(prospect_crmacct_id))
      LEFT OUTER JOIN addr ON (cntct_addr_id=addr_id)
      LEFT OUTER JOIN taxzone ON (prospect_taxzone_id=taxzone_id)
      LEFT OUTER JOIN salesrep ON (prospect_salesrep_id=salesrep_id)
      LEFT OUTER JOIN opsource ON (prospect_source_id=opsource_id)
      LEFT OUTER JOIN whsinfo ON (prospect_warehous_id=warehous_id);

GRANT ALL ON TABLE api.prospect TO xtrole;
COMMENT ON VIEW api.prospect IS 'Prospect';

--Rules

CREATE OR REPLACE RULE "_INSERT" AS
    ON INSERT TO api.prospect DO INSTEAD

INSERT INTO prospect
	(
        prospect_number,
        prospect_name,
        prospect_active,
        prospect_taxzone_id,
        prospect_salesrep_id,
        prospect_warehous_id,
        prospect_source_id,
  	prospect_comments)
        VALUES (
        UPPER(NEW.prospect_number),
        COALESCE(NEW.prospect_name,''),
	COALESCE(NEW.active,true),
        getTaxZoneId(NEW.default_tax_zone),
        getSalesRepId(NEW.sales_rep),
        getWarehousId(NEW.site_code,'ACTIVE'),
        (SELECT opsource_id FROM opsource WHERE opsource_name=NEW.source),
        COALESCE(NEW.notes,''));

CREATE OR REPLACE RULE "_UPDATE" AS
    ON UPDATE TO api.prospect DO INSTEAD

UPDATE prospect SET
        prospect_number=UPPER(NEW.prospect_number),
        prospect_name=NEW.prospect_name,
	prospect_active=NEW.active,
        prospect_taxzone_id=getTaxZoneId(NEW.default_tax_zone),
        prospect_salesrep_id=getSalesRepId(NEW.sales_rep),
        prospect_warehous_id=getWarehousId(NEW.site_code,'ACTIVE'),
        prospect_source_id=(SELECT opsource_id FROM opsource WHERE opsource_name=NEW.source),
  	prospect_comments=NEW.notes
WHERE prospect_id=getProspectId(OLD.prospect_number);

CREATE OR REPLACE RULE "_DELETE" AS
    ON DELETE TO api.prospect DO INSTEAD
    DELETE FROM public.prospect WHERE (prospect_number=OLD.prospect_number);

