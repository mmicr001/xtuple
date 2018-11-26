CREATE OR REPLACE FUNCTION crmacctcntctassupdated () RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  NEW.crmacctcntctass_lastupdated := now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS crmacctcntctassupdate ON crmacctcntctass;

CREATE TRIGGER crmacctcntctassupdate
  BEFORE UPDATE
  ON crmacctcntctass
  FOR EACH ROW
  EXECUTE PROCEDURE crmacctcntctassupdated();

CREATE OR REPLACE FUNCTION _crmaccntcntctassTriggerAfter() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _rec RECORD;
  _active TEXT;
BEGIN

-- Cache full-text information
  SELECT cntct_name, crmacct_number, crmrole_name,
         CASE WHEN NEW.crmacctcntctass_active THEN 'active'
              ELSE 'inactive' END AS active
    INTO _rec
    FROM crmacctcntctass
    JOIN cntct   ON cntct_id   = crmacctcntctass_cntct_id
    JOIN crmacct ON crmacct_id = crmacctcntctass_crmacct_id
    JOIN crmrole ON crmrole_id = crmacctcntctass_crmrole_id
   WHERE crmacctcntctass_id = NEW.crmacctcntctass_id;

--  Update Role Defaults on other contacts (for the same role)
  IF (NEW.crmacctcntctass_default) THEN
    UPDATE crmacctcntctass SET crmacctcntctass_default=FALSE
     WHERE crmacctcntctass_crmacct_id  = NEW.crmacctcntctass_crmacct_id
       AND  crmacctcntctass_cntct_id  != NEW.crmacctcntctass_cntct_id
       AND  crmacctcntctass_crmrole_id = NEW.crmacctcntctass_crmrole_id;
  END IF;

--  Record Contact assignments in the Contact changelog
  IF (TG_OP = 'INSERT' AND fetchMetricBool('ContactChangeLog')) THEN
    PERFORM postComment('ChangeLog', 'T', NEW.crmacctcntctass_cntct_id,
                        format('New Assignment: %s was assigned to Account %s with the role %s',
                               _rec.cntct_name, _rec.crmacct_number, _rec.crmrole_name));
  END IF;

  IF (TG_OP = 'UPDATE' AND fetchMetricBool('ContactChangeLog')) THEN
    IF (OLD.crmacctcntctass_crmrole_id != NEW.crmacctcntctass_crmrole_id) THEN
      PERFORM postComment('ChangeLog', 'T', NEW.crmacctcntctass_cntct_id,
                          format('Role Updated: %s role was changed to %s in Account %s',
                                 _rec.cntct_name, _rec.crmrole_name, _rec.crmacct_number));
    END IF;
    IF (OLD.crmacctcntctass_active != NEW.crmacctcntctass_active) THEN
      PERFORM postComment('ChangeLog', 'T', NEW.crmacctcntctass_cntct_id,
                          format('Role Updated: %s was marked as %s in Account %s',
                                 _rec.cntct_name, _rec.active, _rec.crmacct_number));
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS crmaccntcntctassTriggerAfter ON public.crmacctcntctass;

CREATE TRIGGER crmaccntcntctassTriggerAfter
  AFTER INSERT OR UPDATE
  ON crmacctcntctass
  FOR EACH ROW
  EXECUTE PROCEDURE _crmaccntcntctassTriggerAfter();

