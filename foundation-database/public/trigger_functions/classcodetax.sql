CREATE OR REPLACE FUNCTION _classcodetaxTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  IF (NEW.classcodetax_default) THEN
    UPDATE classcodetax
       SET classcodetax_default = FALSE
     WHERE classcodetax_classcode_id = NEW.classcodetax_classcode_id
       AND classcodetax_id != NEW.classcodetax_id;
  END IF;

  RETURN NEW;

END;
$$ language plpgsql;

DROP TRIGGER IF EXISTS classcodetaxTrigger ON classcodetax;
CREATE TRIGGER classcodetaxTrigger
  AFTER INSERT OR UPDATE
  ON classcodetax
  FOR EACH ROW
  EXECUTE PROCEDURE _classcodetaxTrigger();
