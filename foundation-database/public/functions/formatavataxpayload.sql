CREATE OR REPLACE FUNCTION formatAvaTaxPayload(pOrderType   TEXT,
                                               pOrderNumber TEXT,
                                               pToLine1   TEXT,
                                               pToLine2   TEXT,
                                               pToLine3   TEXT,
                                               pToCity    TEXT,
                                               pToState   TEXT,
                                               pToZip     TEXT,
                                               pToCountry TEXT,
                                               pCustId      INTEGER,
                                               pCurrId      INTEGER,
                                               pDocDate     DATE,
                                               pFreight     NUMERIC,
                                               pMisc        NUMERIC,
                                               pLines       TEXT[],
                                               pQtys        NUMERIC[],
                                               pTaxTypes    INTEGER[],
                                               pAmounts     NUMERIC[]) RETURNS JSON AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _rec     RECORD;
  _payload TEXT;
  _numlines INTEGER;
BEGIN

  _numlines := COALESCE(array_length(pLines, 1), 0);

  SELECT cust_number, (SELECT taxreg_number FROM taxreg WHERE taxreg_reltype = 'C'
                                                          AND taxreg_rel_id = pcustid
                                                          AND CURRENT_DATE BETWEEN taxreg_effective AND taxreg_expires 
                                                          LIMIT 1) AS taxreg
  INTO _rec
  FROM  custinfo
  WHERE cust_id = pcustid;
 
  _payload = format('{
    "type": %s,
    "code": %s,  
    "companyCode": %s,
    "date": %s,
    "customerCode": %s,
    "businessIdentificationNo", %s,
    "addresses": {
        "singleLocation": {
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
    "lines": [',
    pordertype,
    pordernumber,
    fetchmetrictext('AvalaraCompany'),
    pdocdate,
    _rec.cust_number,
    COALESCE(_rec.taxreg, ''),
    ptoline1,
    ptoline2,
    ptoline3,
    ptocity,
    ptostate,
    ptocountry,
    ptozip,
    (SELECT curr_abbr FROM curr_symbol WHERE curr_id=pcurrid),
    'xTuple ' || pordertype);

  FOR _line IN 1.._numlines
  LOOP
   _payload = _payload || 
            format('{
            "number": %s,
            "quantity": %d,
            "amount": %d,
            "taxCode": %s
            }',
            plines[_line],
            pqtys[_line],
            pamounts[_line],
            ptaxtypes[_line]);
    IF (_line < _numlines) THEN
      _payload = _payload || ',';
    END IF;
  END LOOP;            
            
  _payload = _payload || ']}';
  
  RETURN _payload;

END
$$ LANGUAGE plpgsql;
