CREATE OR REPLACE FUNCTION formatAvaTaxPayload(pOrderType      TEXT,
                                               pOrderNumber    TEXT,
                                               pFromLine1      TEXT,
                                               pFromLine2      TEXT,
                                               pFromLine3      TEXT,
                                               pFromCity       TEXT,
                                               pFromState      TEXT,
                                               pFromZip        TEXT,
                                               pFromCountry    TEXT,
                                               pToLine1        TEXT,
                                               pToLine2        TEXT,
                                               pToLine3        TEXT,
                                               pToCity         TEXT,
                                               pToState        TEXT,
                                               pToZip          TEXT,
                                               pToCountry      TEXT,
                                               pCustId         INTEGER,
                                               pCurrId         INTEGER,
                                               pDocDate        DATE,
                                               pFreight        NUMERIC,
                                               pMisc           NUMERIC,
                                               pFreightTaxtype TEXT,
                                               pMiscTaxtype    TEXT,
                                               pMiscDiscount   BOOLEAN,
                                               pLines          TEXT[],
                                               pQtys           NUMERIC[],
                                               pTaxTypes       TEXT[],
                                               pAmounts        NUMERIC[]) RETURNS JSONB AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _result JSONB;

BEGIN

  RETURN _result;

END
$$ language plpgsql;
