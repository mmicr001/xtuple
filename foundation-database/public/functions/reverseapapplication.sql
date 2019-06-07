CREATE OR REPLACE FUNCTION reverseapapplication(papplyid integer)
  RETURNS integer AS $$
DECLARE
  _r	  RECORD;
  _paid	NUMERIC;
  _round NUMERIC := 0.01;
BEGIN

  SELECT apapply_vend_id,
         apapply_postdate,
         apapply_target_apopen_id, 
         apapply_target_docnumber, 
         apapply_target_doctype, 
         apapply_source_apopen_id,
         apapply_source_docnumber, 
         apapply_source_doctype, 
         apapply_curr_id,
         apapply_amount AS aamt, 
         apapply_target_paid AS pamt,
         apapply_reversed
  INTO _r
  FROM apapply 
  WHERE apapply_id = papplyid;

-- Creates test to not allow to over unapply
  _paid := (SELECT apopen_paid
            FROM apopen 
            WHERE apopen_id = _r.apapply_target_apopen_id);

  IF ((_paid + _round) < _r.aamt) THEN
    RAISE EXCEPTION 'Amount paid is less than the applied amount [xtuple: reverseapapplication, -1]';
  END IF;

  IF (_r.apapply_reversed) THEN
    RAISE EXCEPTION 'This application has already been reversed [xtuple: reverseapapplication, -2]';
  END IF;

  INSERT INTO apapply (apapply_vend_id,
                       apapply_postdate,
                       apapply_username,
                       apapply_target_apopen_id, 
                       apapply_target_docnumber, 
                       apapply_target_doctype, 
                       apapply_source_apopen_id,
                       apapply_source_docnumber, 
                       apapply_source_doctype, 
                       apapply_curr_id,
                       apapply_amount,
                       apapply_target_paid)
  VALUES (_r.apapply_vend_id,
          _r.apapply_postdate,
          geteffectivextuser(),
          _r.apapply_target_apopen_id, 
          _r.apapply_target_docnumber, 
          _r.apapply_target_doctype, 
          _r.apapply_source_apopen_id,
          _r.apapply_source_docnumber, 
          _r.apapply_source_doctype, 
          _r.apapply_curr_id,
          _r.aamt * -1,
          _r.pamt * -1);

  UPDATE apopen SET apopen_paid = apopen_paid - _r.aamt 
  WHERE (apopen_id = _r.apapply_source_apopen_id)
    OR  (apopen_id = _r.apapply_target_apopen_id);

  UPDATE apopen SET apopen_open = true, apopen_closedate = NULL
  WHERE apopen_amount != apopen_paid 
  AND (apopen_id = _r.apapply_source_apopen_id
   OR  apopen_id = _r.apapply_target_apopen_id);

  IF (_r.apapply_source_doctype = 'K') THEN
    PERFORM createAPCreditMemo(_r.apapply_vend_id, NULL, _r.apapply_source_docnumber, '',
                               _r.apapply_postdate, _r.aamt,
                               'Check ' || _r.apapply_source_docnumber ||
                               ' to be re-applied; original date: ' || _r.apapply_postdate,
                               -1, CURRENT_DATE, NULL, _r.apapply_curr_id);
  END IF;

  UPDATE apapply SET apapply_reversed = true
  WHERE apapply_id = papplyid;

  RETURN 0;

END;
$$ LANGUAGE plpgsql;
