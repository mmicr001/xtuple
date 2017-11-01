CREATE OR REPLACE FUNCTION cntctaddrassupdated () RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  NEW.cntctaddrass_lastupdated := now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'cntctaddrassupdate');
CREATE TRIGGER cntctaddrassupdate
  BEFORE UPDATE
  ON cntctaddrass
  FOR EACH ROW
  EXECUTE PROCEDURE cntctaddrassupdated();
