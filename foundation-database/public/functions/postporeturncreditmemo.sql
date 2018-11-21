
CREATE OR REPLACE FUNCTION postPoReturnCreditMemo(INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pPorejectId ALIAS FOR $1;

BEGIN
  RETURN postPoReturnCreditMemo(pPorejectId, NULL);
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION postPoReturnCreditMemo(INTEGER, NUMERIC) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2018 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pPorejectId ALIAS FOR $1;
  pAmount ALIAS FOR $2;
  _p RECORD;
  _a RECORD;
  _itemsiteId INTEGER;
  _docNumber TEXT;
  _sequence INTEGER;
  _journalNumber INTEGER;
  _apopenid INTEGER;
  _exchGainItem NUMERIC;
  _itemAmount_base NUMERIC;
  _itemAmount NUMERIC;
  _glseriesTotal NUMERIC;
  _tmpTotal NUMERIC;
  _test INTEGER;
  _exchDate DATE;
  _tax RECORD;
  _taxAmount NUMERIC := 0;
  _taxAmount_base NUMERIC;
  _apaccntid INTEGER;
  _taxheadid INTEGER;
  _taxlineid INTEGER;

BEGIN
--Set things up
  SELECT NEXTVAL('apopen_apopen_id_seq') INTO _apopenid;
  SELECT fetchGLSequence() INTO _sequence;
  SELECT fetchJournalNumber('AP-MISC') INTO _journalNumber;
  SELECT fetchapmemonumber() INTO _docNumber;
  _glseriesTotal := 0;

--Get poreject data
  SELECT pohead_vend_id, pohead_number, pohead_curr_id, pohead_orderdate, pohead_taxzone_id,
         poitem_id, poitem_itemsite_id,poitem_expcat_id, poitem_taxtype_id,
        itemsite_costcat_id, poreject_qty, poreject_date,
        ('Return of Item ' || COALESCE(item_number,poitem_vend_item_number)
           || ', qty. ' || formatqty(poreject_qty)) AS notes,
        poreject_value AS value,
        currToBase(pohead_curr_id,(poitem_unitprice * poreject_qty),CURRENT_DATE) AS itemAmount_base,
        (poitem_unitprice * poreject_qty) AS itemAmount
        INTO _p
  FROM pohead, poreject, poitem
        LEFT OUTER JOIN itemsite ON (poitem_itemsite_id=itemsite_id)
        LEFT OUTER JOIN item ON (itemsite_item_id=item_id)
  WHERE ((poreject_poitem_id=poitem_id)
  AND (pohead_id=poitem_pohead_id)
  AND (poreject_id=pPorejectId));

  _itemAmount := _p.itemAmount;
  _itemAmount_base := _p.itemAmount_base;
  IF (pAmount IS NOT NULL) THEN
    _itemAmount := pAmount;
    _itemAmount_base := currToBase(_p.pohead_curr_id, pAmount, CURRENT_DATE);
  END IF;
  

--  Grab the G/L Accounts
  IF (COALESCE(_p.poitem_itemsite_id, -1) = -1) THEN
    SELECT pp.accnt_id AS pp_accnt_id,
           lb.accnt_id AS lb_accnt_id INTO _a
    FROM expcat, accnt AS pp, accnt AS lb
    WHERE ( (expcat_purchprice_accnt_id=pp.accnt_id)
     AND (expcat_liability_accnt_id=lb.accnt_id)
     AND (expcat_id=_p.poitem_expcat_id) );
    IF (NOT FOUND) THEN
      RAISE EXCEPTION 'Cannot Post Credit Memo due to unassigned G/L Accounts.';
    END IF;
  ELSE
    SELECT pp.accnt_id AS pp_accnt_id,
           lb.accnt_id AS lb_accnt_id INTO _a
    FROM costcat, accnt AS pp, accnt AS lb
    WHERE ( (costcat_purchprice_accnt_id=pp.accnt_id)
     AND (costcat_liability_accnt_id=lb.accnt_id)
     AND (costcat_id=_p.itemsite_costcat_id) );
    IF (NOT FOUND) THEN
      RAISE EXCEPTION 'Cannot Post Credit Memo due to unassigned G/L Accounts.';
    END IF;
  END IF;

--  AP Open Item record
    INSERT INTO apopen
    ( apopen_id, apopen_username, apopen_journalnumber,
      apopen_vend_id, apopen_docnumber, apopen_doctype, apopen_ponumber,
      apopen_docdate, apopen_duedate, apopen_distdate, apopen_terms_id,
      apopen_amount, apopen_paid, apopen_open, apopen_notes, apopen_accnt_id, apopen_curr_id,
      apopen_closedate )
    VALUES
    ( _apopenid, getEffectiveXtUser(), _journalNumber,
      _p.pohead_vend_id, _docNumber, 'C', _p.pohead_number,
      CURRENT_DATE, CURRENT_DATE, CURRENT_DATE, -1,
      round(_itemAmount, 2), 0, (round(_itemAmount, 2) <> 0), _p.notes, -1, _p.pohead_curr_id,
      CASE WHEN (round(_itemAmount, 2) = 0) THEN _p.poreject_date END );

-- Taxes
    INSERT INTO taxhead (taxhead_status, taxhead_doc_type, taxhead_doc_id, taxhead_cust_id,
                         taxhead_date,
                         taxhead_curr_id, taxhead_curr_rate,
                         taxhead_taxzone_id, taxhead_journalnumber)
    SELECT 'P', 'AP', _apopenid, _p.pohead_vend_id,
           CURRENT_DATE, _p.pohead_curr_id, currRate(_p.pohead_curr_id, CURRENT_DATE),
           _p.pohead_taxzone_id, _journalNumber
    RETURNING taxhead_id INTO _taxheadid;

    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_line_id,
                         taxline_taxtype_id, taxline_qty, taxline_amount, taxline_extended)
    SELECT _taxheadid, 'L', _apopenid,
           _p.poitem_taxtype_id, 1.0, _itemAmount, _itemAmount
    RETURNING taxline_id INTO _taxlineid;

    FOR _tax IN
      SELECT (value->>'taxid')::INTEGER AS taxdetail_tax_id,
             (value->>'taxclassid')::INTEGER AS taxclassid,
             (value->>'sequence')::INTEGER AS sequence,
             (value->>'basistaxid')::INTEGER AS basistaxid,
             (value->>'amount')::NUMERIC AS amount,
             (value->>'percent')::NUMERIC AS percent,
             sum((value->>'tax')::NUMERIC) AS taxdetail_tax,
        currToBase(_p.pohead_curr_id, round(sum((value->>'tax')::NUMERIC),2), current_date) AS taxbasevalue
      FROM jsonb_array_elements(calculatetax(_p.pohead_taxzone_id,_p.pohead_curr_id,
                                current_date, 0.0, 0.0, getFreightTaxtypeId(),
                                getMiscTaxtypeId(), FALSE, ARRAY[''],
                                ARRAY[_p.poitem_taxtype_id],
                                ARRAY[_itemAmount])->'lines'->0->'tax')
      GROUP BY (value->>'taxid')::INTEGER

    LOOP
      INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                             taxdetail_taxclass_id, taxdetail_sequence, taxdetail_basis_tax_id,
                             taxdetail_amount, taxdetail_percent, taxdetail_tax)
      SELECT _taxlineid, _itemAmount, _tax.taxdetail_tax_id,
             _tax.taxclassid, _tax.sequence, _tax.basistaxid,
             _tax.amount, _tax.percent, _tax.taxdetail_tax;

      _taxAmount := _taxAmount + _tax.taxdetail_tax;
 
    END LOOP;

    _taxAmount_base := addTaxToGLSeries(_sequence,
		       'A/P', 'CM', _docNumber,
		       _p.pohead_curr_id, current_date, current_date,
                      'AP', _apopenid,
                      _p.notes);

    UPDATE apopen SET apopen_amount = round(_itemAmount + _taxAmount,2)
    WHERE (apopen_id = _apopenid);

--  Distribute from the clearing account
    PERFORM insertIntoGLSeries( _sequence, 'A/P', 'CM', _docNumber,
                _a.lb_accnt_id,
                round(_p.value, 2),
                current_date, _p.notes );
    _glseriesTotal := _glseriesTotal + round(_p.value, 2);

--  Distribute the remaining variance to the Purchase Price Variance account
    IF (round(_itemAmount_base, 2) <> round(_p.value, 2)) THEN
      _tmpTotal := round(_itemAmount_base, 2) - round(_p.value, 2);
      PERFORM insertIntoGLSeries( _sequence, 'A/P', 'CM', _docNumber,
                                  _a.pp_accnt_id,
                                  _tmpTotal,
                                  current_date, _p.notes );
        _glseriesTotal := _glseriesTotal + _tmpTotal;
    END IF;

--  Post the reject item for this P/O Item as Invoiced
    UPDATE poreject
    SET poreject_invoiced=TRUE
    WHERE poreject_id=pPorejectId;

--  Update the qty vouchered field
    UPDATE poitem
       SET poitem_qty_vouchered = (poitem_qty_vouchered - _p.poreject_qty)
     WHERE (poitem_id=_p.poitem_id);

--  Post to A/P
  SELECT findAPAccount(_p.pohead_vend_id) INTO _apaccntid;
  IF (NOT FOUND) THEN
    RAISE EXCEPTION 'Cannot Post Credit Memo due to an unassigned A/P Account.';
  END IF;

  SELECT insertIntoGLSeries( _sequence, 'A/P', 'CM', _docNumber,
                             _apaccntid, round(_itemAmount_base + _taxAmount_base, 2) *-1,
                             current_date, _p.notes ) INTO _test;
  IF (NOT FOUND) THEN
    RAISE EXCEPTION 'Cannot Post Credit Memo.';
  END IF;

-- Clean up loose ends

  _glseriesTotal := _glseriesTotal + round(_itemAmount_base, 2)*-1;

  IF (round(_glseriesTotal, 2) != 0) THEN
        PERFORM insertIntoGLSeries(_sequence, 'A/P', 'CM',
            'Currency Exchange Rounding - ' || _docNumber,
            getGainLossAccntId(_apaccntid), round(_glseriesTotal, 2) * -1,
           current_date, _p.notes);
  END IF;

--  Post it all
  PERFORM postGLSeries(_sequence, _journalNumber);

  RETURN _journalNumber;

END;
$$ LANGUAGE 'plpgsql';

