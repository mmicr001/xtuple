CREATE OR REPLACE FUNCTION _voitemBeforeTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE

BEGIN
  IF (TG_OP = 'DELETE') THEN
    UPDATE taxhead
       SET taxhead_valid = FALSE
     WHERE taxhead_doc_type = 'VCH'
       AND taxhead_doc_id = OLD.voitem_vohead_id;

    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropIfExists('TRIGGER', 'voitemBeforeTrigger');
CREATE TRIGGER voitemBeforeTrigger
  BEFORE INSERT OR UPDATE OR DELETE
  ON voitem
  FOR EACH ROW
  EXECUTE PROCEDURE _voitemBeforeTrigger();

CREATE OR REPLACE FUNCTION _voitemAfterTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN

  IF (TG_OP = 'INSERT' OR
      TG_OP = 'UPDATE' AND
      (NEW.voitem_qty != OLD.voitem_qty OR
       NEW.voitem_freight != OLD.voitem_freight OR
       NEW.voitem_taxtype_id != OLD.voitem_taxtype_id OR
       (fetchMetricText('TaxService') != 'N' AND
        NEW.voitem_tax_exemption != OLD.voitem_tax_exemption))) THEN
    UPDATE taxhead
       SET taxhead_valid = FALSE
     WHERE taxhead_doc_type = 'VCH'
       AND taxhead_doc_id = NEW.voitem_vohead_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropIfExists('TRIGGER', 'voitemAfterTrigger');
CREATE TRIGGER voitemAfterTrigger
  AFTER INSERT OR UPDATE OR DELETE
  ON voitem
  FOR EACH ROW
  EXECUTE PROCEDURE _voitemAfterTrigger();
