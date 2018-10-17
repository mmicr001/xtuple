CREATE OR REPLACE FUNCTION _invcheadBeforeTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _recurid     INTEGER;
  _newparentid INTEGER;

BEGIN
  IF (TG_OP = 'UPDATE') THEN
    IF (OLD.invchead_posted
      AND ((OLD.invchead_invcnumber != NEW.invchead_invcnumber)
        OR (OLD.invchead_invcdate != NEW.invchead_invcdate)
        OR (OLD.invchead_terms_id != NEW.invchead_terms_id)
        OR (OLD.invchead_salesrep_id != NEW.invchead_salesrep_id)
        OR (OLD.invchead_commission != NEW.invchead_commission)
        OR (OLD.invchead_taxzone_id != NEW.invchead_taxzone_id)
        OR (OLD.invchead_shipchrg_id != NEW.invchead_shipchrg_id)
        OR (OLD.invchead_prj_id != NEW.invchead_prj_id)
        OR (OLD.invchead_misc_accnt_id != NEW.invchead_misc_accnt_id)
        OR (OLD.invchead_misc_amount != NEW.invchead_misc_amount)
        OR (OLD.invchead_freight != NEW.invchead_freight))) THEN
      RAISE EXCEPTION 'Edit not allow on Posted Invoice.';
    END IF;
  END IF;

  IF TG_OP IN ('INSERT', 'UPDATE') THEN
    NEW.invchead_billto_address1 := COALESCE(NEW.invchead_billto_address1, '');
    NEW.invchead_billto_address2 := COALESCE(NEW.invchead_billto_address2, '');
    NEW.invchead_billto_address3 := COALESCE(NEW.invchead_billto_address3, '');
    NEW.invchead_billto_city     := COALESCE(NEW.invchead_billto_city, '');
    NEW.invchead_billto_state    := COALESCE(NEW.invchead_billto_state, '');
    NEW.invchead_billto_zipcode  := COALESCE(NEW.invchead_billto_zipcode, '');
    NEW.invchead_shipto_address1 := COALESCE(NEW.invchead_shipto_address1, '');
    NEW.invchead_shipto_address2 := COALESCE(NEW.invchead_shipto_address2, '');
    NEW.invchead_shipto_address3 := COALESCE(NEW.invchead_shipto_address3, '');
    NEW.invchead_shipto_city     := COALESCE(NEW.invchead_shipto_city, '');
    NEW.invchead_shipto_state    := COALESCE(NEW.invchead_shipto_state, '');
    NEW.invchead_shipto_zipcode  := COALESCE(NEW.invchead_shipto_zipcode, '');
    NEW.invchead_billto_country  := COALESCE(NEW.invchead_billto_country, '');
    NEW.invchead_shipto_country  := COALESCE(NEW.invchead_shipto_country, '');
  END IF;

  IF (TG_OP = 'UPDATE' AND
      (NEW.invchead_invcdate != OLD.invchead_invcdate OR
       NEW.invchead_curr_id != OLD.invchead_curr_id OR
       NEW.invchead_freight != OLD.invchead_freight OR
       NEW.invchead_freight_taxtype_id != OLD.invchead_freight_taxtype_id OR
       NEW.invchead_misc_amount != OLD.invchead_misc_amount OR
       NEW.invchead_misc_taxtype_id != OLD.invchead_misc_taxtype_id OR
       NEW.invchead_misc_discount != OLD.invchead_misc_discount OR
       (fetchMetricText('TaxService') = 'N' AND
        NEW.invchead_taxzone_id != OLD.invchead_taxzone_id) OR
       (fetchMetricText('TaxService') != 'N' AND
        (NEW.invchead_cust_id != OLD.invchead_cust_id OR
         NEW.invchead_warehous_id != OLD.invchead_warehous_id OR
         NEW.invchead_shipto_address1 != OLD.invchead_shipto_address1 OR
         NEW.invchead_shipto_address2 != OLD.invchead_shipto_address2 OR
         NEW.invchead_shipto_address3 != OLD.invchead_shipto_address3 OR
         NEW.invchead_shipto_city != OLD.invchead_shipto_city OR
         NEW.invchead_shipto_state != OLD.invchead_shipto_state OR
         NEW.invchead_shipto_zipcode != OLD.invchead_shipto_zipcode OR
         NEW.invchead_shipto_country != OLD.invchead_shipto_country OR
         NEW.invchead_tax_exemption != OLD.invchead_tax_exemption)))) THEN
    UPDATE taxhead
       SET taxhead_valid = FALSE
     WHERE taxhead_doc_type = 'INV'
       AND taxhead_doc_id = NEW.invchead_id;
  END IF;

  IF (TG_OP = 'UPDATE' AND NEW.invchead_posted AND NOT OLD.invchead_posted) THEN
    EXECUTE format('NOTIFY commit, %L', 'INV,' || OLD.invchead_id);
  END IF;

  IF (TG_OP = 'UPDATE' AND NEW.invchead_void AND NOT OLD.invchead_void) THEN
    EXECUTE format('NOTIFY cancel, %L', 'INV,' || OLD.invchead_id);
  END IF;

  IF (TG_OP = 'DELETE') THEN
    EXECUTE format('NOTIFY cancel, %L', 'INV,' || OLD.invchead_id ||
                                        ',' || OLD.invchead_invcnumber);
  END IF;

  IF (TG_OP = 'DELETE') THEN
    SELECT recur_id INTO _recurid
      FROM recur
     WHERE ((recur_parent_id=OLD.invchead_id)
        AND (recur_parent_type='I'));
    IF (_recurid IS NOT NULL) THEN
      SELECT invchead_id INTO _newparentid
        FROM invchead
       WHERE ((invchead_recurring_invchead_id=OLD.invchead_id)
          AND (invchead_id!=OLD.invchead_id))
       ORDER BY invchead_invcdate
       LIMIT 1;

      IF (_newparentid IS NULL) THEN
        DELETE FROM recur WHERE recur_id=_recurid;
      ELSE
        UPDATE recur SET recur_parent_id=_newparentid
         WHERE recur_id=_recurid;
        UPDATE invchead SET invchead_recurring_invchead_id=_newparentid
         WHERE invchead_recurring_invchead_id=OLD.invchead_id
           AND invchead_id!=OLD.invchead_id;
      END IF;
    END IF;

    RETURN OLD;
  END IF;

  -- Timestamps
  IF (TG_OP = 'INSERT') THEN
    NEW.invchead_created := now();
  ELSIF (TG_OP = 'UPDATE') THEN
    NEW.invchead_lastupdated := now();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'invcheadBeforeTrigger');
CREATE TRIGGER invcheadBeforeTrigger
  BEFORE INSERT OR UPDATE OR DELETE
  ON invchead
  FOR EACH ROW
  EXECUTE PROCEDURE _invcheadBeforeTrigger();

CREATE OR REPLACE FUNCTION _invcheadTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  IF (TG_OP = 'DELETE') THEN
    -- Something can go here
    RETURN OLD;
  END IF;

-- Insert new row
  IF (TG_OP = 'INSERT') THEN
    --- clear the number from the issue cache
    PERFORM clearNumberIssue('InvcNumber', NEW.invchead_invcnumber);

    PERFORM postComment('ChangeLog', 'INV', NEW.invchead_id, 'Created');
  END IF;

-- Update row
  IF (TG_OP = 'UPDATE') THEN
    IF ( (COALESCE(NEW.invchead_taxzone_id,-1) <> COALESCE(OLD.invchead_taxzone_id,-1)) OR
         (NEW.invchead_invcdate <> OLD.invchead_invcdate) OR
         (NEW.invchead_curr_id <> OLD.invchead_curr_id) ) THEN
  -- Calculate invcitem Tax
      IF (fetchMetricText('TaxService') = 'N' AND COALESCE(NEW.invchead_taxzone_id,-1) <> COALESCE(OLD.invchead_taxzone_id,-1)) THEN

        UPDATE invcitem SET invcitem_taxtype_id=getItemTaxType(invcitem_item_id,NEW.invchead_taxzone_id)
        WHERE (invcitem_invchead_id=NEW.invchead_id);
      END IF;
    END IF;

    -- Record changes
    PERFORM postComment('ChangeLog', 'INV', NEW.invchead_id, 'Last Updated');
    IF (OLD.invchead_invcdate <> NEW.invchead_invcdate) THEN
        PERFORM postComment( 'ChangeLog', 'INV', NEW.invchead_id, 'Invoice Date', formatDate(OLD.invchead_invcdate), formatDate(NEW.invchead_invcdate));
    END IF;
    IF (OLD.invchead_terms_id <> NEW.invchead_terms_id) THEN
        PERFORM postComment( 'ChangeLog', 'INV', NEW.invchead_id, 'Terms',
                             (SELECT terms_code FROM terms WHERE terms_id=OLD.invchead_terms_id),
                             (SELECT terms_code FROM terms WHERE terms_id=NEW.invchead_terms_id));
    END IF;
    IF (OLD.invchead_saletype_id <> NEW.invchead_saletype_id) THEN
        PERFORM postComment( 'ChangeLog', 'INV', NEW.invchead_id, 'Sale Type',
                             (SELECT saletype_code FROM saletype WHERE saletype_id=OLD.invchead_saletype_id),
                             (SELECT saletype_code FROM saletype WHERE saletype_id=NEW.invchead_saletype_id));
    END IF;
    IF (OLD.invchead_salesrep_id <> NEW.invchead_salesrep_id) THEN
        PERFORM postComment( 'ChangeLog', 'INV', NEW.invchead_id, 'Sales Rep',
                             (SELECT salesrep_name FROM salesrep WHERE salesrep_id=OLD.invchead_salesrep_id),
                             (SELECT salesrep_name FROM salesrep WHERE salesrep_id=NEW.invchead_salesrep_id));
    END IF;
    IF (OLD.invchead_commission <> NEW.invchead_commission) THEN
        PERFORM postComment( 'ChangeLog', 'INV', NEW.invchead_id, 'Commission',
                             formatprcnt(OLD.invchead_commission),
                             formatprcnt(NEW.invchead_commission));
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'invcheadtrigger');
CREATE TRIGGER invcheadtrigger
  AFTER INSERT OR UPDATE OR DELETE
  ON invchead
  FOR EACH ROW
  EXECUTE PROCEDURE _invcheadTrigger();


CREATE OR REPLACE FUNCTION _invcheadaftertrigger()
  RETURNS trigger AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
  DECLARE
    _cohead_id INTEGER;

  BEGIN
--  Create a comment entry when on a Sales Order when an Invoice is Posted for that order
    IF (TG_OP = 'UPDATE') THEN
      IF ((OLD.invchead_posted != NEW.invchead_posted) AND NEW.invchead_posted) THEN
        SELECT cohead_id INTO _cohead_id
        FROM cohead
        WHERE (cohead_number = OLD.invchead_ordernumber);
        IF (FOUND) THEN
          PERFORM postComment('ChangeLog', 'S', _cohead_id,
                              ('Invoice, ' || NEW.invchead_invcnumber || ', posted for this order') );
        END IF;
      END IF;
    END IF;

  RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'invcheadaftertrigger');
CREATE TRIGGER invcheadaftertrigger
  AFTER UPDATE
  ON invchead
  FOR EACH ROW
  EXECUTE PROCEDURE _invcheadaftertrigger();

CREATE OR REPLACE FUNCTION _invcheadAfterDeleteTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE

BEGIN

  DELETE
  FROM charass
  WHERE charass_target_type = 'INV'
    AND charass_target_id = OLD.invchead_id;

  DELETE FROM taxhead
   WHERE taxhead_doc_type = 'INV'
     AND taxhead_doc_id = OLD.invchead_id;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'invcheadAfterDeleteTrigger');
CREATE TRIGGER invcheadAfterDeleteTrigger
  AFTER DELETE
  ON invchead
  FOR EACH ROW
  EXECUTE PROCEDURE _invcheadAfterDeleteTrigger();
