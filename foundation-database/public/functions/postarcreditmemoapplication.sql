DROP FUNCTION IF EXISTS postARCreditMemoApplication(INTEGER);

CREATE OR REPLACE FUNCTION postARCreditMemoApplication(pAropenid INTEGER,
                                                       pApplyDate DATE DEFAULT NULL)
  RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _applyDate DATE;
  _p RECORD;
  _r RECORD;
  _totalSource NUMERIC := 0;
  _totalTarget NUMERIC := 0;
  _exchGain NUMERIC := 0;
  _result NUMERIC;
  _araccntid INTEGER;

BEGIN

  SELECT COALESCE(pApplyDate, GREATEST(s.aropen_distdate, MAX(t.aropen_distdate)), CURRENT_DATE)
    INTO _applyDate
    FROM aropen s
    LEFT OUTER JOIN arcreditapply ON s.aropen_id = arcreditapply_source_aropen_id
    LEFT OUTER JOIN aropen t ON arcreditapply_target_aropen_id = t.aropen_id
   WHERE s.aropen_id = pAropenid
   GROUP BY s.aropen_distdate;

  -- find source CM and calc total amount to apply in CM currency
  SELECT ROUND(aropen_amount - aropen_paid, 2) AS balance,
         ROUND(SUM(currToCurr(arcreditapply_curr_id, aropen_curr_id,
               COALESCE(arcreditapply_amount, 0), _applyDate)), 2) AS toApply INTO _p
  FROM aropen JOIN arcreditapply ON (arcreditapply_source_aropen_id=aropen_id)
  WHERE (aropen_id=pAropenid)
  GROUP BY aropen_amount, aropen_paid;
  IF (NOT FOUND) THEN
    RETURN -1;
  ELSIF (_p.toApply = 0) THEN
    RETURN -2;
  ELSIF (_p.toApply > _p.balance) THEN
    RETURN -3;
  END IF;

-- cache source CM
  SELECT aropen_cust_id, aropen_docnumber, aropen_doctype, aropen_amount,
         aropen_curr_id, aropen_docdate, aropen_accnt_id, aropen_cust_id,
         aropen_curr_id, aropen_curr_rate INTO _p
  FROM aropen
  WHERE (aropen_id=pAropenid);
  IF (NOT FOUND) THEN
    RETURN -5;
  END IF;

-- loop thru each arcreditapply
  FOR _r IN SELECT arcreditapply_id, arcreditapply_target_aropen_id,
                   arcreditapply_reftype, arcreditapply_ref_id, arcreditapply_curr_id,
                   currToCurr(arcreditapply_curr_id, _p.aropen_curr_id,
                              arcreditapply_amount, _applyDate) AS arcreditapply_amountSource,
                   currToCurr(arcreditapply_curr_id, aropen_curr_id,
                              arcreditapply_amount, _applyDate) AS arcreditapply_amountTarget,
                   aropen_doctype, aropen_docnumber, aropen_docdate, aropen_curr_rate
            FROM arcreditapply JOIN aropen ON (aropen_id=arcreditapply_target_aropen_id)
            WHERE (arcreditapply_source_aropen_id=pAropenid)
  LOOP

    IF (_r.arcreditapply_amountTarget IS NULL) THEN
      RETURN -4;
    END IF;

    IF (_r.arcreditapply_amountTarget <> 0) THEN

--  Update the target invoice aropen item to post the paid amount
      UPDATE aropen
      SET aropen_paid = round(aropen_paid + _r.arcreditapply_amountTarget, 2)
      WHERE (aropen_id=_r.arcreditapply_target_aropen_id);

      UPDATE aropen
      SET aropen_open = (round(aropen_amount, 2) > round(aropen_paid, 2))
      WHERE (aropen_id=_r.arcreditapply_target_aropen_id);

--  Cache the running amount posted
      _totalSource := (_totalSource + _r.arcreditapply_amountSource);
      _totalTarget := (_totalTarget + _r.arcreditapply_amountTarget);

--  Record the application
      INSERT INTO arapply
      ( arapply_cust_id,
        arapply_source_aropen_id, arapply_source_doctype, arapply_source_docnumber,
        arapply_target_aropen_id, arapply_target_doctype, arapply_target_docnumber,
        arapply_fundstype, arapply_refnumber,
        arapply_applied, arapply_closed, arapply_postdate, arapply_distdate,
        arapply_journalnumber, arapply_username, arapply_curr_id,
        arapply_reftype, arapply_ref_id )
      VALUES
      ( _p.aropen_cust_id,
        pAropenid, _p.aropen_doctype, _p.aropen_docnumber,
        _r.arcreditapply_target_aropen_id, _r.aropen_doctype, _r.aropen_docnumber,
        '', '',
        round(_r.arcreditapply_amountSource, 2), TRUE, _applyDate, _applyDate,
        0, getEffectiveXtUser(), _p.aropen_curr_id, 
        _r.arcreditapply_reftype, _r.arcreditapply_ref_id );

    END IF;

--  Delete the posted arcreditapply record
    DELETE FROM arcreditapply
    WHERE (arcreditapply_id=_r.arcreditapply_id);

    IF (_r.aropen_docdate > _p.aropen_docdate) THEN
      _exchGain := (_totalTarget / _r.aropen_curr_rate - _totalSource / _p.aropen_curr_rate) * -1;
    ELSE
      _exchGain := _totalSource / _p.aropen_curr_rate - _totalTarget / _r.aropen_curr_rate;
    END IF;

    IF (_p.aropen_accnt_id > -1) THEN
      _araccntid := _p.aropen_accnt_id;
    ELSE 
      _araccntid := findARAccount(_p.aropen_cust_id);
    END IF;
    
    IF (_exchGain <> 0) THEN
        PERFORM insertGLTransaction(fetchJournalNumber('AR-MISC'), 'A/R',
                                    'CR', _p.aropen_docnumber, 'CM Application',
                                    _araccntid, getGainLossAccntId(_araccntid),
                                    -1, _exchGain * -1, _applyDate);
    END IF;

  END LOOP;

-- TODO: If this is a Customer Deposit (aropen_doctype='R')
--       the we need to convert the total to a base transaction
  IF(_p.aropen_doctype='R') THEN
    SELECT insertGLTransaction(fetchJournalNumber('AR-MISC'), 'A/R',
                               'CD', _p.aropen_docnumber, 'CM Application',
                               cr.accnt_id, db.accnt_id,
                               -1, (_totalSource / _p.aropen_curr_rate),
                               _applyDate)
      INTO _result
      FROM accnt AS cr, accnt AS db
     WHERE ((db.accnt_id = findDeferredAccount(_p.aropen_cust_id))
       AND  (cr.accnt_id = findARAccount(_p.aropen_cust_id)) );
    IF(NOT FOUND OR _result < 0) THEN
      RAISE EXCEPTION 'There was an error posting the Customer Deposit GL Transactions.';
    END IF;
  END IF;

--  Record the amount posted and mark the source CM aropen as closed if it is completely posted
  UPDATE aropen
  SET aropen_paid = round(aropen_paid + _totalSource, 2)
  WHERE (aropen_id=pAropenid);

  UPDATE aropen
  SET aropen_open = (round(aropen_amount, 2) > round(aropen_paid, 2))
  WHERE (aropen_id=pAropenid);

  RETURN pAropenid;

END;
$$ LANGUAGE plpgsql;

