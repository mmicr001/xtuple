CREATE OR REPLACE FUNCTION _taxheadTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  IF fetchMetricText('TaxService') = 'N' THEN
    PERFORM saveTax(taxhead_doc_type, taxhead_doc_id,
                    calculateOrderTax(taxhead_doc_type,taxhead_doc_id));
  END IF;

  RETURN NEW;

END;
$$ language plpgsql;

DROP TRIGGER IF EXISTS taxheadTrigger ON taxhead;
CREATE TRIGGER taxheadTrigger
  AFTER UPDATE
  ON taxhead
  FOR EACH ROW
  EXECUTE PROCEDURE _taxheadTrigger();
