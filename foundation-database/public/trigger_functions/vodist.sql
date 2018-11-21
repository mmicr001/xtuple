CREATE OR REPLACE FUNCTION _vodistAfterTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  IF (TG_OP = 'DELETE') THEN
    UPDATE taxhead
       SET taxhead_valid = FALSE
     WHERE taxhead_doc_type = 'VCH'
       AND taxhead_doc_id = OLD.vodist_vohead_id;

    RETURN OLD;
  END IF;

  IF (TG_OP = 'INSERT' OR
      TG_OP = 'UPDATE' AND
      (NEW.vodist_amount != OLD.vodist_amount OR
       NEW.vodist_taxtype_id != OLD.vodist_taxtype_id OR
       (fetchMetricText('TaxService') != 'N' AND
        (NEW.vodist_warehous_id != OLD.vodist_warehous_id OR
        NEW.vodist_tax_exemption != OLD.vodist_tax_exemption)))) THEN
    UPDATE taxhead
       SET taxhead_valid = FALSE
     WHERE taxhead_doc_type = 'VCH'
       AND taxhead_doc_id = NEW.vodist_vohead_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropIfExists('TRIGGER', 'vodistAfterTrigger');
CREATE TRIGGER vodistAfterTrigger
  AFTER INSERT OR UPDATE OR DELETE
  ON vodist
  FOR EACH ROW
  EXECUTE PROCEDURE _vodistAfterTrigger();
