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
                                               pCust           TEXT,
                                               pTaxReg         TEXT,
                                               pCurrId         INTEGER,
                                               pDocDate        DATE,
                                               pFreight        NUMERIC,
                                               pMisc           NUMERIC,
                                               pFreightTaxtype TEXT,
                                               pMiscTaxtype    TEXT,
                                               pMiscDiscount   BOOLEAN,
                                               pFreightLine1   TEXT[],
                                               pFreightLine2   TEXT[],
                                               pFreightLine3   TEXT[],
                                               pFreightCity    TEXT[],
                                               pFreightState   TEXT[],
                                               pFreightZip     TEXT[],
                                               pFreightCountry TEXT[],
                                               pFreightSplit   NUMERIC[],
                                               pLines          TEXT[],
                                               pQtys           NUMERIC[],
                                               pTaxTypes       TEXT[],
                                               pAmounts        NUMERIC[],
                                               pLineLine1      TEXT[],
                                               pLineLine2      TEXT[],
                                               pLineLine3      TEXT[],
                                               pLineCity       TEXT[],
                                               pLineState      TEXT[],
                                               pLineZip        TEXT[],
                                               pLineCountry    TEXT[],
                                               pOverride       NUMERIC,
                                               pRecord         BOOLEAN) RETURNS JSONB AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _transactionType TEXT;
  _payload         TEXT;
  _numlines        INTEGER;
  _numfreight      INTEGER;
  _freightsplit    INTEGER;
  _freight         NUMERIC;
  _freightname     TEXT;
BEGIN

  _transactionType := (CASE pordertype
                       WHEN 'S' THEN 'SalesOrder'
                       WHEN 'INV' THEN 'SalesInvoice'
                       WHEN 'P' THEN 'PurchaseOrder'
                       WHEN 'V' THEN 'PurchaseInvoice'
                       ELSE 'SalesOrder' END);

  IF (NOT pRecord OR fetchMetricBool('NoAvaTaxCommit')) THEN
    _transactionType := replace(_transactionType, 'Invoice', 'Order');
  END IF;

  _numlines := COALESCE(array_length(pLines, 1), 0);
  _numfreight := COALESCE(array_length(pFreightSplit, 1), 0);

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
    pCust,
    pTaxReg,
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
            "discounted": "true"',
            plines[_line],
            pqtys[_line],
            pamounts[_line],
            ptaxtypes[_line]);

    IF pLineLine1[_line] != pFromLine1 OR pLineLine2[_line] != pFromLine2 OR
       pLineLine3[_line] != pFromLine3 OR pLineCity[_line] != pFromCity OR
       pLineState[_line] != pFromState OR pLineZip[_line] != pFromZip OR
       pLineCountry[_line] != pFromCountry THEN
      _payload := _payload ||
                format(',"addresses": {
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
                }}',
                pLineLine1[_line],
                pLineLine2[_line],
                pLineLine3[_line],
                pLineCity[_line],
                pLineState[_line],
                pLineCountry[_line],
                pLineZip[_line],
                pToLine1,
                pToLine2,
                pToLine3,
                pToCity,
                pToState,
                pToCountry,
                pToZip);
    END IF;

    _payload := _payload || '}';
    IF _line !=_numlines THEN
      _payload := _payload || ',';
    END IF;
  END LOOP;

  IF pFreight != 0.0 THEN
    IF _numlines > 0 THEN
      _payload := _payload || ',';
    END IF;

    FOR _freightsplit IN 1.._numfreight
    LOOP
      IF _numfreight = 1 THEN
        _freight = pFreight;
        _freightname = 'Freight';
      ELSE
        _freight = pFreightSplit[_freightsplit];
        _freightname = 'Freight' || _freightsplit;
      END IF;

      _payload = _payload ||
                format('{
                "number": "%s",
                "amount": %s,
                "taxCode": "%s",
                "discounted": "true"',
                _freightname,
                _freight,
                pfreighttaxtype);

      IF pFreightLine1[_freightsplit] != pFromLine1 OR pFreightLine2[_freightsplit] != pFromLine2 OR
         pFreightLine3[_freightsplit] != pFromLine3 OR pFreightCity[_freightsplit] != pFromCity OR
         pFreightState[_freightsplit] != pFromState OR pFreightZip[_freightsplit] != pFromZip OR
         pFreightCountry[_freightsplit] != pFromCountry THEN
        _payload := _payload ||
                  format(',"addresses": {
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
                  }}',
                  pFreightLine1[_freightsplit],
                  pFreightLine2[_freightsplit],
                  pFreightLine3[_freightsplit],
                  pFreightCity[_freightsplit],
                  pFreightState[_freightsplit],
                  pFreightCountry[_freightsplit],
                  pFreightZip[_freightsplit],
                  pToLine1,
                  pToLine2,
                  pToLine3,
                  pToCity,
                  pToState,
                  pToCountry,
                  pToZip);
      END IF;

      _payload := _payload || '}';
      IF _freightsplit !=_numfreight THEN
        _payload := _payload || ',';
      END IF;
    END LOOP;
  END IF;

  IF pMisc != 0.0 AND (NOT pMiscDiscount OR pMisc > 0) AND pMiscTaxtype IS NOT NULL THEN
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

  _payload := _payload || ']';

  IF pOverride IS NOT NULL THEN
    _payload := _payload ||
                format(', "taxOverride": {
                "type": "taxAmount",
                "taxAmount": %s,
                "reason": "Tax Adjustment"
                }',
                pOverride);
  END IF;

  _payload = _payload || '}}';

  RETURN _payload;

END
$$ LANGUAGE plpgsql;
