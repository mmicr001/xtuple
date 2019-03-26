-- Before trigger
CREATE OR REPLACE FUNCTION _cntctTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  NEW.cntct_name := formatCntctName(NULL, NEW.cntct_first_name, NEW.cntct_middle, NEW.cntct_last_name, NEW.cntct_suffix);
  IF (TG_OP = 'UPDATE' AND NEW.cntct_email = '') THEN
    -- Delete the Contact email address
    DELETE FROM cntcteml WHERE cntcteml_cntct_id=NEW.cntct_id
                         AND   cntcteml_email=OLD.cntct_email;
  END IF;
  NEW.cntct_email := lower(NEW.cntct_email);

  -- Validate Email Address
  IF (NOT validateEmailAddress(NEW.cntct_email)) THEN
    RAISE EXCEPTION 'An invalid email address was entered (%). Please check and correct. [xtuple: cntctEmailValid, -1, %]', NEW.cntct_email, NEW.cntct_email;
  END IF;

  -- Unique Email check
  IF (fetchmetricbool('EnforceUniqueContactEmails') AND
      EXISTS(SELECT 1 FROM cntcteml WHERE cntcteml_email = NEW.cntct_email
                                      AND  cntcteml_cntct_id <> NEW.cntct_id)
     ) THEN
    RAISE EXCEPTION 'Emails are required to be unique.  You cannot use this email more than once. [xtuple: cntctEmailUnique, -1]';
  END IF;

  IF (TG_OP = 'INSERT') THEN
    --- clear the number from the issue cache
    PERFORM clearNumberIssue('ContactNumber', NEW.cntct_number);
  END IF;

  -- Timestamps
  IF (TG_OP = 'INSERT') THEN
    NEW.cntct_created := now();
  ELSIF (TG_OP = 'UPDATE') THEN
    NEW.cntct_lastupdated := now();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'cntctTrigger');
CREATE TRIGGER cntcttrigger
  BEFORE INSERT OR UPDATE
  ON cntct
  FOR EACH ROW
  EXECUTE PROCEDURE _cntctTrigger();

-- Before Delete trigger
CREATE OR REPLACE FUNCTION _cntctTriggerBeforeDelete() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  IF (TG_OP = 'DELETE') THEN
    DELETE FROM cntcteml  WHERE cntcteml_cntct_id=OLD.cntct_id;
    DELETE FROM docass WHERE docass_source_id = OLD.cntct_id AND docass_source_type = 'T';
    DELETE FROM docass WHERE docass_target_id = OLD.cntct_id AND docass_target_type = 'T';

    -- these have denormalized cntct info so it should be ok to update them
    UPDATE cohead SET cohead_billto_cntct_id=NULL
     WHERE cohead_billto_cntct_id=OLD.cntct_id;
    UPDATE cohead SET cohead_shipto_cntct_id=NULL
     WHERE cohead_shipto_cntct_id=OLD.cntct_id;

    UPDATE pohead SET pohead_vend_cntct_id=NULL
     WHERE pohead_vend_cntct_id=OLD.cntct_id;
    UPDATE pohead SET pohead_shipto_cntct_id=NULL
     WHERE pohead_shipto_cntct_id=OLD.cntct_id;

    UPDATE quhead SET quhead_billto_cntct_id=NULL
     WHERE quhead_billto_cntct_id=OLD.cntct_id;
    UPDATE quhead SET quhead_shipto_cntct_id=NULL
     WHERE quhead_shipto_cntct_id=OLD.cntct_id;

    IF (fetchMetricBool('MultiWhs')) THEN
      UPDATE tohead SET tohead_destcntct_id=NULL
       WHERE tohead_destcntct_id=OLD.cntct_id;
      UPDATE tohead SET tohead_srccntct_id=NULL
       WHERE tohead_srccntct_id=OLD.cntct_id;
    END IF;

  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'cntctTriggerBeforeDelete');
CREATE TRIGGER cntcttriggerbeforedelete
  BEFORE DELETE
  ON cntct
  FOR EACH ROW
  EXECUTE PROCEDURE _cntctTriggerBeforeDelete();

-- After Delete trigger
CREATE OR REPLACE FUNCTION _cntctAfterDeleteTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE

BEGIN

  DELETE FROM charass
   WHERE charass_target_type = 'CNTCT'
     AND charass_target_id = OLD.cntct_id;
  DELETE FROM comment
   WHERE (comment_source_id=OLD.cntct_id AND comment_source = 'T');
  DELETE FROM docass
   WHERE (docass_source_id=OLD.cntct_id AND docass_source_type = 'T')
      OR (docass_target_id=OLD.cntct_id AND docass_target_type = 'T');

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'cntctAfterDeleteTrigger');
CREATE TRIGGER cntctAfterDeleteTrigger
  AFTER DELETE
  ON cntct
  FOR EACH ROW
  EXECUTE PROCEDURE _cntctAfterDeleteTrigger();

-- After trigger
CREATE OR REPLACE FUNCTION _cntctTriggerAfter() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _cntctemlid INTEGER;
  _rows INTEGER;
BEGIN
  IF (TG_OP = 'INSERT') THEN
    IF(length(coalesce(NEW.cntct_email,'')) > 0) THEN
      INSERT INTO cntcteml (
        cntcteml_cntct_id, cntcteml_primary, cntcteml_email )
      VALUES (
        NEW.cntct_id, true, NEW.cntct_email );
    END IF;
    IF (fetchMetricBool('ContactChangeLog')) THEN
      PERFORM postComment('ChangeLog', 'T', NEW.cntct_id, 'Created');
    END IF;
  ELSIF (TG_OP = 'UPDATE') THEN
    IF (OLD.cntct_email != NEW.cntct_email AND length(coalesce(NEW.cntct_email,'')) > 0) THEN
      SELECT cntcteml_id INTO _cntctemlid
      FROM cntcteml
      WHERE ((cntcteml_cntct_id=NEW.cntct_id)
        AND (cntcteml_email=NEW.cntct_email));

      GET DIAGNOSTICS _rows = ROW_COUNT;
      IF (_rows = 0) THEN
        UPDATE cntcteml SET
          cntcteml_primary=false
        WHERE ((cntcteml_cntct_id=NEW.cntct_id)
         AND (cntcteml_primary=true));

        INSERT INTO cntcteml (
          cntcteml_cntct_id, cntcteml_primary, cntcteml_email )
        VALUES (
          NEW.cntct_id, true, NEW.cntct_email );
      ELSE
        UPDATE cntcteml SET
          cntcteml_primary=false
        WHERE ((cntcteml_cntct_id=NEW.cntct_id)
         AND (cntcteml_primary=true));

        UPDATE cntcteml SET
          cntcteml_primary=true
        WHERE (cntcteml_id=_cntctemlid);
      END IF;
      IF (fetchMetricBool('ContactChangeLog')) THEN
        PERFORM postComment('ChangeLog', 'T', NEW.cntct_id, 'Primary Email', OLD.cntct_email, NEW.cntct_email);
      END IF;
    END IF;

    IF (TG_OP = 'UPDATE' AND fetchMetricBool('ContactChangeLog')) THEN
      IF (OLD.cntct_title != NEW.cntct_title) THEN
        PERFORM postComment('ChangeLog', 'T', NEW.cntct_id, 'Job Title', OLD.cntct_title, NEW.cntct_title);
      END IF;
      IF (OLD.cntct_owner_username != '' AND OLD.cntct_owner_username != NEW.cntct_owner_username) THEN
        PERFORM postComment('ChangeLog', 'T', NEW.cntct_id, 'Owner', OLD.cntct_owner_username, NEW.cntct_owner_username);
      END IF;
      IF (OLD.cntct_name != NEW.cntct_name) THEN
        PERFORM postComment('ChangeLog', 'T', NEW.cntct_id, 'Name', OLD.cntct_name, NEW.cntct_name);
      END IF;
      IF (OLD.cntct_webaddr != NEW.cntct_webaddr) THEN
        PERFORM postComment('ChangeLog', 'T', NEW.cntct_id, 'Name', OLD.cntct_webaddr, NEW.cntct_webaddr);
      END IF;
      IF (OLD.cntct_addr_id != NEW.cntct_addr_id) THEN
        PERFORM postComment('ChangeLog', 'T', NEW.cntct_id, 'Name', formataddr(OLD.cntct_addr_id), formataddr(NEW.cntct_addr_id));
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'cntctTriggerAfter');
CREATE TRIGGER cntcttriggerafter
  AFTER INSERT OR UPDATE OR DELETE
  ON cntct
  FOR EACH ROW
  EXECUTE PROCEDURE _cntctTriggerAfter();

