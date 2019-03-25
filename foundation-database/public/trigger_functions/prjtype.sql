CREATE OR REPLACE FUNCTION _prjtypeAfterTrigger () RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  IF (NEW.prjtype_default) THEN
    UPDATE prjtype SET prjtype_default = FALSE
    WHERE prjtype_id <> NEW.prjtype_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'prjtypeAfterTrigger');
CREATE TRIGGER prjtypeAfterTrigger
  AFTER INSERT OR UPDATE
  ON prjtype
  FOR EACH ROW
  EXECUTE PROCEDURE _prjtypeAfterTrigger();
