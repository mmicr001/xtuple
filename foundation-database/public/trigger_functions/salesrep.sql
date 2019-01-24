CREATE OR REPLACE FUNCTION _salesrepBeforeTrigger () RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  IF NOT (checkPrivilege('MaintainSalesReps')) THEN
    RAISE EXCEPTION 'You do not have privileges to maintain Sales Reps.';
  END IF;

  IF (TG_OP IN ('INSERT', 'UPDATE')) THEN
    IF (NEW.salesrep_number IS NULL) THEN
      RAISE EXCEPTION 'You must supply a valid Sales Rep Number.';
    END IF;

    IF (NEW.salesrep_commission IS NULL) THEN
      RAISE EXCEPTION 'You must supply a Commission Rate for this Sales Rep.';
    END IF;

    IF (TG_OP = 'INSERT' AND fetchMetricText('CRMAccountNumberGeneration') IN ('A','O') AND isNumeric(NEW.salesrep_number)) THEN
      --- clear the number from the issue cache
      PERFORM clearNumberIssue('CRMAccountNumber', NEW.salesrep_number);
    END IF;

    NEW.salesrep_number = UPPER(NEW.salesrep_number);

    IF (TG_OP = 'INSERT') THEN
      LOOP
        UPDATE crmacct SET crmacct_name=NEW.salesrep_name
         WHERE crmacct_number=NEW.salesrep_number
         RETURNING crmacct_id INTO NEW.salesrep_crmacct_id;
        IF (FOUND) THEN
          EXIT;
        END IF;
        BEGIN
          INSERT INTO crmacct(crmacct_number, crmacct_name, crmacct_active, crmacct_type)
          VALUES (NEW.salesrep_number, NEW.salesrep_name, NEW.salesrep_active, 'I')
          RETURNING crmacct_id INTO NEW.salesrep_crmacct_id;

          EXIT;
        EXCEPTION WHEN unique_violation THEN
              -- do nothing, and loop to try the UPDATE again
        END;
      END LOOP;
    END IF;

    -- TODO: default characteristic assignments?
  END IF;

  -- Timestamps
  IF (TG_OP = 'INSERT') THEN
    NEW.salesrep_created := now();
  ELSIF (TG_OP = 'UPDATE') THEN
    NEW.salesrep_lastupdated := now();
  ELSIF  (TG_OP = 'DELETE') THEN
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'salesrepBeforeTrigger');
CREATE TRIGGER salesrepBeforeTrigger BEFORE INSERT OR UPDATE OR DELETE ON salesrep
       FOR EACH ROW EXECUTE PROCEDURE _salesrepBeforeTrigger();

CREATE OR REPLACE FUNCTION _salesrepAfterTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  IF (TG_OP = 'UPDATE' AND OLD.salesrep_crmacct_id=NEW.salesrep_crmacct_id) THEN
    UPDATE crmacct SET crmacct_number = NEW.salesrep_number
    WHERE ((crmacct_id=NEW.salesrep_crmacct_id)
      AND  (crmacct_number!=NEW.salesrep_number));

    UPDATE crmacct SET crmacct_name = NEW.salesrep_name
    WHERE ((crmacct_id=NEW.salesrep_crmacct_id)
      AND  (crmacct_name!=NEW.salesrep_name));
  END IF;

  IF (fetchMetricBool('SalesRepChangeLog')) THEN
    IF (TG_OP = 'INSERT') THEN
      PERFORM postComment('ChangeLog', 'SR', NEW.salesrep_id, 'Created');

    ELSIF (TG_OP = 'UPDATE') THEN
      IF (OLD.salesrep_active <> NEW.salesrep_active) THEN
        PERFORM postComment('ChangeLog', 'SR', NEW.salesrep_id,
                            CASE WHEN NEW.salesrep_active THEN 'Activated'
                                 ELSE 'Deactivated' END);
      END IF;

      IF (OLD.salesrep_number <> NEW.salesrep_number) THEN
        PERFORM postComment('ChangeLog', 'SR', NEW.salesrep_id, 'Number',
                            OLD.salesrep_number, NEW.salesrep_number);
      END IF;

      IF (OLD.salesrep_name <> NEW.salesrep_name) THEN
        PERFORM postComment('ChangeLog', 'SR', NEW.salesrep_id, 'Name',
                            OLD.salesrep_name, NEW.salesrep_name);
      END IF;

      IF (OLD.salesrep_commission <> NEW.salesrep_commission) THEN
        PERFORM postComment('ChangeLog', 'SR', NEW.salesrep_id, 'Commission',
                            formatPrcnt(OLD.salesrep_commission), formatPrcnt(NEW.salesrep_commission));
      END IF;

      IF (OLD.salesrep_method <> NEW.salesrep_method) THEN
        PERFORM postComment('ChangeLog', 'SR', NEW.salesrep_id, 'Method',
                            OLD.salesrep_method, NEW.salesrep_method);
      END IF;

    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'salesrepAfterTrigger');
CREATE TRIGGER salesrepAfterTrigger AFTER INSERT OR UPDATE ON salesrep
       FOR EACH ROW EXECUTE PROCEDURE _salesrepAfterTrigger();

CREATE OR REPLACE FUNCTION _salesrepAfterDeleteTrigger() RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT fetchMetricValue('DefaultSalesRep') = OLD.salesrep_id) THEN
    RAISE EXCEPTION 'Cannot delete the default Sales Rep [xtuple: salesrep, -1, %]',
                    OLD.salesrep_number;
  END IF;

  PERFORM postComment('ChangeLog', 'SR', OLD.salesrep_id,
                      'Deleted "' || OLD.salesrep_number || '"');

  RETURN OLD;
END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS salesrepAfterDeleteTrigger ON salesrep;
CREATE TRIGGER salesrepAfterDeleteTrigger AFTER DELETE ON salesrep
       FOR EACH ROW EXECUTE PROCEDURE _salesrepAfterDeleteTrigger();
