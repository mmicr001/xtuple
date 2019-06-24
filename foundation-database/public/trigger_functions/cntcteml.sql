CREATE OR REPLACE FUNCTION cntctemlupdated () RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN

  NEW.cntcteml_lastupdated := now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'cntctemlupdate');
CREATE TRIGGER cntctemlupdate
  BEFORE UPDATE
  ON cntcteml
  FOR EACH ROW
  EXECUTE PROCEDURE cntctemlupdated();
