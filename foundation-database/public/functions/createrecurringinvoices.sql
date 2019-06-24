CREATE OR REPLACE FUNCTION createRecurringInvoices() RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
BEGIN
  RAISE WARNING 'createRecurringInvoices() has been deprecated; use createRecurringItems(NULL, ''I'') instead.';

  RETURN createRecurringItems(NULL, 'I');
END;
$$ LANGUAGE 'plpgsql';
