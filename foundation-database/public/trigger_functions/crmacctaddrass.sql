CREATE OR REPLACE FUNCTION crmacctaddrassupdated () RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  NEW.crmacctaddrass_lastupdated := now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'crmacctaddrassupdate');
CREATE TRIGGER crmacctaddrassupdate
  BEFORE UPDATE
  ON crmacctaddrass
  FOR EACH ROW
  EXECUTE PROCEDURE crmacctaddrassupdated();
