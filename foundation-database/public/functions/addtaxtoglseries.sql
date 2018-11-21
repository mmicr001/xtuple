-- add tax information to a GL Series
-- return the base currency value of the GL Series records inserted
--	  NULL if there has been an error
DROP FUNCTION IF EXISTS addTaxToGLSeries(INTEGER, TEXT, TEXT, TEXT, INTEGER, DATE, DATE, TEXT, INTEGER, TEXT);
CREATE OR REPLACE FUNCTION addTaxToGLSeries(pSequence   INTEGER,
                                            pSource     TEXT,
                                            pDocType    TEXT,
                                            pDocNumber  TEXT,
                                            pCurrId     INTEGER,
                                            pExchDate   DATE,
                                            pDistDate   DATE,
                                            pParentType TEXT,
                                            pParentId   INTEGER,
                                            pNotes      TEXT) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _baseTax	NUMERIC := 0;
  _returnVal	NUMERIC := 0;
  _t		RECORD;

BEGIN

  FOR _t IN SELECT taxhead_id, taxdetail_tax, tax_sales_accnt_id
            FROM taxhead
            JOIN taxline ON taxhead_id = taxline_taxhead_id
            JOIN taxdetail ON taxline_id = taxdetail_taxline_id
            JOIN tax ON taxdetail_tax_id = tax_id
            WHERE taxhead_doc_type = pParentType
              AND taxhead_doc_id = pParentId
            LOOP

    _baseTax := currToBase(pCurrId, _t.taxdetail_tax, pExchDate);
    _returnVal := _returnVal + _baseTax;
    PERFORM insertIntoGLSeries( pSequence, pSource, pDocType, pDocNumber,
                                _t.tax_sales_accnt_id, _baseTax,
                                pDistDate, pNotes );

    UPDATE taxhead SET
      taxhead_date=pExchDate,
      taxhead_distdate=pDistDate,
      taxhead_curr_id=pCurrId,
      taxhead_curr_rate=curr_rate
    FROM curr_rate
    WHERE ((taxhead_id=_t.taxhead_id)
      AND  (pCurrId=curr_id)
      AND  (pExchDate BETWEEN curr_effective AND curr_expires));

  END LOOP;

  RETURN _returnVal;
END;
$$ LANGUAGE plpgsql;
