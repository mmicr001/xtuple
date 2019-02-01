CREATE OR REPLACE FUNCTION convertCustomerToProspect(INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pCustId     ALIAS FOR $1;
  _c          RECORD;
BEGIN
  SELECT * INTO _c
  FROM custinfo
  WHERE (cust_id=pCustId);

  INSERT INTO prospect (
        prospect_id, prospect_crmacct_id, prospect_active, prospect_number,
        prospect_name, prospect_taxzone_id,
        prospect_salesrep_id, prospect_warehous_id, prospect_comments
  ) VALUES (
       _c.cust_id, _c.cust_crmacct_id, _c.cust_active, _c.cust_number,
       _c.cust_name, _c.cust_taxzone_id,
       CASE WHEN(_c.cust_salesrep_id > 0) THEN _c.cust_salesrep_id
            ELSE NULL
       END,
       CASE WHEN(_c.cust_preferred_warehous_id > 0) THEN _c.cust_preferred_warehous_id
            ELSE NULL
       END,
       _c.cust_comments);

  IF (_c.cust_cntct_id IS NOT NULL) THEN
    INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id, crmacctcntctass_crmrole_id)
        SELECT _c.cust_crmacct_id, _c.cust_cntct_id, getcrmroleid()
        WHERE NOT EXISTS(SELECT 1 FROM crmacctcntctass WHERE (crmacctcntctass_crmacct_id=_c.cust_crmacct_id
                                                         AND  crmacctcntctass_cntct_id=_c.cust_cntct_id));
  END IF;

  UPDATE charass SET charass_target_type = 'PSPCT'
  WHERE charass_target_type = 'C'
    AND charass_target_id = pCustId
    AND charass_char_id IN (SELECT charuse_char_id FROM charuse WHERE charuse_target_type = 'PSPCT');

  DELETE FROM custinfo WHERE (cust_id=pCustId);

  RETURN pCustId;
END;
$$ LANGUAGE 'plpgsql';
