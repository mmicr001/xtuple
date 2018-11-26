CREATE OR REPLACE FUNCTION _itemtaxTrigger () RETURNS TRIGGER AS '
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

-- Privilege Checks
   IF (NOT checkPrivilege(''MaintainItemMasters'')) THEN
     RAISE EXCEPTION ''You do not have privileges to maintain Items.'';
   END IF;

  IF (NEW.itemtax_default) THEN
    UPDATE itemtax
       SET itemtax_default = FALSE
     WHERE itemtax_item_id = NEW.itemtax_item_id
       AND itemtax_id != NEW.itemtax_id;
  END IF;

  RETURN NEW;
END;
' LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS itemtaxTrigger ON itemtax;
CREATE TRIGGER itemtaxTrigger AFTER INSERT OR UPDATE ON itemtax FOR EACH ROW EXECUTE PROCEDURE _itemtaxTrigger();
