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
  _transactionType TEXT;
  _rec             RECORD;
  _payload         TEXT;
  _numlines        INTEGER;
BEGIN

  _transactionType := (CASE pordertype
                       WHEN 'S' THEN 'SalesOrder'
                       WHEN 'INV' THEN 'SalesInvoice'
                       WHEN 'P' THEN 'PurchaseOrder'
                       WHEN 'V' THEN 'PurchaseInvoice'
                       ELSE 'SalesOrder' END);

  IF (fetchMetricBool('NoAvaTaxCommit')) THEN
    _transactionType := replace(_transactionType, 'Invoice', 'Order');
  END IF;

  _numlines := COALESCE(array_length(pLines, 1), 0);

  SELECT cust_number, (SELECT taxreg_number FROM taxreg WHERE taxreg_rel_type = 'C'
                                                          AND taxreg_rel_id = pcustid
                                                          AND CURRENT_DATE BETWEEN taxreg_effective AND taxreg_expires
                                                          LIMIT 1) AS taxreg
  INTO _rec
  FROM  custinfo
  WHERE cust_id = pcustid;

  _payload = format('{ "createTransactionModel": {
    "type": "%s",
    "code": "%s",
    "companyCode": "%s",
    "date": "%s",
    "customerCode": "%s",
    "businessIdentificationNo": "%s",
    "addresses": {
        "shipFrom": {
            "line1": "%s",
            "line2": "%s",
            "line3": "%s",
            "city": "%s",
            "region": "%s",
            "country": "%s",
            "postalCode": "%s"
        },
        "shipTo": {
            "line1": "%s",
            "line2": "%s",
            "line3": "%s",
            "city": "%s",
            "region": "%s",
            "country": "%s",
            "postalCode": "%s"
        }
    },
    "commit": false,
    "currencyCode": "%s",
    "description": "%s",
    "discount": %s,
    "lines": [',
    _transactionType,
    pordernumber,
    fetchmetrictext('AvalaraCompany'),
    pdocdate,
    _rec.cust_number,
    COALESCE(_rec.taxreg, ' '),
    pfromline1,
    pfromline2,
    pfromline3,
    pfromcity,
    pfromstate,
    pfromcountry,
    pfromzip,
    ptoline1,
    ptoline2,
    ptoline3,
    ptocity,
    ptostate,
    ptocountry,
    ptozip,
    (SELECT curr_abbr FROM curr_symbol WHERE curr_id=pcurrid),
    'xTuple-' || _transactionType,
    CASE WHEN pMiscDiscount AND pMisc < 0 THEN pMisc * -1 ELSE 0 END);

  FOR _line IN 1.._numlines
  LOOP
   _payload = _payload ||
            format('{
            "number": "%s",
            "quantity": %s,
            "amount": %s,
            "taxCode": "%s",
            "discounted": "true"
            }',
            plines[_line],
            pqtys[_line],
            pamounts[_line],
            ptaxtypes[_line]);
    IF _line !=_numlines THEN
      _payload := _payload || ',';
    END IF;
  END LOOP;

  IF pFreight != 0.0 THEN
    IF _numlines > 0 THEN
      _payload := _payload || ',';
    END IF;

    _payload = _payload ||
              format('{
              "number": "Freight",
              "amount": %s,
              "taxCode": "%s",
              "discounted": "true"
              }',
              pfreight,
              pfreighttaxtype);
  END IF;

  IF pMisc != 0.0 AND (NOT pMiscDiscount OR pMisc > 0) THEN
    IF _numlines > 0 OR pFreight != 0.0 THEN
      _payload := _payload || ',';
    END IF;

    _payload = _payload ||
              format('{
              "number": "Misc",
              "amount": %s,
              "taxCode": "%s"
              }',
              pmisc,
              pmisctaxtype);
  END IF;

  _payload = _payload || ']}}';

  RETURN _payload;

END
$$ LANGUAGE plpgsql;
