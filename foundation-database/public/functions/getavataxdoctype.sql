CREATE OR REPLACE FUNCTION getAvaTaxDoctype(pOrderType TEXT) RETURNS TEXT AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  RETURN CASE pOrderType WHEN 'S' THEN 'SalesOrder'
                         WHEN 'INV' THEN 'SalesInvoice'
                         WHEN 'P' THEN 'SalesOrder'
                         WHEN 'VCH' THEN 'PurchaseInvoice'
                         WHEN 'CM' THEN 'ReturnInvoice'
                         WHEN 'EX' THEN 'PurchaseInvoice'
                         ELSE 'SalesOrder'
          END;

END
$$ language plpgsql;
