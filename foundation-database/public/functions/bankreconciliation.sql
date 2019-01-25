CREATE OR REPLACE FUNCTION bankReconciliation(pBankrecid INTEGER, pTask TEXT) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
-- posting and reopening bank reconciliations are nearly identical.
-- the main differences revolve around what cleanup is done before starting.
-- other than that, posting and reopening touch the same g/l accounts but with
-- debits and credits reversed.
DECLARE
  _accntid      INTEGER;
  _bankrecid    INTEGER;
  _gltransid    INTEGER;
  _post         BOOLEAN;
  _r            RECORD;
  _result       INTEGER;
  _sequence     INTEGER;
  _sign         INTEGER := 1;
  _tax          RECORD;

BEGIN

  CASE lower(pTask)
    WHEN 'post'   THEN _post = TRUE;
    WHEN 'reopen' THEN _post = FALSE;
    ELSE RAISE EXCEPTION
          'bankReconciliation got an invalid task %1 [xtuple: bankReconciliation, -2, %2]',
          pTask, pTask;
  END CASE;

  -- Check the accnt information to make sure it is valid
  SELECT accnt_id INTO _accntid
    FROM bankrec
    JOIN bankaccnt ON (bankrec_bankaccnt_id=bankaccnt_id)
    JOIN accnt     ON (bankaccnt_accnt_id=accnt_id)
   WHERE (bankrec_id=pBankrecid);
  IF ( NOT FOUND ) THEN
    RAISE EXCEPTION 'bankReconciliation %1 %2 did not find the bank''s G/L account [xtuple: bankReconciliation, -1, %3, %4]',
                    pTask, pBankrecid, pTask, pBankrecid;
  END IF;

  IF _post THEN
    DELETE FROM bankrecitem
     WHERE ( (NOT bankrecitem_cleared)
       AND   (bankrecitem_bankrec_id=pBankrecid) );

    -- Post any cleared bankadj items and convert the bankrecitem
    FOR _r IN SELECT bankrecitem_id, bankrecitem_source_id
                FROM bankrecitem, bankadj
               WHERE ( (bankrecitem_source = 'AD')
                 AND   (bankrecitem_source_id=bankadj_id)
                 AND   (bankrecitem_cleared)
                 AND   (NOT bankadj_posted)
                 AND   (bankrecitem_bankrec_id=pBankrecid) ) LOOP

      _sequence := postBankAdjustment(_r.bankrecitem_source_id);

      IF (_sequence < 0) THEN
        RAISE EXCEPTION 'postBankAdjustment %1 %2 failed during bankReconciliation [xtuple: postBankAdjustment, -10, %3, %4, %5]',
                         pTask, pBankrecid, pTask, pBankrecid, _sequence;
      END IF;

      SELECT gltrans_id INTO _gltransid
        FROM gltrans
       WHERE ( (gltrans_sequence=_sequence)
         AND   (gltrans_accnt_id=_accntid) );
      IF ( NOT FOUND ) THEN
        RAISE EXCEPTION 'bankReconciliation %1 %2 did not find exactly one gltrans record for %3 [xtuple: bankReconciliation, -11, %4, %5, %6]',
                        pTask, pBankrecid, _sequence, pTask, pBankrecid, _sequence;
      END IF;

      UPDATE bankrecitem
         SET bankrecitem_source = 'GL',
             bankrecitem_source_id=_gltransid
       WHERE (bankrecitem_id=_r.bankrecitem_id);

    END LOOP;

  ELSE -- NOT _post, therefore must be reopen
    _sign := -1;
    SELECT bankrec_id INTO _bankrecid
      FROM bankrec
     WHERE (NOT bankrec_posted);
    IF (FOUND) THEN
      -- Delete any bankrecitem records for unposted periods
      DELETE FROM bankrecitem
       WHERE (bankrecitem_bankrec_id=_bankrecid);
      -- Delete any bankrec records for unposted period
      DELETE FROM bankrec
       WHERE (bankrec_id=_bankrecid);
    END IF;
  END IF;

  IF (fetchMetricBool('CashBasedTax')) THEN
    -- Cash based tax distributions
    -- GL Transactions
    SELECT fetchGLSequence() INTO _sequence;
    FOR _r IN SELECT *
              FROM bankrecitem
             WHERE ( (bankrecitem_cleared)
               AND   (bankrecitem_bankrec_id=pBankrecid) ) LOOP
      -- first, debit the tax liability clearing account
      -- and credit the tax liability distribution account
      -- for each tax code
      FOR _tax IN SELECT docnumber, custname, distdate, source, doctype,
                         tax_sales_accnt_id, tax_dist_accnt_id,
                         ROUND(currToBase(currid, ROUND(SUM(taxdetail_tax),2), taxhead_date) * percentpaid, 2) AS taxbasevalue
                  FROM (
                        -- Cash receipt, gltrans
                        SELECT aropen_docnumber AS docnumber, cust_name AS custname,
                               aropen_curr_id AS currid, gltrans_date AS distdate,
                               (cashrcptitem_amount / aropen_amount) AS percentpaid,
                               gltrans_source AS source, gltrans_doctype AS doctype,
                               tax_sales_accnt_id, tax_dist_accnt_id,
                               taxdetail_tax, taxhead_date
                        FROM gltrans JOIN cashrcpt  ON ((gltrans_source='A/R')
                                                    AND (gltrans_doctype='CR')
                                                    AND (gltrans_misc_id=cashrcpt_id))
                                     JOIN cashrcptitem ON (cashrcptitem_cashrcpt_id=cashrcpt_id)
                                     JOIN aropen ON (aropen_id=cashrcptitem_aropen_id)
                                     JOIN custinfo ON (cust_id=aropen_cust_id)
                                     LEFT OUTER JOIN invchead ON aropen_cobmisc_id = invchead_id
                                     LEFT OUTER JOIN cmhead ON aropen_doctype = 'C'
                                                           AND COALESCE(aropen_applyto, '') != ''
                                                           AND aropen_cobmisc_id = -1
                                                           AND aropen_docnumber = cmhead_number
                                     JOIN taxhead ON taxhead_doc_type =
                                                     CASE WHEN invchead_id IS NOT NULL THEN 'INV'
                                                          WHEN cmhead_id IS NOT NULL THEN 'CM'
                                                          ELSE 'AR'
                                                      END
                                                 AND taxhead_doc_id = COALESCE(invchead_id,
                                                                               cmhead_id,
                                                                               aropen_id)
                                     JOIN taxline ON taxhead_id = taxline_taxhead_id
                                     JOIN taxdetail ON taxline_id = taxdetail_taxline_id
                                     LEFT OUTER JOIN tax ON (tax_id=taxdetail_tax_id)
                        WHERE (gltrans_id=_r.bankrecitem_source_id)
                        -- Cash receipt, sltrans
                        UNION ALL
                        SELECT aropen_docnumber AS docnumber, cust_name AS custname,
                               aropen_curr_id AS currid, sltrans_date AS distdate,
                               (cashrcptitem_amount / aropen_amount) AS percentpaid,
                               sltrans_source AS source, sltrans_doctype AS doctype,
                               tax_sales_accnt_id, tax_dist_accnt_id,
                               taxdetail_tax, taxhead_date
                        FROM sltrans JOIN cashrcpt  ON ((sltrans_source='A/R')
                                                    AND (sltrans_doctype='CR')
                                                    AND (sltrans_misc_id=cashrcpt_id))
                                     JOIN cashrcptitem ON (cashrcptitem_cashrcpt_id=cashrcpt_id)
                                     JOIN aropen ON (aropen_id=cashrcptitem_aropen_id)
                                     JOIN custinfo ON (cust_id=aropen_cust_id)
                                     LEFT OUTER JOIN invchead ON aropen_cobmisc_id = invchead_id
                                     LEFT OUTER JOIN cmhead ON aropen_doctype = 'C'
                                                           AND COALESCE(aropen_applyto, '') != ''
                                                           AND aropen_cobmisc_id = -1
                                                           AND aropen_docnumber = cmhead_number
                                     JOIN taxhead ON taxhead_doc_type =
                                                     CASE WHEN invchead_id IS NOT NULL THEN 'INV'
                                                          WHEN cmhead_id IS NOT NULL THEN 'CM'
                                                          ELSE 'AR'
                                                      END
                                                 AND taxhead_doc_id = COALESCE(invchead_id, 
                                                                               cmhead_id,
                                                                               aropen_id)
                                     JOIN taxline ON taxhead_id = taxline_taxhead_id
                                     JOIN taxdetail ON taxline_id = taxdetail_taxline_id
                                     LEFT OUTER JOIN tax ON (tax_id=taxdetail_tax_id)
                        WHERE (sltrans_id=_r.bankrecitem_source_id)
                        -- Cash payment, gltrans
                        UNION ALL
                        SELECT apopen_docnumber AS docnumber, vend_name AS vendname,
                               apopen_curr_id AS currid, gltrans_date AS distdate,
                               (checkitem_amount / apopen_amount) AS percentpaid,
                               gltrans_source AS source, gltrans_doctype AS doctype,
                               tax_sales_accnt_id, tax_dist_accnt_id,
                               taxdetail_tax, taxhead_date
                        FROM gltrans JOIN checkhead ON ((gltrans_source='A/P')
                                                    AND (gltrans_doctype='CK')
                                                    AND (gltrans_misc_id=checkhead_id))
                                     JOIN checkitem ON (checkitem_checkhead_id=checkhead_id)
                                     JOIN apopen ON (apopen_id=checkitem_apopen_id)
                                     JOIN vohead ON (vohead_number=apopen_docnumber)
                                     JOIN vendinfo ON (vend_id=apopen_vend_id)
                                     JOIN taxhead ON taxhead_doc_type = 'VCH'
                                                 AND taxhead_doc_id = vohead_id
                                     JOIN taxline ON taxhead_id = taxline_taxhead_id
                                     JOIN taxdetail ON taxline_id = taxdetail_taxline_id
                                     LEFT OUTER JOIN tax ON (tax_id=taxdetail_tax_id)
                        WHERE (gltrans_id=_r.bankrecitem_source_id)
                        -- Cash payment, sltrans
                        UNION ALL
                        SELECT apopen_docnumber AS docnumber, vend_name AS vendname,
                               apopen_curr_id AS currid, sltrans_date AS distdate,
                               (checkitem_amount / apopen_amount) AS percentpaid,
                               sltrans_source AS source, sltrans_doctype AS doctype,
                               tax_sales_accnt_id, tax_dist_accnt_id,
                               taxdetail_tax, taxhead_date
                        FROM sltrans JOIN checkhead ON ((sltrans_source='A/P')
                                                    AND (sltrans_doctype='CK')
                                                    AND (sltrans_misc_id=checkhead_id))
                                     JOIN checkitem ON (checkitem_checkhead_id=checkhead_id)
                                     JOIN apopen ON (apopen_id=checkitem_apopen_id)
                                     JOIN vohead ON (vohead_number=apopen_docnumber)
                                     JOIN vendinfo ON (vend_id=apopen_vend_id)
                                     JOIN taxhead ON taxhead_doc_type = 'VCH'
                                                 AND taxhead_doc_id = vohead_id
                                     JOIN taxline ON taxhead_id = taxline_taxhead_id
                                     JOIN taxdetail ON taxline_id = taxdetail_taxline_id
                                     LEFT OUTER JOIN tax ON (tax_id=taxdetail_tax_id)
                        WHERE (sltrans_id=_r.bankrecitem_source_id)
                        -- Miscellaneous Payments, gltrans
                        UNION ALL
                        SELECT checkhead_number::TEXT AS docnumber, 
                               COALESCE(vend_name, cust_name) AS vendname,
                               checkhead_curr_id AS currid, gltrans_date AS distdate,
                               1 AS percentpaid,
                               gltrans_source AS source, gltrans_doctype AS doctype,
                               tax_sales_accnt_id, tax_dist_accnt_id,
                               taxdetail_tax, taxhead_date
                        FROM gltrans JOIN checkhead ON ((gltrans_source='A/P')
                                                    AND (gltrans_doctype='CK')
                                                    AND (gltrans_misc_id=checkhead_id))
                                     JOIN taxhead ON taxhead_doc_type = 'CK'
                                                 AND taxhead_doc_id = checkhead_id
                                     JOIN taxline ON taxhead_id = taxline_taxhead_id
                                     JOIN taxdetail ON taxline_id = taxdetail_taxline_id
                                     LEFT OUTER JOIN tax ON (tax_id=taxdetail_tax_id)
                                     LEFT OUTER JOIN vendinfo ON (checkhead_recip_id=vend_id)
                                     LEFT OUTER JOIN custinfo ON (checkhead_recip_id=cust_id)
                        WHERE (gltrans_id=_r.bankrecitem_source_id)
                        -- Miscellaneous Payments, sltrans
                        UNION ALL
                        SELECT checkhead_number::TEXT AS docnumber, 
                               COALESCE(vend_name, cust_name) AS vendname,
                               checkhead_curr_id AS currid, sltrans_date AS distdate,
                               1 AS percentpaid,
                               sltrans_source AS source, sltrans_doctype AS doctype,
                               tax_sales_accnt_id, tax_dist_accnt_id,
                               taxdetail_tax, taxhead_date
                        FROM sltrans JOIN checkhead ON ((sltrans_source='A/P')
                                                    AND (sltrans_doctype='CK')
                                                    AND (sltrans_misc_id=checkhead_id))
                                     JOIN taxhead ON taxhead_doc_type = 'CK'
                                                 AND taxhead_doc_id = checkhead_id
                                     JOIN taxline ON taxhead_id = taxline_taxhead_id
                                     JOIN taxdetail ON taxline_id = taxdetail_taxline_id
                                     LEFT OUTER JOIN tax ON (tax_id=taxdetail_tax_id)
                                     LEFT OUTER JOIN vendinfo ON (checkhead_recip_id=vend_id)
                                     LEFT OUTER JOIN custinfo ON (checkhead_recip_id=cust_id)
                        WHERE (sltrans_id=_r.bankrecitem_source_id)
                       ) AS data
                  GROUP BY docnumber, custname, currid, distdate, percentpaid,
                           source, doctype,
                           tax_sales_accnt_id, tax_dist_accnt_id, taxhead_date
      LOOP
        IF (_tax.tax_sales_accnt_id IS NULL OR _tax.tax_dist_accnt_id IS NULL) THEN
          RAISE EXCEPTION 'Cannot post this bank reconciliation due to missing Tax Code G/L Account mappings';
        END IF;  
        SELECT insertIntoGLSeries( _sequence, _tax.source, _tax.doctype, _tax.docnumber,
                                   _tax.tax_dist_accnt_id, 
                                   _tax.taxbasevalue * _sign,
                                   COALESCE(_r.bankrecitem_effdate, _tax.distdate), _tax.custname ) INTO _result;
        IF (_result < 0) THEN
          RAISE EXCEPTION 'insertIntoGLSeries failed, result=%', _result;
        END IF;
        SELECT insertIntoGLSeries( _sequence, _tax.source, _tax.doctype, _tax.docnumber,
                                   _tax.tax_sales_accnt_id, 
                                   (_tax.taxbasevalue * -1.0 * _sign),
                                   COALESCE(_r.bankrecitem_effdate, _tax.distdate), _tax.custname ) INTO _result;
        IF (_result < 0) THEN
          RAISE EXCEPTION 'insertIntoGLSeries failed, result=%', _result;
        END IF;
      END LOOP;

      -- second, add taxpay info to each taxdetail
      FOR _tax IN SELECT taxdetail_id, distdate,
                         ROUND(taxdetail_tax * percentpaid, 2) AS taxpaid
                  FROM (
                        -- Cash receipt, gltrans
                        SELECT taxdetail_id, gltrans_date AS distdate, taxdetail_tax,
                               (cashrcptitem_amount / aropen_amount) AS percentpaid
                          FROM gltrans JOIN cashrcpt  ON ((gltrans_source='A/R')
                                                      AND (gltrans_doctype='CR')
                                                      AND (gltrans_misc_id=cashrcpt_id))
                                       JOIN cashrcptitem ON (cashrcptitem_cashrcpt_id=cashrcpt_id)
                                       JOIN aropen ON (aropen_id=cashrcptitem_aropen_id)
                                       LEFT OUTER JOIN invchead ON aropen_cobmisc_id = invchead_id
                                       LEFT OUTER JOIN cmhead ON aropen_doctype = 'C'
                                                             AND COALESCE(aropen_applyto, '') != ''
                                                             AND aropen_cobmisc_id = -1
                                                             AND aropen_docnumber = cmhead_number
                                       JOIN taxhead ON taxhead_doc_type =
                                                       CASE WHEN invchead_id IS NOT NULL THEN 'INV'
                                                            WHEN cmhead_id IS NOT NULL THEN 'CM'
                                                            ELSE 'AR'
                                                        END
                                                   AND taxhead_doc_id = COALESCE(invchead_id,
                                                                                 cmhead_id,
                                                                                 aropen_id)
                                       JOIN taxline ON taxhead_id = taxline_taxhead_id
                                       JOIN taxdetail ON taxline_id = taxdetail_taxline_id
                          WHERE (gltrans_id=_r.bankrecitem_source_id)
                        -- Cash receipt, sltrans
                        UNION
                        SELECT taxdetail_id, sltrans_date AS distdate, taxdetail_tax,
                               (cashrcptitem_amount / aropen_amount) AS percentpaid
                          FROM sltrans JOIN cashrcpt  ON ((sltrans_source='A/R')
                                                      AND (sltrans_doctype='CR')
                                                      AND (sltrans_misc_id=cashrcpt_id))
                                       JOIN cashrcptitem ON (cashrcptitem_cashrcpt_id=cashrcpt_id)
                                       JOIN aropen ON (aropen_id=cashrcptitem_aropen_id)
                                       LEFT OUTER JOIN invchead ON aropen_cobmisc_id = invchead_id
                                       LEFT OUTER JOIN cmhead ON aropen_doctype = 'C'
                                                             AND COALESCE(aropen_applyto, '') != ''
                                                             AND aropen_cobmisc_id = -1
                                                             AND aropen_docnumber = cmhead_number
                                       JOIN taxhead ON taxhead_doc_type =
                                                       CASE WHEN invchead_id IS NOT NULL THEN 'INV'
                                                            WHEN cmhead_id IS NOT NULL THEN 'CM'
                                                            ELSE 'AR'
                                                        END
                                                   AND taxhead_doc_id = COALESCE(invchead_id,
                                                                                 cmhead_id,
                                                                                 aropen_id)
                                       JOIN taxline ON taxhead_id = taxline_taxhead_id
                                       JOIN taxdetail ON taxline_id = taxdetail_taxline_id
                          WHERE (sltrans_id=_r.bankrecitem_source_id)
                        -- Cash payment, gltrans
                        UNION
                        SELECT taxdetail_id, gltrans_date AS distdate, taxdetail_tax,
                               (checkitem_amount / apopen_amount) AS percentpaid
                          FROM gltrans JOIN checkhead  ON ((gltrans_source='A/P')
                                                       AND (gltrans_doctype='CK')
                                                       AND (gltrans_misc_id=checkhead_id))
                                       JOIN checkitem ON (checkitem_checkhead_id=checkhead_id)
                                       JOIN apopen ON (apopen_id=checkitem_apopen_id)
                                       JOIN vohead ON (vohead_number=apopen_docnumber)
                                       JOIN vendinfo ON (vend_id=apopen_vend_id)
                                       JOIN taxhead ON taxhead_doc_type = 'VCH'
                                                   AND taxhead_doc_id = vohead_id
                                       JOIN taxline ON taxhead_id = taxline_taxhead_id
                                       JOIN taxdetail ON taxline_id = taxdetail_taxline_id
                          WHERE (gltrans_id=_r.bankrecitem_source_id)
                        -- Cash payment, sltrans
                        UNION
                        SELECT taxdetail_id, sltrans_date AS distdate, taxdetail_tax,
                               (checkitem_amount / apopen_amount) AS percentpaid
                          FROM sltrans JOIN checkhead  ON ((sltrans_source='A/P')
                                                       AND (sltrans_doctype='CK')
                                                       AND (sltrans_misc_id=checkhead_id))
                                       JOIN checkitem ON (checkitem_checkhead_id=checkhead_id)
                                       JOIN apopen ON (apopen_id=checkitem_apopen_id)
                                       JOIN vohead ON (vohead_number=apopen_docnumber)
                                       JOIN vendinfo ON (vend_id=apopen_vend_id)
                                       JOIN taxhead ON taxhead_doc_type = 'VCH'
                                                   AND taxhead_doc_id = vohead_id
                                       JOIN taxline ON taxhead_id = taxline_taxhead_id
                                       JOIN taxdetail ON taxline_id = taxdetail_taxline_id
                          WHERE (sltrans_id=_r.bankrecitem_source_id)
                        -- Miscellaneous Payment , gltrans
                        UNION
                        SELECT taxdetail_id, gltrans_date AS distdate, taxdetail_tax,
                               1.00 AS percentpaid
                          FROM gltrans JOIN checkhead  ON ((gltrans_source='A/P')
                                                       AND (gltrans_doctype='CK')
                                                       AND (gltrans_misc_id=checkhead_id))
                                       JOIN taxhead ON taxhead_doc_type = 'CK'
                                                   AND taxhead_doc_id = checkhead_id
                                       JOIN taxline ON taxhead_id = taxline_taxhead_id
                                       JOIN taxdetail ON taxline_id = taxdetail_taxline_id
                          WHERE (gltrans_id=_r.bankrecitem_source_id)
                        -- Miscellaneous Payment , sltrans
                        UNION
                        SELECT taxdetail_id, sltrans_date AS distdate, taxdetail_tax,
                               1.00 AS percentpaid
                          FROM sltrans JOIN checkhead  ON ((sltrans_source='A/P')
                                                       AND (sltrans_doctype='CK')
                                                       AND (sltrans_misc_id=checkhead_id))
                                       JOIN taxhead ON taxhead_doc_type = 'CK'
                                                   AND taxhead_doc_id = checkhead_id
                                       JOIN taxline ON taxhead_id = taxline_taxhead_id
                                       JOIN taxdetail ON taxline_id = taxdetail_taxline_id
                          WHERE (sltrans_id=_r.bankrecitem_source_id)
                       ) AS data
      LOOP
        IF _post THEN
          UPDATE taxdetail
             SET taxdetail_paydate = COALESCE(_r.bankrecitem_effdate, _tax.distdate),
                 taxdetail_tax_paid = _tax.taxpaid
           WHERE taxdetail_id = _tax.taxdetail_id;
        ELSE
          UPDATE taxdetail
             SET taxdetail_paydate = NULL,
                 taxdetail_tax_paid = NULL
           WHERE taxdetail_id = _tax.taxdetail_id;
        END IF;
      END LOOP;

    END LOOP;

    SELECT postGLSeries(_sequence, fetchJournalNumber('GL-MISC')) INTO _result;
    IF (_result < 0) THEN
      RAISE EXCEPTION 'postGLSeries failed, result=%', _result;
    END IF;

  END IF;

  UPDATE gltrans
     SET gltrans_rec = _post
   WHERE ( (gltrans_id IN (SELECT bankrecitem_source_id
                             FROM bankrecitem
                            WHERE ((bankrecitem_source = 'GL')
                              AND  (bankrecitem_cleared)
                              AND  (bankrecitem_bankrec_id=pBankrecid) ) ) )
     AND   (gltrans_accnt_id=_accntid) ) ;

  UPDATE sltrans
     SET sltrans_rec = _post
   WHERE ( (sltrans_id IN (SELECT bankrecitem_source_id
                             FROM bankrecitem
                            WHERE ((bankrecitem_source = 'SL')
                              AND  (bankrecitem_cleared)
                              AND  (bankrecitem_bankrec_id=pBankrecid) ) ) )
     AND   (sltrans_accnt_id=_accntid) ) ;

  UPDATE bankrec SET 
    bankrec_posted = _post,
    bankrec_postdate = CASE _post WHEN TRUE THEN now() ELSE NULL END
   WHERE (bankrec_id=pBankrecid);

  RETURN pBankrecid;
END;

$$ LANGUAGE 'plpgsql';

