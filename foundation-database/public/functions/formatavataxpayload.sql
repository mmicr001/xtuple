CREATE OR REPLACE FUNCTION formatAvaTaxPayload(pOrderType       TEXT,
                                               pOrderNumber     TEXT,
                                               pFromLine1       TEXT,
                                               pFromLine2       TEXT,
                                               pFromLine3       TEXT,
                                               pFromCity        TEXT,
                                               pFromState       TEXT,
                                               pFromZip         TEXT,
                                               pFromCountry     TEXT,
                                               pToLine1         TEXT,
                                               pToLine2         TEXT,
                                               pToLine3         TEXT,
                                               pToCity          TEXT,
                                               pToState         TEXT,
                                               pToZip           TEXT,
                                               pToCountry       TEXT,
                                               pCust            TEXT,
                                               pUsage           TEXT,
                                               pTaxReg          TEXT,
                                               pCurrId          INTEGER,
                                               pDocDate         DATE,
                                               pOrigDate        DATE,
                                               pOrigOrder       TEXT,
                                               pFreight         NUMERIC,
                                               pMisc            NUMERIC,
                                               pMiscDescrip     TEXT,
                                               pFreightTaxtype  TEXT,
                                               pMiscTaxtype     TEXT,
                                               pMiscDiscount    BOOLEAN,
                                               pFreightLine1    TEXT[],
                                               pFreightLine2    TEXT[],
                                               pFreightLine3    TEXT[],
                                               pFreightCity     TEXT[],
                                               pFreightState    TEXT[],
                                               pFreightZip      TEXT[],
                                               pFreightCountry  TEXT[],
                                               pFreightSplit    NUMERIC[],
                                               pLines           TEXT[],
                                               pLineCodes       TEXT[],
                                               pLineUpc         TEXT[],
                                               pLineDescrips    TEXT[],
                                               pQtys            NUMERIC[],
                                               pTaxTypes        TEXT[],
                                               pAmounts         NUMERIC[],
                                               pUsages          TEXT[],
                                               pLineLine1       TEXT[],
                                               pLineLine2       TEXT[],
                                               pLineLine3       TEXT[],
                                               pLineCity        TEXT[],
                                               pLineState       TEXT[],
                                               pLineZip         TEXT[],
                                               pLineCountry     TEXT[],
                                               pTaxPaid         NUMERIC,
                                               pRecord          BOOLEAN) RETURNS JSONB AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _transactionType TEXT;
  _return          BOOLEAN;
  _payload         TEXT;
  _numlines        INTEGER;
  _numfreight      INTEGER;
  _freightsplit    INTEGER;
  _freight         NUMERIC;
  _freightname     TEXT;
BEGIN

  _transactionType := getAvaTaxDoctype(pOrderType);

  _return := _transactionType ~ 'Return';

  IF (NOT pRecord OR fetchMetricBool('NoAvaTaxCommit')) THEN
    _transactionType := replace(_transactionType, 'Invoice', 'Order');
  END IF;

  _numlines := COALESCE(array_length(pLines, 1), 0);
  _numfreight := COALESCE(array_length(pFreightSplit, 1), 0);

  _payload = format('{ "createTransactionModel": {
    "type": %s,
    "code": %s,
    "companyCode": %s,
    "date": %s,
    "customerCode": %s,
    "entityUseCode": %s,
    "businessIdentificationNo": %s,
    "addresses": {
        "shipFrom": {
            "line1": %s,
            "line2": %s,
            "line3": %s,
            "city": %s,
            "region": %s,
            "country": %s,
            "postalCode": %s
        },
        "shipTo": {
            "line1": %s,
            "line2": %s,
            "line3": %s,
            "city": %s,
            "region": %s,
            "country": %s,
            "postalCode": %s
        }
    },
    "commit": false,
    "currencyCode": %s,
    "description": %s,
    "discount": %s,
    "lines": [',
    to_jsonb(_transactionType),
    to_jsonb(pordernumber),
    to_jsonb(fetchmetrictext('AvalaraCompany')),
    to_jsonb(pdocdate),
    to_jsonb(pCust),
    to_jsonb(COALESCE(pUsage, '')),
    to_jsonb(COALESCE(pTaxReg, '')),
    to_jsonb(COALESCE(pfromline1, '')),
    to_jsonb(COALESCE(pfromline2, '')),
    to_jsonb(COALESCE(pfromline3, '')),
    to_jsonb(COALESCE(pfromcity, '')),
    to_jsonb(COALESCE(pfromstate, '')),
    to_jsonb(COALESCE(pfromcountry, '')),
    to_jsonb(COALESCE(pfromzip, '')),
    to_jsonb(COALESCE(ptoline1, '')),
    to_jsonb(COALESCE(ptoline2, '')),
    to_jsonb(COALESCE(ptoline3, '')),
    to_jsonb(COALESCE(ptocity, '')),
    to_jsonb(COALESCE(ptostate, '')),
    to_jsonb(COALESCE(ptocountry, '')),
    to_jsonb(COALESCE(ptozip, '')),
    to_jsonb((SELECT curr_abbr FROM curr_symbol WHERE curr_id=pcurrid)),
    to_jsonb('xTuple-' || _transactionType),
    to_jsonb(CASE WHEN pMiscDiscount AND pMisc < 0
                  THEN pMisc * CASE WHEN _return
                                    THEN 1
                                    ELSE -1
                                END
                  ELSE 0
              END));

  FOR _line IN 1.._numlines
  LOOP
   _payload = _payload ||
            format('{
            "number": %s,
            "itemCode": %s,
            "description": %s,
            "quantity": %s,
            "amount": %s,
            "taxCode": %s,
            "discounted": "true"',
            to_jsonb(plines[_line]),
            to_jsonb(CASE WHEN fetchMetricBool('AvalaraUPC')
                          THEN COALESCE('UPC:' || plineupc[_line], plinecodes[_line])
                          ELSE plinecodes[_line]
                      END),
            to_jsonb(COALESCE(plinedescrips[_line], '')),
            to_jsonb(pqtys[_line]),
            to_jsonb(pamounts[_line] * CASE WHEN _return THEN -1 ELSE 1 END),
            to_jsonb(COALESCE(ptaxtypes[_line], '')));

    IF pUsages[_line] IS DISTINCT FROM pUsage THEN
      _payload := _payload ||
                format(',"entityUseCode": %s',
                to_jsonb(COALESCE(pUsage, '')));
    END IF;

    IF pLineLine1[_line] != pFromLine1 OR pLineLine2[_line] != pFromLine2 OR
       pLineLine3[_line] != pFromLine3 OR pLineCity[_line] != pFromCity OR
       pLineState[_line] != pFromState OR pLineZip[_line] != pFromZip OR
       pLineCountry[_line] != pFromCountry THEN
      _payload := _payload ||
                format(',"addresses": {
                "shipFrom": {
                "line1": %s,
                "line2": %s,
                "line3": %s,
                "city": %s,
                "region": %s,
                "country": %s,
                "postalCode": %s
                },
                "shipTo": {
                "line1": %s,
                "line2": %s,
                "line3": %s,
                "city": %s,
                "region": %s,
                "country": %s,
                "postalCode": %s
                }}',
                to_jsonb(COALESCE(pLineLine1[_line], '')),
                to_jsonb(COALESCE(pLineLine2[_line], '')),
                to_jsonb(COALESCE(pLineLine3[_line], '')),
                to_jsonb(COALESCE(pLineCity[_line], '')),
                to_jsonb(COALESCE(pLineState[_line], '')),
                to_jsonb(COALESCE(pLineCountry[_line], '')),
                to_jsonb(COALESCE(pLineZip[_line], '')),
                to_jsonb(COALESCE(pToLine1, '')),
                to_jsonb(COALESCE(pToLine2, '')),
                to_jsonb(COALESCE(pToLine3, '')),
                to_jsonb(COALESCE(pToCity, '')),
                to_jsonb(COALESCE(pToState, '')),
                to_jsonb(COALESCE(pToCountry, '')),
                to_jsonb(COALESCE(pToZip, '')));
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
                "number": %s,
                "descrip": %s,
                "amount": %s,
                "taxCode": %s,
                "discounted": "true"',
                to_jsonb(_freightname),
                to_jsonb(_freightname),
                to_jsonb(_freight * CASE WHEN _return THEN -1 ELSE 1 END),
                to_jsonb(COALESCE(pfreighttaxtype, '')));

      IF pFreightLine1[_freightsplit] != pFromLine1 OR pFreightLine2[_freightsplit] != pFromLine2 OR
         pFreightLine3[_freightsplit] != pFromLine3 OR pFreightCity[_freightsplit] != pFromCity OR
         pFreightState[_freightsplit] != pFromState OR pFreightZip[_freightsplit] != pFromZip OR
         pFreightCountry[_freightsplit] != pFromCountry THEN
        _payload := _payload ||
                  format(',"addresses": {
                  "shipFrom": {
                  "line1": %s,
                  "line2": %s,
                  "line3": %s,
                  "city": %s,
                  "region": %s,
                  "country": %s,
                  "postalCode": %s
                  },
                  "shipTo": {
                  "line1": %s,
                  "line2": %s,
                  "line3": %s,
                  "city": %s,
                  "region": %s,
                  "country": %s,
                  "postalCode": %s
                  }}',
                  to_jsonb(COALESCE(pFreightLine1[_freightsplit], '')),
                  to_jsonb(COALESCE(pFreightLine2[_freightsplit], '')),
                  to_jsonb(COALESCE(pFreightLine3[_freightsplit], '')),
                  to_jsonb(COALESCE(pFreightCity[_freightsplit], '')),
                  to_jsonb(COALESCE(pFreightState[_freightsplit], '')),
                  to_jsonb(COALESCE(pFreightCountry[_freightsplit], '')),
                  to_jsonb(COALESCE(pFreightZip[_freightsplit], '')),
                  to_jsonb(COALESCE(pToLine1, '')),
                  to_jsonb(COALESCE(pToLine2, '')),
                  to_jsonb(COALESCE(pToLine3, '')),
                  to_jsonb(COALESCE(pToCity, '')),
                  to_jsonb(COALESCE(pToState, '')),
                  to_jsonb(COALESCE(pToCountry, '')),
                  to_jsonb(COALESCE(pToZip), ''));
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
              "descrip": %s,
              "amount": %s,
              "taxCode": %s
              }',
              to_jsonb(COALESCE(pmiscdescrip, '')),
              to_jsonb(pmisc * CASE WHEN _return THEN -1 ELSE 1 END),
              to_jsonb(COALESCE(pmisctaxtype, '')));
  END IF;

  _payload := _payload || ']';

  IF pOrigDate IS NOT NULL THEN
    _payload := _payload ||
                format(', "taxOverride": {
                "type": "taxDate",
                "taxDate": %s,
                "reason": %s
                }',
                to_jsonb(pOrigDate), to_jsonb('Refund for ' || pOrigOrder));
  END IF;

  IF pTaxPaid IS NOT NULL THEN
    _payload := _payload ||
                format(', "taxOverride": {
                "type": "taxAmount",
                "taxAmount": %s,
                "reason": "Tax paid to vendor"
                }',
                to_jsonb(pTaxPaid));
  END IF;

  _payload = _payload || '}}';

  RETURN _payload;

END
$$ LANGUAGE plpgsql;
