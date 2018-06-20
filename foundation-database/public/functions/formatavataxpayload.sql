CREATE OR REPLACE FUNCTION formatAvaTaxPayload(pordertype text,
    pordernumber text,
    ptoline1 text,
    ptoline2 text,
    ptoline3 text,
    ptocity text,
    ptostate text,
    ptozip text,
    ptocountry text,
    pcustid integer,
    pcurrid integer,
    pdocdate date,
    pfreight numeric,
    pmisc numeric,
    plines text[],
    pqtys numeric[],
    ptaxtypes text[],
    pamounts numeric[])
  RETURNS json AS
$$
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
                       WHEN 'I' THEN 'SalesInvoice'
                       WHEN 'P' THEN 'PurchaseOrder'
                       WHEN 'V' THEN 'PurchaseInvoice'
                       ELSE 'SalesOrder' END);

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
        "singleLocation": {
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
    "lines": [',
    _transactionType,
    pordernumber,
    fetchmetrictext('AvalaraCompany'),
    pdocdate,
    _rec.cust_number,
    COALESCE(_rec.taxreg, ' '),
    ptoline1,
    ptoline2,
    ptoline3,
    ptocity,
    ptostate,
    ptocountry,
    ptozip,
    (SELECT curr_abbr FROM curr_symbol WHERE curr_id=pcurrid),
    'xTuple-' || _transactionType);

  FOR _line IN 1.._numlines
  LOOP
   _payload = _payload ||
            format('{
            "number": "%s",
            "quantity": %s,
            "amount": %s,
            "taxCode": "%s"
            }',
            plines[_line],
            pqtys[_line],
            pamounts[_line],
            ptaxtypes[_line]);
    IF (_line < _numlines) THEN
      _payload = _payload || ',';
    END IF;
  END LOOP;

  _payload = _payload || ']}}';

  RETURN _payload;

END
$$ LANGUAGE plpgsql;
