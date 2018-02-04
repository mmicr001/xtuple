CREATE OR REPLACE FUNCTION _dynamicfiltertrigger()
RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  NEW.dynamicfilter_filter = regexp_replace(NEW.dynamicfilter_filter, '(INSERT|UPDATE|DELETE)', '', 'ig');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS dynamicfiltertrigger ON dynamicfilter;

CREATE TRIGGER dynamicfiltertrigger
  BEFORE INSERT OR UPDATE
  ON dynamicfilter
  FOR EACH ROW
  EXECUTE PROCEDURE _dynamicfiltertrigger();
