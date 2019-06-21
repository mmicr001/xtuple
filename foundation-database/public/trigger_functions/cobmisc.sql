CREATE OR REPLACE FUNCTION _cobmiscBeforeTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE

BEGIN
  IF (TG_OP = 'DELETE') THEN
    DELETE FROM taxhead
     WHERE taxhead_doc_type = 'COB'
       AND taxhead_doc_id = OLD.cobmisc_id;

    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropIfExists('TRIGGER', 'cobmiscBeforeTrigger');
CREATE TRIGGER cobmiscBeforeTrigger
  BEFORE INSERT OR UPDATE OR DELETE
  ON cobmisc
  FOR EACH ROW
  EXECUTE PROCEDURE _cobmiscBeforeTrigger();

CREATE OR REPLACE FUNCTION _cobmiscTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN
  IF (TG_OP = 'DELETE') THEN
    -- Something can go here
    RETURN OLD;
  END IF;

-- Update row
  IF (TG_OP = 'UPDATE') THEN

  -- Calculate Tax
    IF (fetchMetricText('TaxService') = 'N' AND COALESCE(NEW.cobmisc_taxzone_id,-1) <> COALESCE(OLD.cobmisc_taxzone_id,-1)) THEN
      UPDATE cobill SET cobill_taxtype_id=getItemTaxType(itemsite_item_id,NEW.cobmisc_taxzone_id)
      FROM coitem
        JOIN itemsite ON (coitem_itemsite_id=itemsite_id)
      WHERE ((coitem_id=cobill_coitem_id)
       AND (cobill_cobmisc_id=NEW.cobmisc_id));
    END IF;
  END IF;

  IF (TG_OP = 'UPDATE' AND
      (NEW.cobmisc_freight != OLD.cobmisc_freight OR
       NEW.cobmisc_freight_taxtype_id != OLD.cobmisc_freight_taxtype_id OR
       NEW.cobmisc_misc != OLD.cobmisc_misc OR
       NEW.cobmisc_misc_taxtype_id != OLD.cobmisc_misc_taxtype_id OR
       NEW.cobmisc_misc_discount != OLD.cobmisc_misc_discount OR
       (fetchMetricText('TaxService') = 'N' AND
        NEW.cobmisc_taxzone_id != OLD.cobmisc_taxzone_id) OR
       (fetchMetricText('TaxService') != 'N' AND
        NEW.cobmisc_tax_exemption != OLD.cobmisc_tax_exemption))) THEN
    UPDATE taxhead
       SET taxhead_valid = FALSE
     WHERE taxhead_doc_type = 'COB'
       AND taxhead_doc_id = NEW.cobmisc_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropIfExists('TRIGGER', 'cobmisctrigger');
CREATE TRIGGER cobmisctrigger
  AFTER INSERT OR UPDATE OR DELETE
  ON cobmisc
  FOR EACH ROW
  EXECUTE PROCEDURE _cobmiscTrigger();
