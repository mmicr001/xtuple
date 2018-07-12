CREATE OR REPLACE FUNCTION _cobillBeforeTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE

BEGIN
  IF (TG_OP = 'DELETE') THEN
    DELETE FROM cobilltax
    WHERE (taxhist_parent_id=OLD.cobill_id);

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
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _r RECORD;

BEGIN
  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  END IF;

-- Cache Billing Head
  SELECT * INTO _r
  FROM cobmisc
  WHERE (cobmisc_id=NEW.cobill_cobmisc_id);
  IF (NOT FOUND) THEN
    RAISE EXCEPTION 'Billing head not found';
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
