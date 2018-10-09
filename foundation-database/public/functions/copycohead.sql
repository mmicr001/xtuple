CREATE OR REPLACE FUNCTION copycohead(pcoheadid INTEGER, pcodate DATE) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.

BEGIN
  IF packageIsEnabled('subscriptions') THEN
    --Check if this is a subscription and copy accordingly or do a standard copy.
    RETURN subscriptions.copySubscriptionSO(pcoheadid, pcodate);
  ELSE
    RETURN copyso(pcoheadid, null, pcodate);
  END IF;
END;
$$ LANGUAGE plpgsql;
