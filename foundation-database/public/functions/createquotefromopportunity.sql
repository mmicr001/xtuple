CREATE OR REPLACE FUNCTION createQuoteFromOpportunity(pOpheadId INTEGER)
RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  quoteid   INTEGER;
BEGIN

INSERT INTO quhead (quhead_imported, quhead_cust_id,  quhead_quotedate,
                    quhead_ordercomments, quhead_prj_id, quhead_curr_id,
                    quhead_status)
  SELECT true, COALESCE(cust_id, prospect_id), CURRENT_DATE,
         ophead_name, ophead_prj_id, ophead_curr_id, 'O'
  FROM ophead
  LEFT JOIN custinfo ON cust_crmacct_id=ophead_crmacct_id
  LEFT JOIN prospect ON prospect_crmacct_id=ophead_crmacct_id
  WHERE ophead_id = pOpHeadId
  ON CONFLICT DO NOTHING
  RETURNING quhead_id INTO quoteid;

  IF (quoteid IS NULL) THEN
    RAISE EXCEPTION 'There was an error creating the Quote [xtuple: createQuoteFromOpportunity, -1]';
  END IF;

-- Create document link between Opportunity and Quote
  INSERT INTO docass (docass_source_id, docass_source_type, docass_target_type, docass_target_id,
                      docass_purpose, docass_username)
  VALUES (quoteid, 'Q', 'OPP', pOpHeadId, 'S', geteffectivextuser());

  RETURN quoteid;
END;
$$ LANGUAGE plpgsql;
