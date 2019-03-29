CREATE OR REPLACE FUNCTION qtyReserved(pItemsiteid INTEGER) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.

  SELECT COALESCE(SUM(coitem_qtyreserved),0)
    FROM coitem
   WHERE coitem_itemsite_id = pItemsiteid
     AND coitem_status <> ALL ('{X,C}'::bpchar[]);

$$ LANGUAGE sql STABLE;
