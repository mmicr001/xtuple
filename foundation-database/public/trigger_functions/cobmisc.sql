CREATE OR REPLACE FUNCTION _cobmiscTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  IF (TG_OP = 'DELETE') THEN
    -- Something can go here
    RETURN OLD;
  END IF;

-- Update row
  IF (TG_OP = 'UPDATE') THEN

  -- Calculate Tax
    IF (COALESCE(NEW.cobmisc_taxzone_id,-1) <> COALESCE(OLD.cobmisc_taxzone_id,-1)) THEN
      UPDATE cobill SET cobill_taxtype_id=getItemTaxType(itemsite_item_id,NEW.cobmisc_taxzone_id)
      FROM coitem
        JOIN itemsite ON (coitem_itemsite_id=itemsite_id)
      WHERE ((coitem_id=cobill_coitem_id)
       AND (cobill_cobmisc_id=NEW.cobmisc_id));
    END IF;
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
