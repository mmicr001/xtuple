CREATE OR REPLACE FUNCTION _incdtpriorityaftertrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN

  IF (NEW.incdtpriority_default) THEN
    UPDATE incdtpriority SET incdtpriority_default = FALSE
    WHERE incdtpriority_id <> NEW.incdtpriority_id;
  END IF;

  RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS incdtpriorityaftertrigger ON incdtpriority;

CREATE TRIGGER incdtpriorityaftertrigger
  AFTER INSERT OR UPDATE
  ON incdtpriority
  FOR EACH ROW
  EXECUTE PROCEDURE _incdtpriorityaftertrigger();
