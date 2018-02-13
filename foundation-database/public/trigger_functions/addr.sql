CREATE OR REPLACE FUNCTION _addrtrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
  DECLARE
    _uses	INTEGER	:= 0;

  BEGIN

    IF (TG_OP = 'INSERT') THEN
      --- clear the number from the issue cache
      PERFORM clearNumberIssue('AddressNumber', NEW.addr_number);
    ELSE
      SELECT count(*) INTO _uses
      FROM cntct
      WHERE ((cntct_addr_id=OLD.addr_id)
        AND   cntct_active);
    END IF;

    IF (TG_OP = 'UPDATE') THEN
      IF (OLD.addr_active AND NOT NEW.addr_active AND _uses > 0) THEN
	RAISE EXCEPTION 'Cannot inactivate Address with Active Contacts (%)',
			_uses;
      END IF;
      NEW.addr_lastupdated = now();
    ELSIF (TG_OP = 'DELETE') THEN
      IF (_uses > 0) THEN
	RAISE EXCEPTION 'Cannot Delete Address with Active Contacts (%)',
			_uses;
      END IF;

      UPDATE cntct SET cntct_addr_id = NULL
      WHERE ((cntct_addr_id=OLD.addr_id)
	AND  (NOT cntct_active));

      RETURN OLD;
    END IF;

    RETURN NEW;
  END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS addrtrigger ON addr;
CREATE TRIGGER addrtrigger
  BEFORE  INSERT OR
	  UPDATE OR DELETE
  ON addr
  FOR EACH ROW
  EXECUTE PROCEDURE _addrtrigger();

CREATE OR REPLACE FUNCTION _addrAfterDeleteTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE

BEGIN

  DELETE
  FROM charass
  WHERE charass_target_type = 'ADDR'
    AND charass_target_id = OLD.addr_id;

  RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropIfExists('TRIGGER', 'addrAfterDeleteTrigger');
CREATE TRIGGER addrAfterDeleteTrigger
  AFTER DELETE
  ON addr
  FOR EACH ROW
  EXECUTE PROCEDURE _addrAfterDeleteTrigger();


CREATE OR REPLACE FUNCTION _addraftertrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  IF (fetchMetricBool('AddressChangeLog')) THEN
    IF (TG_OP = 'INSERT') THEN
      PERFORM postComment('ChangeLog', 'ADDR', NEW.addr_id, 'Created');
    ELSIF (TG_OP = 'UPDATE') THEN
      IF (OLD.addr_active <> NEW.addr_active) THEN
        PERFORM postComment('ChangeLog', 'ADDR', NEW.addr_id,
                            CASE WHEN NEW.addr_active THEN 'Activated'
                                 ELSE 'Deactivated' END);
      END IF;

      IF ((OLD.addr_line1 <> NEW.addr_line1) 
          OR (OLD.addr_line2 <> NEW.addr_line2) 
          OR (OLD.addr_line3 <> NEW.addr_line3) 
          OR (OLD.addr_city <> NEW.addr_city) 
          OR (OLD.addr_state <> NEW.addr_state) 
          OR (OLD.addr_country <> NEW.addr_country) 
          OR (OLD.addr_postalcode <> NEW.addr_postalcode)) THEN
            PERFORM postComment('ChangeLog', 'ADDR', NEW.addr_id,
                            'Address Updated:' || E'\n' || formataddr(NEW.addr_id));
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'addrAfterTrigger');
CREATE TRIGGER addrAfterTrigger
  AFTER INSERT OR UPDATE
  ON addr
  FOR EACH ROW
  EXECUTE PROCEDURE _addraftertrigger();
