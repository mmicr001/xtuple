CREATE OR REPLACE FUNCTION validateemailaddress(pEmail TEXT)
RETURNS BOOLEAN AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  IF (pEmail IS NULL OR pEmail = '') THEN
    RETURN TRUE;
  END IF;

  IF (fetchmetricbool('ValidateEmail')) THEN
    -- Basic regular expression check
    IF (fetchmetrictext('EmailValidatorMethod') = 'B') THEN
      RETURN pEmail ~ fetchmetrictext('EmailValidatorRegexp');
    END IF;
  END IF;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql STABLE;
