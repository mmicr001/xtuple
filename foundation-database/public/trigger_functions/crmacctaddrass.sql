CREATE OR REPLACE FUNCTION crmacctaddrassupdated () RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
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
