CREATE OR REPLACE FUNCTION _vendtypeAfterTrigger () RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  IF (NEW.vendtype_default) THEN
    UPDATE vendtype SET vendtype_default = FALSE
    WHERE vendtype_id <> NEW.vendtype_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'vendtypeAfterTrigger');
CREATE TRIGGER vendtypeAfterTrigger
  AFTER INSERT OR UPDATE
  ON vendtype
  FOR EACH ROW
  EXECUTE PROCEDURE _vendtypeAfterTrigger();
