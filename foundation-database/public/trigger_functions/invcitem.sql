CREATE OR REPLACE FUNCTION _invcitemBeforeTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _itemfractional BOOLEAN;

BEGIN
  IF (TG_OP = 'UPDATE') THEN
    IF (SELECT COUNT(invchead_id) > 0
        FROM invchead
        WHERE ((invchead_id=OLD.invcitem_invchead_id)
          AND (invchead_posted))) THEN
      RAISE EXCEPTION 'Edit not allowed on Posted Invoices.';
    END IF;
  END IF;

  -- If regular Item then enforce item_fractional
  IF (COALESCE(NEW.invcitem_item_id, -1) <> -1) THEN
    SELECT itemuomfractionalbyuom(NEW.invcitem_item_id, NEW.invcitem_qty_uom_id) INTO _itemfractional;
    IF (NOT _itemfractional) THEN
      IF (TRUNC(NEW.invcitem_ordered) <> NEW.invcitem_ordered) THEN
        RAISE EXCEPTION 'Item does not support fractional quantities';
      END IF;
      IF (TRUNC(NEW.invcitem_billed) <> NEW.invcitem_billed) THEN
        RAISE EXCEPTION 'Item does not support fractional quantities';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropIfExists('TRIGGER', 'invcitemBeforeTrigger');
CREATE TRIGGER invcitemBeforeTrigger
  BEFORE INSERT OR UPDATE
  ON invcitem
  FOR EACH ROW
  EXECUTE PROCEDURE _invcitemBeforeTrigger();

CREATE OR REPLACE FUNCTION _invcitemTrigger() RETURNS trigger AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
-- Insert new row
  IF (TG_OP = 'INSERT') THEN
      PERFORM postComment('ChangeLog', 'INVI', NEW.invcitem_id, 'Created');
  END IF;

-- Update row
  IF (TG_OP = 'UPDATE') THEN
  -- Record Changes
    IF (NEW.invcitem_billed <> OLD.invcitem_billed) THEN
       PERFORM postComment('ChangeLog', 'INVI', NEW.invcitem_id, 'Billed Qty',
                            formatQty(OLD.invcitem_billed), formatQty(NEW.invcitem_billed));
    END IF;
    IF (NEW.invcitem_price <> OLD.invcitem_price) THEN
      PERFORM postComment('ChangeLog', 'INVI', NEW.invcitem_id, 'Price',
                           formatPrice(OLD.invcitem_price), formatPrice(NEW.invcitem_price));
    END IF;
    IF (NEW.invcitem_taxtype_id <> OLD.invcitem_taxtype_id) THEN
      PERFORM postComment('ChangeLog', 'INVI', NEW.invcitem_id, 'Tax Type',
                          (SELECT taxtype_name FROM taxtype WHERE taxtype_id=OLD.invcitem_taxtype_id),
                          (SELECT taxtype_name FROM taxtype WHERE taxtype_id=NEW.invcitem_taxtype_id));
    END IF;
    IF (NEW.invcitem_rev_accnt_id <> OLD.invcitem_rev_accnt_id) THEN
      PERFORM postComment('ChangeLog', 'INVI', NEW.invcitem_id, 'Revenue Account',
                          (SELECT accnt_name FROM accnt WHERE accnt_id=OLD.invcitem_rev_accnt_id),
                          (SELECT accnt_name FROM accnt WHERE accnt_id=NEW.invcitem_rev_accnt_id));
    END IF;
    IF (OLD.invcitem_item_id <> -1 AND NEW.invcitem_salescat_id > 0) THEN
      PERFORM postComment('ChangeLog', 'INVI', NEW.invcitem_id, 'Switched Item to Misc:',
                          (SELECT item_number FROM item WHERE item_id=OLD.invcitem_item_id),
                          (SELECT salescat_name FROM salescat WHERE salescat_id=NEW.invcitem_salescat_id));
    END IF;
    IF (OLD.invcitem_salescat_id > 0 AND NEW.invcitem_item_id <> -1) THEN
      PERFORM postComment('ChangeLog', 'INVI', NEW.invcitem_id, 'Switched Misc to Item:',
                          (SELECT salescat_name FROM salescat WHERE salescat_id=OLD.invcitem_salescat_id),
                          (SELECT item_number FROM item WHERE item_id=NEW.invcitem_item_id));
    END IF;
    IF (OLD.invcitem_salescat_id > 0 AND NEW.invcitem_salescat_id <> OLD.invcitem_salescat_id) THEN
      PERFORM postComment('ChangeLog', 'INVI', NEW.invcitem_id, 'Sales Category',
                          (SELECT salescat_name FROM salescat WHERE salescat_id=OLD.invcitem_salescat_id),
                          (SELECT salescat_name FROM salescat WHERE salescat_id=NEW.invcitem_salescat_id));
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropIfExists('TRIGGER', 'invcitemtrigger');
CREATE TRIGGER invcitemtrigger
  AFTER INSERT OR UPDATE
  ON invcitem
  FOR EACH ROW
  EXECUTE PROCEDURE _invcitemTrigger();
