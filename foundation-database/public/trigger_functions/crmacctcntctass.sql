CREATE OR REPLACE FUNCTION crmacctcntctassupdated () RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  NEW.crmacctcntctass_lastupdated := now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'crmacctcntctassupdate');
CREATE TRIGGER crmacctcntctassupdate
  BEFORE UPDATE
  ON crmacctcntctass
  FOR EACH ROW
  EXECUTE PROCEDURE crmacctcntctassupdated();
