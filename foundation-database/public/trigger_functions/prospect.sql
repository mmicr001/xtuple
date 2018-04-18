CREATE OR REPLACE FUNCTION _prospectTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _custid       INTEGER;
  _prospectid   INTEGER;
BEGIN
  IF (NOT checkPrivilege('MaintainProspectMasters')) THEN
    RAISE EXCEPTION 'You do not have privileges to maintain Prospects.';
  END IF;

  IF (NEW.prospect_number IS NULL) THEN
    RAISE EXCEPTION 'You must supply a valid Prospect Number.';
  END IF;

  NEW.prospect_number := UPPER(NEW.prospect_number);

  -- Timestamps
  IF (TG_OP = 'INSERT') THEN
    NEW.prospect_created := now();
  ELSIF (TG_OP = 'UPDATE') THEN
    NEW.prospect_lastupdated := now();
  END IF;

  IF (TG_OP = 'INSERT') THEN
    SELECT cust_id, prospect_id INTO _custid, _prospectid
      FROM crmacct
      LEFT OUTER JOIN custinfo ON (cust_crmacct_id=crmacct_id)
      LEFT OUTER JOIN prospect ON (prospect_crmacct_id=crmacct_id)
    WHERE crmacct_number=NEW.prospect_number;

    IF (_custid > 0 AND _custid != _prospectid) THEN
      RAISE EXCEPTION '[xtuple: createProspect, -2]';
    END IF;

    IF (_prospectid > 0) THEN
      RAISE EXCEPTION '[xtuple: createProspect, -3]';
    END IF;

    LOOP
      UPDATE crmacct SET crmacct_name=NEW.prospect_name
       WHERE crmacct_number=NEW.prospect_number
       RETURNING crmacct_id INTO NEW.prospect_crmacct_id;
      IF (FOUND) THEN
        EXIT;
      END IF;
      BEGIN
        INSERT INTO crmacct(crmacct_number,      crmacct_name,
                            crmacct_active,      crmacct_type ) 
                    VALUES (NEW.prospect_number, NEW.prospect_name,
                            NEW.prospect_active, 'O')
        RETURNING crmacct_id INTO NEW.prospect_crmacct_id;    
      EXIT;
        EXCEPTION WHEN unique_violation THEN
            -- do nothing, and loop to try the UPDATE again
      END;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('trigger', 'prospectTrigger');
CREATE TRIGGER prospectTrigger BEFORE INSERT OR UPDATE ON prospect
       FOR EACH ROW EXECUTE PROCEDURE _prospectTrigger();

CREATE OR REPLACE FUNCTION _prospectAfterTrigger () RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  IF (TG_OP = 'INSERT') THEN

    /* TODO: default characteristic assignments based on what? */

  ELSIF (TG_OP = 'UPDATE' AND OLD.prospect_crmacct_id=NEW.prospect_crmacct_id) THEN
    UPDATE crmacct SET crmacct_number = NEW.prospect_number
    WHERE ((crmacct_id=NEW.prospect_crmacct_id)
      AND  (crmacct_number!=NEW.prospect_number));

    UPDATE crmacct SET crmacct_name = NEW.prospect_name
    WHERE ((crmacct_id=NEW.prospect_crmacct_id)
      AND  (crmacct_name!=NEW.prospect_name));

  END IF;

  IF (fetchMetricBool('ProspectChangeLog')) THEN
    IF (TG_OP = 'INSERT') THEN
      PERFORM postComment('ChangeLog', 'PSPCT', NEW.prospect_id, 'Created');

    ELSIF (TG_OP = 'UPDATE') THEN
      IF (OLD.prospect_active <> NEW.prospect_active) THEN
        PERFORM postComment('ChangeLog', 'PSPCT', NEW.prospect_id,
                            CASE WHEN NEW.prospect_active THEN 'Activated'
                                 ELSE 'Deactivated' END);
      END IF;

      IF (OLD.prospect_number <> NEW.prospect_number) THEN
        PERFORM postComment('ChangeLog', 'PSPCT', NEW.prospect_id, 'Number',
                            OLD.prospect_number, NEW.prospect_number);
      END IF;

      IF (OLD.prospect_owner_username <> NEW.prospect_owner_username) THEN
        PERFORM postComment('ChangeLog', 'PSPCT', NEW.prospect_id, 'Owner',
                            OLD.prospect_owner_username, NEW.prospect_owner_username);
      END IF;

      IF (OLD.prospect_assigned_username <> NEW.prospect_assigned_username) THEN
        PERFORM postComment('ChangeLog', 'PSPCT', NEW.prospect_id, 'Assigned To',
                            OLD.prospect_assigned_username, NEW.prospect_assigned_username);
      END IF;

      IF (OLD.prospect_assigned <> NEW.prospect_assigned) THEN
        PERFORM postComment('ChangeLog', 'PSPCT', NEW.prospect_id, 'Assigned',
                            formatDate(OLD.prospect_assigned), formatDate(NEW.prospect_assigned));
      END IF;

      IF (OLD.prospect_lasttouch <> NEW.prospect_lasttouch) THEN
        PERFORM postComment('ChangeLog', 'PSPCT', NEW.prospect_id, 'Last Touched',
                            formatDate(OLD.prospect_lasttouch), formatDate(NEW.prospect_lasttouch));
      END IF;

      IF (OLD.prospect_name <> NEW.prospect_name) THEN
        PERFORM postComment('ChangeLog', 'PSPCT', NEW.prospect_id, 'Name',
                            OLD.prospect_name, NEW.prospect_name);
      END IF;

      IF (OLD.prospect_source_id <> NEW.prospect_source_id) THEN
        PERFORM postComment('ChangeLog', 'PSPCT', NEW.prospect_id, 'Source',
                            (SELECT opsource_name FROM opsource WHERE opsource_id=OLD.prospect_source_id),
                            (SELECT opsource_name FROM opsource WHERE opsource_id=NEW.prospect_source_id));
      END IF;

      IF (OLD.prospect_salesrep_id <> NEW.prospect_salesrep_id) THEN
        PERFORM postComment('ChangeLog', 'PSPCT', NEW.prospect_id, 'Sales Rep',
                            (SELECT salesrep_number FROM salesrep WHERE salesrep_id=OLD.prospect_salesrep_id),
                            (SELECT salesrep_number FROM salesrep WHERE salesrep_id=NEW.prospect_salesrep_id));
      END IF;

      IF (OLD.prospect_warehous_id <> NEW.prospect_warehous_id) THEN
        PERFORM postComment('ChangeLog', 'PSPCT', NEW.prospect_id, 'Warehouse',
                            (SELECT warehous_code FROM whsinfo WHERE warehous_id=OLD.prospect_warehous_id),
                            (SELECT warehous_code FROM whsinfo WHERE warehous_id=NEW.prospect_warehous_id));
      END IF;

      IF (OLD.prospect_taxzone_id <> NEW.prospect_taxzone_id) THEN
        PERFORM postComment('ChangeLog', 'PSPCT', NEW.prospect_id, 'Tax Zone',
                            (SELECT taxzone_code FROM taxzone WHERE taxzone_id=OLD.prospect_taxzone_id),
                            (SELECT taxzone_code FROM taxzone WHERE taxzone_id=NEW.prospect_taxzone_id));
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'prospectAfterTrigger');
CREATE TRIGGER prospectAfterTrigger AFTER INSERT OR UPDATE ON prospect
       FOR EACH ROW EXECUTE PROCEDURE _prospectAfterTrigger();

CREATE OR REPLACE FUNCTION _prospectBeforeDeleteTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  IF (NOT checkPrivilege('MaintainProspectMasters')) THEN
    RAISE EXCEPTION 'You do not have privileges to maintain Prospects.';
  END IF;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('trigger', 'prospectBeforeDeleteTrigger');
CREATE TRIGGER prospectBeforeDeleteTrigger BEFORE DELETE ON prospect
       FOR EACH ROW EXECUTE PROCEDURE _prospectBeforeDeleteTrigger();

CREATE OR REPLACE FUNCTION _prospectAfterDeleteTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  IF EXISTS(SELECT 1 FROM quhead WHERE quhead_cust_id = OLD.prospect_id) AND
     NOT EXISTS (SELECT 1 FROM custinfo WHERE cust_id = OLD.prospect_id) THEN
    RAISE EXCEPTION '[xtuple: deleteProspect, -1]';
  END IF;

  IF (fetchMetricBool('ProspectChangeLog')) THEN
    PERFORM postComment('ChangeLog', 'PSPCT', OLD.prospect_id,
                        'Deleted "' || OLD.prospect_number || '"');
  END IF;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'prospectAfterDeleteTrigger');
CREATE TRIGGER prospectAfterDeleteTrigger AFTER DELETE ON prospect
       FOR EACH ROW EXECUTE PROCEDURE _prospectAfterDeleteTrigger();
