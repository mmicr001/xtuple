DROP FUNCTION IF EXISTS updatememotax(text, text, integer, integer, date, integer, numeric);
DROP FUNCTION IF EXISTS updatememotax(text, text, integer, integer, date, integer, numeric, numeric);

CREATE OR REPLACE FUNCTION updatememotax(
    pDocSource text,
    pDocType text,
    pMemoId integer,
    pTaxZone integer,
    pDate date,
    pCurr integer,
    pAmount numeric,
    pCurrRate NUMERIC DEFAULT NULL,
    pAutoOverride BOOLEAN DEFAULT FALSE
    )
  RETURNS numeric AS $func$
-- Copyright (c) 1999-2017 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
   _total 	numeric := 0;
   _sense       integer := 1;
   _custid      INTEGER;
   _taxheadid   INTEGER;
   _taxlineid   INTEGER;
   _taxd	RECORD;
   _taxt	RECORD;
   _taxamount	numeric;
   _tax		numeric;
   _taxamnt	numeric;
   _subtotal	numeric;
BEGIN
-- A/P memos
   IF (pDocSource = 'AP') THEN
     SELECT apopen_vend_id INTO _custid
       FROM apopen
      WHERE apopen_id = pMemoid;

     IF ( pDocType = 'D') THEN
       _sense = -1;
     END IF;
-- A/R memos
   ELSIF (pDocSource = 'AR') THEN
     SELECT aropen_cust_id INTO _custid
       FROM aropen 
      WHERE aropen_id = pMemoid;

     IF (pDocType = 'C') THEN
       _sense = -1;
     END IF;
   ELSE
     RAISE EXCEPTION 'Invalid memo type %', pDocSource;
   END IF;

   DELETE FROM taxhead
    WHERE taxhead_doc_type = pDocSource
      AND taxhead_doc_id = pMemoid;

   INSERT INTO taxhead (taxhead_status, taxhead_doc_type, taxhead_doc_id, taxhead_cust_id,
                        taxhead_date, taxhead_curr_id, taxhead_curr_rate, taxhead_taxzone_id,
                        taxhead_distdate)
   SELECT 'P', pDocSource, pMemoid, _custid,
          pDate, pCurr, pCurrRate, pTaxZone,
          pDate
   RETURNING taxhead_id INTO _taxheadid;

   INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_line_id, taxline_qty,
                        taxline_amount, taxline_extended)
   SELECT _taxheadid, 'L', pMemoid, 1.0,
          pAmount, pAmount
   RETURNING taxline_id INTO _taxlineid;

   -- Get Tax Adjustment Type(s) from configuration (auto-tax only)
   <<taxtypes>>
   FOR _taxt IN
     SELECT DISTINCT COALESCE(taxass_taxtype_id, getadjustmenttaxtypeid()) AS taxass_taxtype_id
     FROM tax
     JOIN taxass ON (tax_id=taxass_tax_id)
     WHERE ((CASE WHEN pAutoOverride THEN TRUE ELSE taxass_memo_apply END)
       AND (taxass_taxtype_id = getadjustmenttaxtypeid()
              OR taxass_taxtype_id IS NULL)
      AND  (taxass_taxzone_id = ptaxzone))
   LOOP  

     -- Determine the Tax details for the Voucher Tax Zone
     <<taxdetail>>
     FOR _taxd IN
        SELECT tax_id, (value->>'tax')::NUMERIC AS tax,
               (value->>'sequence')::INTEGER AS sequence,
               (value->>'taxclassid')::INTEGER AS taxclassid,
               (value->>'basistaxid')::INTEGER AS basistaxid,
               (value->>'amount')::NUMERIC AS amount,
               (value->>'percent')::NUMERIC AS percent
          FROM jsonb_array_elements(calculateTaxIncluded(ptaxzone, pcurr, pdate,
                                                        0.0, 0.0, -1, -1, FALSE,
                                                        ARRAY[''],
                                                        ARRAY[_taxt.taxass_taxtype_id],
                                                        ARRAY[pamount])->'lines'->0->'tax')
          JOIN tax ON (value->>'taxid')::INTEGER = tax_id
	ORDER BY sequence DESC

     LOOP
     -- Calculate Tax Amount
       _taxamount = _taxd.tax;

       -- Insert Tax Line
       INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                              taxdetail_taxclass_id, taxdetail_sequence, taxdetail_basis_tax_id,
                              taxdetail_amount, taxdetail_percent, taxdetail_tax)
       SELECT _taxlineid, pAmount, _taxd.tax_id,
              _taxd.taxclassid, _taxd.sequence, _taxd.basistaxid,
              _taxd.amount, _taxd.percent, _taxd.tax;

       -- Check for and post reverse VAT charges
       IF (EXISTS(SELECT 1 FROM taxass
                  WHERE ((taxass_reverse_tax)
                  AND (COALESCE(taxass_taxzone_id, -1) = ptaxzone)
                  AND (COALESCE(taxass_taxtype_id, -1) IN (getAdjustmentTaxTypeId(), -1))))) THEN
       INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                              taxdetail_taxclass_id, taxdetail_sequence, taxdetail_basis_tax_id,
                              taxdetail_amount, taxdetail_percent, taxdetail_tax)
       SELECT _taxlineid, pAmount, _taxd.tax_id,
              _taxd.taxclassid, _taxd.sequence, _taxd.basistaxid,
              _taxd.amount, _taxd.percent, _taxd.tax * -1;
       END IF;

       _total = _total + _taxamount;

     END LOOP taxdetail;
   END LOOP taxtypes;

    -- All done
    RETURN ABS(_total);

END;
$func$ LANGUAGE plpgsql;
