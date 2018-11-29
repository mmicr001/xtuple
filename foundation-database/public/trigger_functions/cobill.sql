CREATE OR REPLACE FUNCTION _cobillBeforeTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE

BEGIN
  IF (TG_OP = 'DELETE') THEN
    UPDATE taxhead
       SET taxhead_valid = FALSE
     WHERE taxhead_doc_type = 'COB'
       AND taxhead_doc_id = OLD.cobill_cobmisc_id;

    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropIfExists('TRIGGER', 'cobillBeforeTrigger');
CREATE TRIGGER cobillBeforeTrigger
  BEFORE INSERT OR UPDATE OR DELETE
  ON cobill
  FOR EACH ROW
  EXECUTE PROCEDURE _cobillBeforeTrigger();

CREATE OR REPLACE FUNCTION _cobillTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  IF (TG_OP = 'INSERT' OR
      TG_OP = 'UPDATE' AND
      (NEW.cobill_qty != OLD.cobill_qty OR
       NEW.cobill_taxtype_id != OLD.cobill_taxtype_id OR
       (fetchMetricText('TaxService') != 'N' AND
        NEW.cobill_tax_exemption != OLD.cobill_tax_exemption))) THEN
    UPDATE taxhead
       SET taxhead_valid = FALSE
     WHERE taxhead_doc_type = 'COB'
       AND taxhead_doc_id = NEW.cobill_cobmisc_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropIfExists('TRIGGER', 'cobilltrigger');
CREATE TRIGGER cobilltrigger
  AFTER INSERT OR UPDATE OR DELETE
  ON cobill
  FOR EACH ROW
  EXECUTE PROCEDURE _cobillTrigger();
