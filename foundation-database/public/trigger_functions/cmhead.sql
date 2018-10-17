CREATE OR REPLACE FUNCTION _cmheadBeforeTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _check BOOLEAN;
  _id INTEGER;
BEGIN
  -- Checks
  -- Start with privileges
  SELECT checkPrivilege('MaintainCreditMemos') INTO _check;
  IF ( (TG_OP = 'INSERT') OR (TG_OP = 'DELETE') ) THEN
    IF NOT (_check) THEN
      RAISE EXCEPTION 'You do not have privileges to maintain Credit Memos.';
    END IF;
  END IF;
  IF (TG_OP = 'UPDATE') THEN
    IF ((OLD.cmhead_printed = NEW.cmhead_printed) AND NOT (_check) ) THEN
      RAISE EXCEPTION 'You do not have privileges to maintain Credit Memos.';
    END IF;
  END IF;

  IF (TG_OP = 'DELETE') THEN
    DELETE FROM taxhead
     WHERE taxhead_doc_type = 'CM'
       AND taxhead_doc_id = OLD.cmhead_id;

    RETURN OLD;
  END IF;

  IF ( (NEW.cmhead_number IS NULL) OR (LENGTH(NEW.cmhead_number) = 0) ) THEN
    RAISE EXCEPTION 'You must enter a valid Memo # for this Credit Memo.';
  END IF;

  IF (TG_OP = 'INSERT') THEN
    SELECT cmhead_id INTO _id
    FROM cmhead
    WHERE (cmhead_number=NEW.cmhead_number);
    IF (FOUND) THEN
      RAISE EXCEPTION 'The Memo # is already in use.';
    END IF;

    IF (fetchMetricText('CMNumberGeneration') IN ('A','O')) THEN
      --- clear the number from the issue cache
      PERFORM clearNumberIssue('CmNumber', NEW.cmhead_number);
    ELSIF (fetchMetricText('CMNumberGeneration') = 'S') THEN
      --- clear the number from the issue cache
      PERFORM clearNumberIssue('SoNumber', NEW.cmhead_number);
    END IF;
  END IF;

  IF (NEW.cmhead_cust_id IS NOT NULL) THEN
    SELECT cust_id INTO _id
    FROM custinfo
    WHERE (cust_id=NEW.cmhead_cust_id);
    IF (NOT FOUND) THEN
      RAISE EXCEPTION 'You must enter a valid Customer # for this Credit Memo.';
    END IF;
  END IF;

  IF ( (NEW.cmhead_misc > 0) AND (NEW.cmhead_misc_accnt_id = -1) ) THEN
    RAISE EXCEPTION 'You may not enter a Misc. Charge without indicating the G/L Sales Account.';
  END IF;
  
  IF TG_OP IN ('INSERT', 'UPDATE') THEN
    NEW.cmhead_billtoaddress1   := COALESCE(NEW.cmhead_billtoaddress1, '');
    NEW.cmhead_billtoaddress2   := COALESCE(NEW.cmhead_billtoaddress2, '');
    NEW.cmhead_billtoaddress3   := COALESCE(NEW.cmhead_billtoaddress3, '');
    NEW.cmhead_billtocity       := COALESCE(NEW.cmhead_billtocity, '');
    NEW.cmhead_billtocountry    := COALESCE(NEW.cmhead_billtocountry, '');
    NEW.cmhead_billtostate      := COALESCE(NEW.cmhead_billtostate, '');
    NEW.cmhead_billtozip        := COALESCE(NEW.cmhead_billtozip, '');
    NEW.cmhead_shipto_address1  := COALESCE(NEW.cmhead_shipto_address1, '');
    NEW.cmhead_shipto_address2  := COALESCE(NEW.cmhead_shipto_address2, '');
    NEW.cmhead_shipto_address3  := COALESCE(NEW.cmhead_shipto_address3, '');
    NEW.cmhead_shipto_city      := COALESCE(NEW.cmhead_shipto_city, '');
    NEW.cmhead_shipto_country   := COALESCE(NEW.cmhead_shipto_country, '');
    NEW.cmhead_shipto_state     := COALESCE(NEW.cmhead_shipto_state, '');
    NEW.cmhead_shipto_zipcode   := COALESCE(NEW.cmhead_shipto_zipcode, '');
  END IF;

  IF (TG_OP = 'UPDATE' AND
      (NEW.cmhead_docdate != OLD.cmhead_docdate OR
       NEW.cmhead_curr_id != OLD.cmhead_curr_id OR
       NEW.cmhead_freight != OLD.cmhead_freight OR
       NEW.cmhead_freight_taxtype_id != OLD.cmhead_freight_taxtype_id OR
       NEW.cmhead_misc != OLD.cmhead_misc OR
       NEW.cmhead_misc_taxtype_id != OLD.cmhead_misc_taxtype_id OR
       NEW.cmhead_misc_discount != OLD.cmhead_misc_discount OR
       (fetchMetricText('TaxService') = 'N' AND
        NEW.cmhead_taxzone_id != OLD.cmhead_taxzone_id) OR
       (fetchMetricText('TaxService') != 'N' AND
        (NEW.cmhead_cust_id != OLD.cmhead_cust_id OR
         NEW.cmhead_warehous_id != OLD.cmhead_warehous_id OR
         NEW.cmhead_shipto_address1 != OLD.cmhead_shipto_address1 OR
         NEW.cmhead_shipto_address2 != OLD.cmhead_shipto_address2 OR
         NEW.cmhead_shipto_address3 != OLD.cmhead_shipto_address3 OR
         NEW.cmhead_shipto_city != OLD.cmhead_shipto_city OR
         NEW.cmhead_shipto_state != OLD.cmhead_shipto_state OR
         NEW.cmhead_shipto_zipcode != OLD.cmhead_shipto_zipcode OR
         NEW.cmhead_shipto_country != OLD.cmhead_shipto_country OR
         NEW.cmhead_tax_exemption != OLD.cmhead_tax_exemption)))) THEN
    UPDATE taxhead
       SET taxhead_valid = FALSE
     WHERE taxhead_doc_type = 'CM'
       AND taxhead_doc_id = NEW.cmhead_id;
  END IF;

  IF (TG_OP = 'UPDATE' AND NEW.cmhead_posted AND NOT OLD.cmhead_posted) THEN
    EXECUTE format('NOTIFY commit, %L', 'CM,' || OLD.cmhead_id);
  END IF;

  IF (TG_OP = 'UPDATE' AND NEW.cmhead_void AND NOT OLD.cmhead_void) THEN
    EXECUTE format('NOTIFY cancel, %L', 'CM,' || OLD.cmhead_id);
  END IF;

  IF (TG_OP = 'DELETE') THEN
    EXECUTE format('NOTIFY cancel, %L', 'CM,' || OLD.cmhead_id || ',' || OLD.cmhead_number);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropIfExists('TRIGGER', 'cmheadbeforetrigger');
CREATE TRIGGER cmheadbeforetrigger
  BEFORE INSERT OR UPDATE OR DELETE
  ON cmhead
  FOR EACH ROW
  EXECUTE PROCEDURE _cmheadBeforeTrigger();


CREATE OR REPLACE FUNCTION _cmheadTrigger() RETURNS "trigger" AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  IF (TG_OP = 'DELETE') THEN
    -- If this was created by a return, then reset the return
    IF (OLD.cmhead_rahead_id IS NOT NULL) THEN
      UPDATE rahead SET
        rahead_headcredited=false
      WHERE (rahead_id=OLD.cmhead_rahead_id);
      DELETE FROM rahist
      WHERE ((rahist_rahead_id=OLD.cmhead_rahead_id)
      AND (rahist_source='CM')
      AND (rahist_source_id=OLD.cmhead_id));
    END IF;
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

SELECT dropIfExists('TRIGGER', 'cmheadtrigger');
CREATE TRIGGER cmheadtrigger
  AFTER INSERT OR UPDATE OR DELETE
  ON cmhead
  FOR EACH ROW
  EXECUTE PROCEDURE _cmheadTrigger();
