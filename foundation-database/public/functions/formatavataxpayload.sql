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
                                               pSingleLocation  BOOLEAN,
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
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _transactionType TEXT;
  _return          BOOLEAN;
  _payload         TEXT;
  _numlines        INTEGER;
  _numfreight      INTEGER;
  _shipfromtoaddr  TEXT;
  _singleaddr      TEXT;
  _fromline1       TEXT;
  _fromline2       TEXT;
  _fromline3       TEXT;
  _fromcity        TEXT;
  _fromstate       TEXT;
  _fromzip         TEXT;
  _fromcountry     TEXT;
  _toline1         TEXT;
  _toline2         TEXT;
  _toline3         TEXT;
  _tocity          TEXT;
  _tostate         TEXT;
  _tozip           TEXT;
  _tocountry       TEXT;
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

  _shipfromtoaddr := '"addresses": {
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
                      }';

  _singleaddr := '"addresses": {
                    "singleLocation": {
                      "line1": %s,
                      "line2": %s,
                      "line3": %s,
                      "city": %s,
                      "region": %s,
                      "country": %s,
                      "postalCode": %s
                    }
                  }';

  _fromline1 := pFromLine1;
  _fromline2 := pFromLine2;
  _fromline3 := pFromLine3;
  _fromcity := pFromCity;
  _fromstate := pFromState;
  _fromzip := pFromZip;
  _fromcountry := pFromCountry;
  _toline1 := pToLine1;
  _toline2 := pToLine2;
  _toline3 := pToLine3;
  _tocity := pToCity;
  _tostate := pToState;
  _tozip := pToZip;
  _tocountry := pToCountry;

  _payload = format('{ "createTransactionModel": {
    "type": %s,
    "code": %s,
    "companyCode": %s,
    "date": %s,
    "customerCode": %s,
    "entityUseCode": %s,
    "businessIdentificationNo": %s,
    "commit": false,
    "currencyCode": %s,
    "description": %s,
    "discount": %s,',
    to_jsonb(_transactionType),
    to_jsonb(pordertype || '-' || pordernumber),
    to_jsonb(fetchmetrictext('AvalaraCompany')),
    to_jsonb(pdocdate),
    to_jsonb(pCust),
    to_jsonb(COALESCE(pUsage, '')),
    to_jsonb(COALESCE(pTaxReg, '')),
    to_jsonb((SELECT curr_abbr FROM curr_symbol WHERE curr_id=pcurrid)),
    to_jsonb('xTuple-' || _transactionType),
    to_jsonb(CASE WHEN pMiscDiscount AND pMisc < 0
                  THEN pMisc * CASE WHEN _return
                                    THEN 1
                                    ELSE -1
                                END
                  ELSE 0
              END));

  IF pFromLine1 != pToLine1 OR pFromLine2 != pToLine2 OR pFromLine3 != pToLine3 OR
     pFromCity != pToCity OR pFromState != pToState OR pFromZip != pToZip OR
     pFromCountry != pToCountry THEN
    _payload := _payload ||
             format(_shipfromtoaddr,
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
             to_jsonb(COALESCE(ptozip, '')));
  ELSE
    _payload := _payload ||
             format(_singleaddr,
             to_jsonb(COALESCE(pfromline1, '')),
             to_jsonb(COALESCE(pfromline2, '')),
             to_jsonb(COALESCE(pfromline3, '')),
             to_jsonb(COALESCE(pfromcity, '')),
             to_jsonb(COALESCE(pfromstate, '')),
             to_jsonb(COALESCE(pfromcountry, '')),
             to_jsonb(COALESCE(pfromzip, '')));
  END IF;

  _payload := _payload || ',"lines": [';

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
                to_jsonb(COALESCE(pUsages[_line], '')));
    END IF;

    IF pOrderType IN ('P', 'VCH') THEN
      _toline1 := pLineLine1[_line];
      _toline2 := pLineLine2[_line];
      _toline3 := pLineLine3[_line];
      _tocity := pLineCity[_line];
      _tostate := pLineState[_line];
      _tozip := pLineZip[_line];
      _tocountry := pLineCountry[_line];
    END IF;

    IF pSingleLocation OR pOrderType NOT IN ('P', 'VCH') THEN
      _fromline1 := pLineLine1[_line];
      _fromline2 := pLineLine2[_line];
      _fromline3 := pLineLine3[_line];
      _fromcity := pLineCity[_line];
      _fromstate := pLineState[_line];
      _fromzip := pLineZip[_line];
      _fromcountry := pLineCountry[_line];
    END IF;

    IF pFromLine1 != _fromline1 OR pFromLine2 != _fromline2 OR pFromLine3 != _fromline3 OR
       pFromCity != _fromcity OR pFromState != _fromstate OR pFromZip != _fromzip OR
       pFromCountry != _fromcountry OR
       pToLine1 != _toline1 OR pToLine2 != _toline2 OR pToLine3 != _toline3 OR
       pToCity != _tocity OR pToState != _tostate OR pToZip != _tozip OR 
       pToCountry != _tocountry THEN
      IF _fromline1 != _toline1 OR _fromline2 != _toline2 OR _fromline3 != _toline3 OR
         _fromcity != _tocity OR _fromstate != _tostate OR _fromzip != _tozip OR
         _fromcountry != _tocountry THEN
        _payload := _payload || ',' ||
                format(_shipfromtoaddr,
                to_jsonb(COALESCE(_fromline1, '')),
                to_jsonb(COALESCE(_fromline2, '')),
                to_jsonb(COALESCE(_fromline3, '')),
                to_jsonb(COALESCE(_fromcity, '')),
                to_jsonb(COALESCE(_fromstate, '')),
                to_jsonb(COALESCE(_fromcountry, '')),
                to_jsonb(COALESCE(_fromzip, '')),
                to_jsonb(COALESCE(_toline1, '')),
                to_jsonb(COALESCE(_toline2, '')),
                to_jsonb(COALESCE(_toline3, '')),
                to_jsonb(COALESCE(_tocity, '')),
                to_jsonb(COALESCE(_tostate, '')),
                to_jsonb(COALESCE(_tocountry, '')),
                to_jsonb(COALESCE(_tozip, '')));
      ELSE
        _payload := _payload || ',' ||
                format(_singleaddr,
                to_jsonb(COALESCE(_fromline1, '')),
                to_jsonb(COALESCE(_fromline2, '')),
                to_jsonb(COALESCE(_fromline3, '')),
                to_jsonb(COALESCE(_fromcity, '')),
                to_jsonb(COALESCE(_fromstate, '')),
                to_jsonb(COALESCE(_fromcountry, '')),
                to_jsonb(COALESCE(_fromzip, '')));
      END IF;
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

      IF pOrderType IN ('P', 'VCH') THEN
        _toline1 := pFreightLine1[_freightsplit];
        _toline2 := pFreightLine2[_freightsplit];
        _toline3 := pFreightLine3[_freightsplit];
        _tocity := pFreightCity[_freightsplit];
        _tostate := pFreightState[_freightsplit];
        _tozip := pFreightZip[_freightsplit];
        _tocountry := pFreightCountry[_freightsplit];
      END IF;

      IF pSingleLocation OR pOrderType NOT IN ('P', 'VCH') THEN
        _fromline1 := pFreightLine1[_freightsplit];
        _fromline2 := pFreightLine2[_freightsplit];
        _fromline3 := pFreightLine3[_freightsplit];
        _fromcity := pFreightCity[_freightsplit];
        _fromstate := pFreightState[_freightsplit];
        _fromzip := pFreightZip[_freightsplit];
        _fromcountry := pFreightCountry[_freightsplit];
      END IF;

      IF pFromLine1 != _fromline1 OR pFromLine2 != _fromline2 OR pFromLine3 != _fromline3 OR
         pFromCity != _fromcity OR pFromState != _fromstate OR pFromZip != _fromzip OR
         pFromCountry != _fromcountry OR
         pToLine1 != _toline1 OR pToLine2 != _toline2 OR pToLine3 != _toline3 OR
         pToCity != _tocity OR pToState != _tostate OR pToZip != _tozip OR
         pToCountry != _tocountry THEN
        IF _fromline1 != _toline1 OR _fromline2 != _toline2 OR _fromline3 != _toline3 OR
           _fromcity != _tocity OR _fromstate != _tostate OR _fromzip != _tozip OR
           _fromcountry != _tocountry THEN
          _payload := _payload || ',' ||
                  format(_shipfromtoaddr,
                  to_jsonb(COALESCE(_fromline1, '')),
                  to_jsonb(COALESCE(_fromline2, '')),
                  to_jsonb(COALESCE(_fromline3, '')),
                  to_jsonb(COALESCE(_fromcity, '')),
                  to_jsonb(COALESCE(_fromstate, '')),
                  to_jsonb(COALESCE(_fromcountry, '')),
                  to_jsonb(COALESCE(_fromzip, '')),
                  to_jsonb(COALESCE(_toline1, '')),
                  to_jsonb(COALESCE(_toline2, '')),
                  to_jsonb(COALESCE(_toline3, '')),
                  to_jsonb(COALESCE(_tocity, '')),
                  to_jsonb(COALESCE(_tostate, '')),
                  to_jsonb(COALESCE(_tocountry, '')),
                  to_jsonb(COALESCE(_tozip, '')));
        ELSE
          _payload := _payload || ',' ||
                  format(_singleaddr,
                  to_jsonb(COALESCE(_fromline1, '')),
                  to_jsonb(COALESCE(_fromline2, '')),
                  to_jsonb(COALESCE(_fromline3, '')),
                  to_jsonb(COALESCE(_fromcity, '')),
                  to_jsonb(COALESCE(_fromstate, '')),
                  to_jsonb(COALESCE(_fromcountry, '')),
                  to_jsonb(COALESCE(_fromzip, '')));
        END IF;
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
