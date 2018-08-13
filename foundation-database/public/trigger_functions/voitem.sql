CREATE OR REPLACE FUNCTION _voitemBeforeTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2015 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE

BEGIN
  IF (TG_OP = 'DELETE') THEN
    DELETE FROM voitemtax
    WHERE (taxhist_parent_id=OLD.voitem_id);

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
-- Copyright (c) 1999-2015 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _r RECORD;

BEGIN
  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  END IF;

-- Cache Voucher Head
  SELECT * INTO _r
  FROM vohead
  WHERE (vohead_id=NEW.voitem_vohead_id);
  IF (NOT FOUND) THEN
    RAISE EXCEPTION 'Voucher head not found';
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
