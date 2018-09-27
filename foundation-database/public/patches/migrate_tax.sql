DO $$
BEGIN

  IF compareVersion(fetchMetricText('ServerVersion'), '5.0.0-alpha') = -1 THEN
    PERFORM setMetric('TaxService', 'N');

    PERFORM saveTax('Q', quhead_id, calculateOrderTax('Q', quhead_id))
       FROM quhead;

    PERFORM saveTax('S', cohead_id, calculateOrderTax('S', cohead_id))
       FROM cohead;

    -- Old data must be fixed or the recalculation will error
    UPDATE cobill
       SET cobill_qty = (SELECT SUM(cobill_qty)
                           FROM cobill b
                          WHERE b.cobill_cobmisc_id = cobill_cobmisc_id
                            AND b.cobill_coitem_id = cobill_coitem_id);

    DELETE FROM cobill
     WHERE cobill_id != (SELECT MIN(cobill_id)
                           FROM cobill b
                          WHERE b.cobill_cobmisc_id = cobill_cobmisc_id
                            AND b.cobill_coitem_id = cobill_coitem_id);

    PERFORM saveTax('COB', cobmisc_id, calculateOrderTax('COB', cobmisc_id))
       FROM cobmisc;

    PERFORM saveTax('INV', invchead_id, calculateOrderTax('INV', invchead_id))
       FROM invchead
      WHERE NOT invchead_posted;

    PERFORM saveTax('P', pohead_id, calculateOrderTax('P', pohead_id))
       FROM pohead;

    PERFORM saveTax('VCH', vohead_id, calculateOrderTax('VCH', vohead_id))
       FROM vohead
      WHERE NOT vohead_posted;

    PERFORM saveTax('CM', cmhead_id, calculateOrderTax('CM', cmhead_id))
       FROM cmhead
      WHERE NOT cmhead_posted;

    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_taxtype_id)
    SELECT taxhead_id, 'A', getAdjustmentTaxtypeId()
      FROM cobmisc
      JOIN taxhead ON taxhead_doc_type = 'COB'
                  AND cobmisc_id = taxhead_doc_id
     WHERE EXISTS(SELECT 1
                    FROM cobmisctax
                   WHERE taxhist_parent_id = taxhead_doc_id
                     AND taxhist_taxtype_id = getAdjustmentTaxtypeId());

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_tax_id, taxdetail_tax)
    SELECT taxline_id, taxhist_tax_id, taxhist_tax
      FROM cobmisc
      JOIN cobmisctax ON cobmisc_id = taxhist_parent_id
      JOIN taxhead ON taxhead_doc_type = 'COB'
                  AND cobmisc_id = taxhead_doc_id
      JOIN taxline ON taxhead_id = taxline_taxhead_id
                  AND taxline_line_type = 'A'
     WHERE taxhist_taxtype_id = getAdjustmentTaxtypeId();

    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_taxtype_id)
    SELECT taxhead_id, 'A', getAdjustmentTaxtypeId()
      FROM invchead
      JOIN taxhead ON taxhead_doc_type = 'INV'
                  AND invchead_id = taxhead_doc_id
     WHERE NOT invchead_posted
       AND EXISTS(SELECT 1
                    FROM invcheadtax
                   WHERE taxhist_parent_id = taxhead_doc_id
                     AND taxhist_taxtype_id = getAdjustmentTaxtypeId());

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_tax_id, taxdetail_tax)
    SELECT taxline_id, taxhist_tax_id, taxhist_tax
      FROM invchead
      JOIN invcheadtax ON invchead_id = taxhist_parent_id
      JOIN taxhead ON taxhead_doc_type = 'INV'
                  AND invchead_id = taxhead_doc_id
      JOIN taxline ON taxhead_id = taxline_taxhead_id
                  AND taxline_line_type = 'A'
     WHERE NOT invchead_posted
       AND taxhist_taxtype_id = getAdjustmentTaxtypeId();

    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_taxtype_id)
    SELECT taxhead_id, 'A', getAdjustmentTaxtypeId()
      FROM vohead
      JOIN taxhead ON taxhead_doc_type = 'VCH'
                  AND vohead_id = taxhead_doc_id
     WHERE NOT vohead_posted
       AND EXISTS(SELECT 1
                    FROM voheadtax
                   WHERE taxhist_parent_id = taxhead_doc_id
                     AND taxhist_taxtype_id = getAdjustmentTaxtypeId());

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_tax_id, taxdetail_tax)
    SELECT taxline_id, taxhist_tax_id, taxhist_tax
      FROM vohead
      JOIN voheadtax ON vohead_id = taxhist_parent_id
      JOIN taxhead ON taxhead_doc_type = 'VCH'
                  AND vohead_id = taxhead_doc_id
      JOIN taxline ON taxhead_id = taxline_taxhead_id
                  AND taxline_line_type = 'A'
     WHERE NOT vohead_posted
       AND taxhist_taxtype_id = getAdjustmentTaxtypeId();

    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_taxtype_id)
    SELECT taxhead_id, 'A', getAdjustmentTaxtypeId()
      FROM cmhead
      JOIN taxhead ON taxhead_doc_type = 'CM'
                  AND cmhead_id = taxhead_doc_id
     WHERE NOT cmhead_posted
       AND EXISTS(SELECT 1
                    FROM cmheadtax
                   WHERE taxhist_parent_id = taxhead_doc_id
                     AND taxhist_taxtype_id = getAdjustmentTaxtypeId());

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_tax_id, taxdetail_tax)
    SELECT taxline_id, taxhist_tax_id, taxhist_tax
      FROM cmhead
      JOIN cmheadtax ON cmhead_id = taxhist_parent_id
      JOIN taxhead ON taxhead_doc_type = 'CM'
                  AND cmhead_id = taxhead_doc_id
      JOIN taxline ON taxhead_id = taxline_taxhead_id
                  AND taxline_line_type = 'A'
     WHERE NOT cmhead_posted
       AND taxhist_taxtype_id = getAdjustmentTaxtypeId();

    CREATE TEMPORARY TABLE asohisttmp ON COMMIT DROP AS SELECT asohist_id FROM asohist;

    PERFORM restoreSalesHistory(asohist_id)
       FROM asohist;

    INSERT INTO cohisttax ( taxhist_id,
                            taxhist_parent_id,
                            taxhist_taxtype_id,
                            taxhist_tax_id,
                            taxhist_basis,
                            taxhist_basis_tax_id,
                            taxhist_sequence,
                            taxhist_percent,
                            taxhist_amount,
                            taxhist_tax,
                            taxhist_docdate,
                            taxhist_distdate,
                            taxhist_curr_id,
                            taxhist_curr_rate,
                            taxhist_journalnumber )
    SELECT taxhist_id,
           taxhist_parent_id,
           taxhist_taxtype_id,
           taxhist_tax_id,
           taxhist_basis,
           taxhist_basis_tax_id,
           taxhist_sequence,
           taxhist_percent,
           taxhist_amount,
           taxhist_tax,
           taxhist_docdate,
           taxhist_distdate,
           taxhist_curr_id,
           taxhist_curr_rate,
           taxhist_journalnumber
    FROM asohisttax;

    CREATE TABLE IF NOT EXISTS checkheadtax() INHERITS (taxhist);

    CREATE TABLE IF NOT EXISTS taxpay
    (taxpay_taxhist_id INTEGER, taxpay_distdate DATE, taxpay_tax NUMERIC);

    INSERT INTO taxhead (taxhead_status, taxhead_doc_type, taxhead_doc_id,
                         taxhead_cust_id,
                         taxhead_date,
                         taxhead_curr_id,
                         taxhead_curr_rate,
                         taxhead_taxzone_id,
                         taxhead_distdate,
                         taxhead_journalnumber)
    SELECT DISTINCT ON (invchead_id)
           CASE WHEN invchead_void THEN 'V' ELSE 'P' END, 'INV', invchead_id,
           COALESCE(cohist_cust_id, invchead_cust_id),
           COALESCE(cohisttax.taxhist_docdate, invcheadtax.taxhist_docdate,
                    invcitemtax.taxhist_docdate, cohist_invcdate, invchead_invcdate),
           COALESCE(cohisttax.taxhist_curr_id, invcheadtax.taxhist_curr_id,
                    invcitemtax.taxhist_curr_id, cohist_curr_id, invchead_curr_id),
           COALESCE(cohisttax.taxhist_curr_rate, invcheadtax.taxhist_curr_rate,
                    invcitemtax.taxhist_curr_rate,
                    currRate(cohist_curr_id, cohist_invcdate),
                    currRate(invchead_curr_id, invchead_invcdate)),
           COALESCE(cohist_taxzone_id, invchead_taxzone_id),
           COALESCE(cohisttax.taxhist_distdate, aropen_distdate),
           COALESCE(cohisttax.taxhist_journalnumber, aropen_journalnumber)
      FROM invchead
      LEFT OUTER JOIN cohist ON cohist_doctype = 'I'
                            AND invchead_id = cohist_invchead_id
      LEFT OUTER JOIN cohisttax ON cohist_id = cohisttax.taxhist_parent_id
      LEFT OUTER JOIN invcheadtax ON invchead_id = invcheadtax.taxhist_parent_id
      LEFT OUTER JOIN invcitem ON invchead_void
                              AND invchead_id = invcitem_invchead_id
      LEFT OUTER JOIN invcitemtax ON invchead_void
                                 AND invcitem_id = invcitemtax.taxhist_parent_id
      LEFT OUTER JOIN aropen ON aropen_doctype = 'I'
                            AND invchead_invcnumber = aropen_docnumber
     WHERE invchead_posted;

    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_line_id,
                         taxline_linenumber, taxline_subnumber, taxline_number, taxline_item_number,
                         taxline_taxtype_id, taxline_qty, taxline_amount, taxline_extended)
    SELECT DISTINCT ON (invchead_id, type, invcitem_id)
           taxhead_id, type, invcitem_id,
           invcitem_linenumber, invcitem_subnumber, number, item_number,
           COALESCE(cohisttax.taxhist_taxtype_id,
                    invcheadtax.taxhist_taxtype_id, invcitemtax.taxhist_taxtype_id, taxtype_id),
           qty, amt,
           CASE WHEN type != 'A' 
                THEN COALESCE(cohisttax.taxhist_basis,
                              invcheadtax.taxhist_basis, invcitemtax.taxhist_basis, ext)
            END
      FROM invchead
      JOIN taxhead ON taxhead_doc_type = 'INV'
                  AND invchead_id = taxhead_doc_id
      JOIN (
            SELECT invcitem_invchead_id AS headid, cohist_id, 'L' AS type, invcitem_id,
                   invcitem_linenumber, invcitem_subnumber,
                   formatInvcLineNumber(invcitem_id) AS number,
                   COALESCE(item_number, invcitem_number) AS item_number,
                   COALESCE(cohist_taxtype_id, invcitem_taxtype_id) AS taxtype_id,
                   COALESCE(cohist_qtyshipped, invcitem_billed / invcitem_qty_invuomratio) AS qty,
                   COALESCE(cohist_unitprice, invcitem_price / invcitem_price_invuomratio) AS amt,
                   ROUND(COALESCE(cohist_qtyshipped, invcitem_billed / invcitem_qty_invuomratio) *
                         COALESCE(cohist_unitprice, invcitem_price / invcitem_price_invuomratio), 2)
                   AS ext
              FROM invcitem
              LEFT OUTER JOIN item ON invcitem_item_id = item_id
              LEFT OUTER JOIN cohist ON invcitem_id = cohist_invcitem_id
            UNION
            SELECT invchead_id, cohist_id, 'F', NULL,
                   1, 0,
                   NULL,
                   '',
                   getFreightTaxtypeId(),
                   NULL,
                   NULL,
                   COALESCE(cohist_unitprice, invchead_freight)
              FROM invchead
              LEFT OUTER JOIN cohist ON cohist_doctype = 'I'
                                    AND invchead_id = cohist_invchead_id
                                    AND cohist_misc_type = 'F'
             WHERE COALESCE(cohist_unitprice, invchead_freight) != 0.0
            UNION
            SELECT invchead_id, cohist_id, 'M', NULL,
                   1, 0,
                   NULL,
                   '',
                   getMiscTaxtypeId(),
                   NULL,
                   NULL,
                   COALESCE(cohist_unitprice, invchead_misc_amount)
              FROM invchead 
              LEFT OUTER JOIN cohist ON cohist_doctype = 'I'
                                    AND invchead_id = cohist_invchead_id
                                    AND cohist_misc_type = 'M'
             WHERE COALESCE(cohist_unitprice, invchead_misc_amount) != 0.0
            UNION
            SELECT invchead_id, cohist_id, 'A', NULL,
                   1, 0,
                   NULL,
                   '',
                   getAdjustmentTaxtypeId(),
                   NULL,
                   NULL,
                   NULL
              FROM invchead
              LEFT OUTER JOIN cohist ON cohist_doctype = 'I'
                                    AND invchead_id = cohist_invchead_id
                                    AND cohist_misc_type = 'T'
              LEFT OUTER JOIN cohisttax ON cohist_id = cohisttax.taxhist_parent_id
              LEFT OUTER JOIN invcheadtax ON invchead_void
                                         AND invchead_id = invcheadtax.taxhist_parent_id
                                         AND invcheadtax.taxhist_taxtype_id =
                                             getAdjustmentTaxtypeId()
             WHERE cohisttax.taxhist_id IS NOT NULL OR invcheadtax.taxhist_id IS NOT NULL
             GROUP BY invchead_id, cohist_id
           ) lines ON invchead_id = headid
      LEFT OUTER JOIN cohisttax ON cohist_id = cohisttax.taxhist_parent_id
      LEFT OUTER JOIN invcheadtax ON invchead_void
                                 AND invchead_id = invcheadtax.taxhist_parent_id
                                 AND ((type = 'F'
                                       AND invcheadtax.taxhist_taxtype_id =
                                           getFreightTaxtypeId())
                                      OR (type = 'A'
                                          AND invcheadtax.taxhist_taxtype_id =
                                              getAdjustmentTaxtypeId()))
      LEFT OUTER JOIN invcitemtax ON invchead_void
                                 AND invcitem_id = invcitemtax.taxhist_parent_id
                                 AND type = 'L'
     WHERE invchead_posted;

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                           taxdetail_taxclass_id, taxdetail_sequence, taxdetail_basis_tax_id,
                           taxdetail_amount, taxdetail_percent, taxdetail_tax, taxdetail_paydate,
                           taxdetail_tax_paid)
    SELECT taxline_id, taxable, tax_id,
           tax_taxclass_id, sequence, basis,
           amount, percent, tax, taxpay_distdate,
           taxpay_tax
      FROM invchead
      JOIN (
            SELECT invcitem_invchead_id AS headid, taxline_id,
                   COALESCE(cohisttax.taxhist_basis, invcitemtax.taxhist_basis) AS taxable,
                   tax_id, tax_taxclass_id,
                   COALESCE(cohisttax.taxhist_sequence, invcitemtax.taxhist_sequence) AS sequence,
                   COALESCE(cohisttax.taxhist_basis_tax_id,
                            invcitemtax.taxhist_basis_tax_id) AS basis,
                   COALESCE(cohisttax.taxhist_amount, invcitemtax.taxhist_amount) AS amount,
                   COALESCE(cohisttax.taxhist_percent, invcitemtax.taxhist_percent) AS percent,
                   COALESCE(cohisttax.taxhist_tax, invcitemtax.taxhist_tax) AS tax,
                   taxpay_distdate, taxpay_tax
              FROM invcitem
              JOIN invchead ON invcitem_invchead_id = invchead_id
              JOIN taxhead ON taxhead_doc_type = 'INV'
                          AND invchead_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND invcitem_id = taxline_line_id
              LEFT OUTER JOIN cohist ON invcitem_id = cohist_invcitem_id
              LEFT OUTER JOIN cohisttax ON cohist_id = cohisttax.taxhist_parent_id
              LEFT OUTER JOIN taxpay ON cohisttax.taxhist_id = taxpay_taxhist_id
              LEFT OUTER JOIN invcitemtax ON invchead_void
                                         AND invcitem_id = invcitemtax.taxhist_parent_id
              LEFT OUTER JOIN tax ON COALESCE(cohisttax.taxhist_tax_id,
                                              invcitemtax.taxhist_tax_id) = tax_id
             WHERE cohisttax.taxhist_id IS NOT NULL OR invcitemtax.taxhist_id IS NOT NULL
            UNION
            SELECT invchead_id, taxline_id,
                   COALESCE(cohisttax.taxhist_basis, invcheadtax.taxhist_basis),
                   tax_id, tax_taxclass_id,
                   COALESCE(cohisttax.taxhist_sequence, invcheadtax.taxhist_sequence),
                   COALESCE(cohisttax.taxhist_basis_tax_id, 
                            invcheadtax.taxhist_basis_tax_id),
                   COALESCE(cohisttax.taxhist_amount, invcheadtax.taxhist_amount),
                   COALESCE(cohisttax.taxhist_percent, invcheadtax.taxhist_percent),
                   COALESCE(cohisttax.taxhist_tax, invcheadtax.taxhist_tax),
                   taxpay_distdate, taxpay_tax
              FROM invchead
              JOIN taxhead ON taxhead_doc_type = 'INV'
                          AND invchead_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND taxline_line_type = 'F'
              LEFT OUTER JOIN cohist ON cohist_doctype = 'I'
                                    AND invchead_id = cohist_invchead_id
                                    AND cohist_misc_type = 'F'
              LEFT OUTER JOIN cohisttax ON cohist_id = cohisttax.taxhist_parent_id
              LEFT OUTER JOIN taxpay ON cohisttax.taxhist_id = taxpay_taxhist_id
              LEFT OUTER JOIN invcheadtax ON invchead_void
                                         AND invchead_id = invcheadtax.taxhist_parent_id
                                         AND invcheadtax.taxhist_taxtype_id =
                                             getFreightTaxtypeId()
              LEFT OUTER JOIN tax ON COALESCE(cohisttax.taxhist_tax_id,
                                              invcheadtax.taxhist_tax_id) = tax_id
             WHERE cohisttax.taxhist_id IS NOT NULL OR invcheadtax.taxhist_id IS NOT NULL
            UNION
            SELECT invchead_id, taxline_id,
                   COALESCE(cohisttax.taxhist_basis, invcheadtax.taxhist_basis),
                   tax_id, tax_taxclass_id,
                   COALESCE(cohisttax.taxhist_sequence, invcheadtax.taxhist_sequence),
                   COALESCE(cohisttax.taxhist_basis_tax_id, 
                            invcheadtax.taxhist_basis_tax_id),
                   COALESCE(cohisttax.taxhist_amount, invcheadtax.taxhist_amount),
                   COALESCE(cohisttax.taxhist_percent, invcheadtax.taxhist_percent),
                   COALESCE(cohisttax.taxhist_tax, invcheadtax.taxhist_tax),
                   taxpay_distdate, taxpay_tax
              FROM invchead
              JOIN taxhead ON taxhead_doc_type = 'INV'
                          AND invchead_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND taxline_line_type = 'A'
              LEFT OUTER JOIN cohist ON cohist_doctype = 'I'
                                    AND invchead_id = cohist_invchead_id
                                    AND cohist_misc_type = 'T'
              LEFT OUTER JOIN cohisttax ON cohist_id = cohisttax.taxhist_parent_id
              LEFT OUTER JOIN taxpay ON cohisttax.taxhist_id = taxpay_taxhist_id
              LEFT OUTER JOIN invcheadtax ON invchead_void
                                         AND invchead_id = invcheadtax.taxhist_parent_id
                                         AND invcheadtax.taxhist_taxtype_id =
                                             getAdjustmentTaxtypeId()
              LEFT OUTER JOIN tax ON COALESCE(cohisttax.taxhist_tax_id,
                                              invcheadtax.taxhist_tax_id) = tax_id
             WHERE cohisttax.taxhist_id IS NOT NULL OR invcheadtax.taxhist_id IS NOT NULL
           ) lines ON invchead_id = headid
      WHERE invchead_posted;

    INSERT INTO taxhead (taxhead_status, taxhead_doc_type, taxhead_doc_id, taxhead_cust_id,
                         taxhead_date,
                         taxhead_curr_id,
                         taxhead_curr_rate,
                         taxhead_taxzone_id,
                         taxhead_distdate,
                         taxhead_journalnumber)
    SELECT DISTINCT ON (vohead_id)
           CASE WHEN apopen_void THEN 'V' ELSE 'P' END, 'VCH', vohead_id, vohead_vend_id,
           COALESCE(voheadtax.taxhist_docdate, voitemtax.taxhist_docdate, vohead_docdate),
           COALESCE(voheadtax.taxhist_curr_id, voitemtax.taxhist_curr_id, vohead_curr_id),
           COALESCE(voheadtax.taxhist_curr_rate, voitemtax.taxhist_curr_rate,
                    currRate(vohead_curr_id, vohead_docdate)),
           vohead_taxzone_id,
           COALESCE(voheadtax.taxhist_distdate, voitemtax.taxhist_distdate, apopen_distdate),
           COALESCE(voheadtax.taxhist_journalnumber, voitemtax.taxhist_journalnumber,
                    apopen_journalnumber)
      FROM vohead
      LEFT OUTER JOIN voheadtax ON vohead_id = voheadtax.taxhist_parent_id
      LEFT OUTER JOIN voitem ON vohead_id = voitem_vohead_id
      LEFT OUTER JOIN voitemtax ON voitem_id = voitemtax.taxhist_parent_id
      LEFT OUTER JOIN apopen ON apopen_doctype = 'V'
                            AND vohead_number = apopen_docnumber
     WHERE vohead_posted;

    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_line_id,
                         taxline_linenumber, taxline_subnumber, taxline_number, taxline_item_number,
                         taxline_taxtype_id, taxline_qty, taxline_amount, taxline_extended)
    SELECT DISTINCT ON (vohead_id, type, voitem_id)
           taxhead_id, type, voitem_id,
           poitem_linenumber, 0, number, item_number,
           COALESCE(voheadtax.taxhist_taxtype_id, voitemtax.taxhist_taxtype_id, voitem_taxtype_id),
           qty, amt,
           CASE WHEN type != 'A'
                THEN COALESCE(voheadtax.taxhist_basis, voitemtax.taxhist_basis, ext)
            END
      FROM vohead
      JOIN taxhead ON taxhead_doc_type = 'VCH'
                  AND vohead_id = taxhead_doc_id
      JOIN (
            SELECT voitem_vohead_id AS headid, 'L' AS type, voitem_id,
                   poitem_linenumber,
                   formatPoLineNumber(poitem_id) AS number,
                   COALESCE(item_number, expcat_code) AS item_number,
                   voitem_taxtype_id,
                   voitem_qty AS qty,
                   poitem_unitprice AS amt,
                   ROUND(voitem_qty * poitem_unitprice, 2) AS ext
              FROM voitem
              JOIN poitem ON voitem_poitem_id = poitem_id
              LEFT OUTER JOIN itemsite ON poitem_itemsite_id = itemsite_id
              LEFT OUTER JOIN item ON itemsite_item_id = item_id
              LEFT OUTER JOIN expcat ON poitem_expcat_id = expcat_id
            UNION
            SELECT vohead_id, 'F', NULL,
                   1,
                   NULL,
                   '',
                   getFreightTaxtypeId(),
                   NULL,
                   NULL,
                   vohead_freight
              FROM vohead
             WHERE vohead_freight != 0.0
            UNION
            SELECT vohead_id, 'A', NULL,
                   1,
                   NULL,
                   '',
                   getAdjustmentTaxtypeId(),
                   NULL,
                   NULL,
                   NULL
              FROM vohead
              LEFT OUTER JOIN voheadtax ON vohead_id = taxhist_parent_id
                                       AND taxhist_taxtype_id = getAdjustmentTaxtypeId()
             WHERE taxhist_id IS NOT NULL
           ) lines ON vohead_id = headid
      LEFT OUTER JOIN voheadtax ON vohead_id = voheadtax.taxhist_parent_id
                                 AND ((type = 'F'
                                       AND voheadtax.taxhist_taxtype_id =
                                           getFreightTaxtypeId())
                                      OR (type = 'A'
                                          AND voheadtax.taxhist_taxtype_id =
                                              getAdjustmentTaxtypeId()))
      LEFT OUTER JOIN voitemtax ON voitem_id = voitemtax.taxhist_parent_id
                               AND type = 'L'
     WHERE vohead_posted;

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                           taxdetail_taxclass_id, taxdetail_sequence, taxdetail_basis_tax_id, 
                           taxdetail_amount, taxdetail_percent, taxdetail_tax, taxdetail_paydate,
                           taxdetail_tax_paid)
    SELECT taxline_id, taxhist_basis, tax_id,
           tax_taxclass_id, taxhist_sequence, taxhist_basis_tax_id, 
           taxhist_amount, taxhist_percent, taxhist_tax, taxpay_distdate,
           taxpay_tax
      FROM vohead
      JOIN (
            SELECT voitem_vohead_id AS headid, taxline_id, taxhist_basis, tax_id, tax_taxclass_id,
                   taxhist_sequence, taxhist_basis_tax_id, taxhist_amount, taxhist_percent,
                   taxhist_tax, taxpay_distdate, taxpay_tax
              FROM voitem
              JOIN vohead ON voitem_vohead_id = vohead_id
              JOIN taxhead ON taxhead_doc_type = 'VCH'
                          AND vohead_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND voitem_id = taxline_line_id
              JOIN voitemtax ON voitem_id = taxhist_parent_id
              LEFT OUTER JOIN taxpay ON taxhist_id = taxpay_taxhist_id
              JOIN tax ON taxhist_tax_id = tax_id
            UNION
            SELECT vohead_id, taxline_id, taxhist_basis, tax_id, tax_taxclass_id,
                   taxhist_sequence, taxhist_basis_tax_id, taxhist_amount, taxhist_percent,
                   taxhist_tax, taxpay_distdate, taxpay_tax
              FROM vohead
              JOIN taxhead ON taxhead_doc_type = 'VCH'
                          AND vohead_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND taxline_line_type = 'F'
              JOIN voheadtax ON vohead_id = taxhist_parent_id
                            AND taxhist_taxtype_id = getFreightTaxtypeId()
              LEFT OUTER JOIN taxpay ON taxhist_id = taxpay_taxhist_id
              JOIN tax ON taxhist_tax_id = tax_id
            UNION
            SELECT vohead_id, taxline_id, taxhist_basis, tax_id, tax_taxclass_id,
                   taxhist_sequence, taxhist_basis_tax_id, taxhist_amount, taxhist_percent,
                   taxhist_tax, taxpay_distdate, taxpay_tax
              FROM vohead
              JOIN taxhead ON taxhead_doc_type = 'VCH'
                          AND vohead_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND taxline_line_type = 'A'
              JOIN voheadtax ON vohead_id = taxhist_parent_id
                            AND voheadtax.taxhist_taxtype_id = getAdjustmentTaxtypeId()
              LEFT OUTER JOIN taxpay ON taxhist_id = taxpay_taxhist_id
              JOIN tax ON taxhist_tax_id = tax_id
           ) lines ON vohead_id = headid
      WHERE vohead_posted;

    INSERT INTO taxhead (taxhead_status, taxhead_doc_type, taxhead_doc_id,
                         taxhead_cust_id,
                         taxhead_date,
                         taxhead_orig_doc_type, taxhead_orig_doc_id, taxhead_orig_date,
                         taxhead_curr_id,
                         taxhead_curr_rate,
                         taxhead_taxzone_id,
                         taxhead_distdate,
                         taxhead_journalnumber)
    SELECT DISTINCT ON (cmhead_id)
           CASE WHEN cmhead_void THEN 'V' ELSE 'P' END, 'CM', cmhead_id,
           COALESCE(cohist_cust_id, cmhead_cust_id),
           COALESCE(cohisttax.taxhist_docdate, cmheadtax.taxhist_docdate,
                    cmitemtax.taxhist_docdate, cohist_orderdate, cmhead_docdate),
           CASE WHEN invchead_id IS NOT NULL THEN 'INV' END, invchead_id, invchead_invcdate,
           COALESCE(cohisttax.taxhist_curr_id, cmheadtax.taxhist_curr_id,
                    cmitemtax.taxhist_curr_id, cohist_curr_id, cmhead_curr_id),
           COALESCE(cohisttax.taxhist_curr_rate, cmheadtax.taxhist_curr_rate,
                    cmitemtax.taxhist_curr_rate,
                    currRate(cohist_curr_id, cohist_orderdate),
                    currRate(cmhead_curr_id, cmhead_docdate)),
           COALESCE(cohist_taxzone_id, cmhead_taxzone_id),
           COALESCE(cohisttax.taxhist_distdate, aropen_distdate),
           COALESCE(cohisttax.taxhist_journalnumber, aropen_journalnumber)
      FROM cmhead
      LEFT OUTER JOIN invchead ON cmhead_invcnumber = invchead_invcnumber
      LEFT OUTER JOIN cohist ON cohist_doctype = 'C'
                            AND cmhead_number = cohist_ordernumber
      LEFT OUTER JOIN cohisttax ON cohist_id = cohisttax.taxhist_parent_id
      LEFT OUTER JOIN cmheadtax ON cmhead_id = cmheadtax.taxhist_parent_id
      LEFT OUTER JOIN cmitem ON cmhead_void
                            AND cmhead_id = cmitem_cmhead_id
      LEFT OUTER JOIN cmitemtax ON cmhead_void
                               AND cmitem_id = cmitemtax.taxhist_parent_id
      LEFT OUTER JOIN aropen ON aropen_doctype = 'C'
                            AND cmhead_number = aropen_docnumber
     WHERE cmhead_posted;

    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_line_id,
                         taxline_linenumber, taxline_subnumber, taxline_number, taxline_item_number,
                         taxline_taxtype_id, taxline_qty, taxline_amount, taxline_extended)
    SELECT DISTINCT ON (cmhead_id, type, cmitem_id)
           taxhead_id, type, cmitem_id,
           cmitem_linenumber, 0, number, item_number,
           COALESCE(cohisttax.taxhist_taxtype_id,
                    cmheadtax.taxhist_taxtype_id, cmitemtax.taxhist_taxtype_id, taxtype_id),
           qty, amt,
           CASE WHEN type != 'A' 
                THEN COALESCE(cohisttax.taxhist_basis,
                              cmheadtax.taxhist_basis, cmitemtax.taxhist_basis, ext)
            END
      FROM cmhead
      JOIN taxhead ON taxhead_doc_type = 'CM'
                  AND cmhead_id = taxhead_doc_id
      JOIN (
            SELECT cmitem_cmhead_id AS headid, cohist_id, 'L' AS type, cmitem_id,
                   cmitem_linenumber,
                   cmitem_linenumber::TEXT AS number,
                   COALESCE(item_number, cmitem_number) AS item_number,
                   COALESCE(cohist_taxtype_id, cmitem_taxtype_id) AS taxtype_id,
                   COALESCE(cohist_qtyshipped * -1,
                            cmitem_qtycredit * cmitem_qty_invuomratio) AS qty,
                   COALESCE(cohist_unitprice, cmitem_unitprice / cmitem_price_invuomratio) AS amt,
                   ROUND(COALESCE(cohist_qtyshipped * -1,
                                  cmitem_qtycredit / cmitem_qty_invuomratio) *
                         COALESCE(cohist_unitprice, cmitem_unitprice / cmitem_price_invuomratio), 2)
                   AS ext
              FROM cmitem
              LEFT OUTER JOIN itemsite ON cmitem_itemsite_id = itemsite_id
              LEFT OUTER JOIN item ON itemsite_item_id = item_id
              JOIN cmhead ON cmitem_cmhead_id = cmhead_id
              LEFT OUTER JOIN cohist ON cohist_doctype = 'C'
                                    AND cmhead_number = cohist_ordernumber
                                    AND (cmitem_itemsite_id = cohist_itemsite_id
                                         OR cmitem_number || '-' || cmitem_descrip =
                                            cohist_misc_descrip)
                                    AND (SELECT COUNT(*) = 1
                                           FROM cohist b
                                          WHERE b.cohist_doctype = 'C'
                                            AND b.cohist_ordernumber = cmhead_number
                                            AND (b.cohist_itemsite_id = cmitem_itemsite_id
                                                 OR b.cohist_misc_descrip =
                                                    cmitem_number || '-' || cmitem_descrip))
            UNION
            SELECT cmhead_id, cohist_id, 'F', NULL,
                   1,
                   NULL,
                   '',
                   getFreightTaxtypeId(),
                   NULL,
                   NULL,
                   COALESCE(cohist_unitprice * -1, cmhead_freight)
              FROM cmhead
              LEFT OUTER JOIN cohist ON cohist_doctype = 'C'
                                    AND cmhead_number = cohist_ordernumber
                                    AND cohist_misc_type = 'F'
             WHERE COALESCE(cohist_unitprice, cmhead_freight) != 0.0
            UNION
            SELECT cmhead_id, cohist_id, 'M', NULL,
                   1,
                   NULL,
                   '',
                   getMiscTaxtypeId(),
                   NULL,
                   NULL,
                   COALESCE(cohist_unitprice * -1, cmhead_misc)
              FROM cmhead
              LEFT OUTER JOIN cohist ON cohist_doctype = 'C'
                                    AND cmhead_number = cohist_ordernumber
                                    AND cohist_misc_type = 'M'
                                    AND cohist_misc_descrip = cmhead_misc_descrip
             WHERE COALESCE(cohist_unitprice, cmhead_misc) != 0.0
            UNION
            SELECT cmhead_id, cohist_id, 'A', NULL,
                   1,
                   NULL,
                   '',
                   getAdjustmentTaxtypeId(),
                   NULL,
                   NULL,
                   NULL
              FROM cmhead
              LEFT OUTER JOIN cohist ON cohist_doctype = 'C'
                                    AND cmhead_number = cohist_ordernumber
                                    AND cohist_misc_type = 'T'
              LEFT OUTER JOIN cohisttax ON cohist_id = cohisttax.taxhist_parent_id
              LEFT OUTER JOIN cmheadtax ON cmhead_void
                                       AND cmhead_id = cmheadtax.taxhist_parent_id
                                       AND cmheadtax.taxhist_taxtype_id = getAdjustmentTaxtypeId()
             WHERE cohisttax.taxhist_id IS NOT NULL OR cmheadtax.taxhist_id IS NOT NULL
             GROUP BY cmhead_id, cohist_id
           ) lines ON cmhead_id = headid
      LEFT OUTER JOIN cohisttax ON cohist_id = cohisttax.taxhist_parent_id
      LEFT OUTER JOIN cmheadtax ON cmhead_void
                               AND cmhead_id = cmheadtax.taxhist_parent_id
                               AND ((type = 'F'
                                     AND cmheadtax.taxhist_taxtype_id =
                                         getFreightTaxtypeId())
                                    OR (type = 'A'
                                        AND cmheadtax.taxhist_taxtype_id =
                                            getAdjustmentTaxtypeId()))
      LEFT OUTER JOIN cmitemtax ON cmhead_void
                                 AND cmitem_id = cmitemtax.taxhist_parent_id
                                 AND type = 'L'
     WHERE cmhead_posted;

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                           taxdetail_taxclass_id, taxdetail_sequence, taxdetail_basis_tax_id, 
                           taxdetail_amount, taxdetail_percent, taxdetail_tax, taxdetail_paydate,
                           taxdetail_tax_paid)
    SELECT taxline_id, taxable, tax_id,
           tax_taxclass_id, sequence, basis, 
           amount, percent, tax, taxpay_distdate,
           taxpay_tax
      FROM cmhead
      JOIN (
            SELECT cmitem_cmhead_id AS headid, taxline_id,
                   COALESCE(cohisttax.taxhist_basis, cmitemtax.taxhist_basis) AS taxable,
                   tax_id, tax_taxclass_id,
                   COALESCE(cohisttax.taxhist_sequence, cmitemtax.taxhist_sequence) AS sequence,
                   COALESCE(cohisttax.taxhist_basis_tax_id,
                            cmitemtax.taxhist_basis_tax_id) AS basis,
                   COALESCE(cohisttax.taxhist_amount, cmitemtax.taxhist_amount) AS amount,
                   COALESCE(cohisttax.taxhist_percent, cmitemtax.taxhist_percent) AS percent,
                   COALESCE(cohisttax.taxhist_tax, cmitemtax.taxhist_tax) AS tax,
                   taxpay_distdate, taxpay_tax
              FROM cmitem
              JOIN cmhead ON cmitem_cmhead_id = cmhead_id
              JOIN taxhead ON taxhead_doc_type = 'CM'
                          AND cmhead_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND cmitem_id = taxline_line_id
              LEFT OUTER JOIN cohist ON cohist_doctype = 'C'
                                    AND cmhead_number = cohist_ordernumber
                                    AND (cmitem_itemsite_id = cohist_itemsite_id
                                         OR cmitem_number || '-' || cmitem_descrip =
                                            cohist_misc_descrip)
                                    AND (SELECT COUNT(*) = 1
                                           FROM cohist b
                                          WHERE b.cohist_doctype = 'C'
                                            AND b.cohist_ordernumber = cmhead_number
                                            AND (b.cohist_itemsite_id = cmitem_itemsite_id
                                                 OR b.cohist_misc_descrip =
                                                    cmitem_number || '-' || cmitem_descrip))
              LEFT OUTER JOIN cohisttax ON cohist_id = cohisttax.taxhist_parent_id
              LEFT OUTER JOIN taxpay ON cohisttax.taxhist_id = taxpay_taxhist_id
              LEFT OUTER JOIN cmitemtax ON cmhead_void
                                       AND cmitem_id = cmitemtax.taxhist_parent_id
              LEFT OUTER JOIN tax ON COALESCE(cohisttax.taxhist_tax_id,
                                              cmitemtax.taxhist_tax_id) = tax_id
             WHERE cohisttax.taxhist_id IS NOT NULL OR cmitemtax.taxhist_id IS NOT NULL
            UNION
            SELECT cmhead_id, taxline_id,
                   COALESCE(cohisttax.taxhist_basis, cmheadtax.taxhist_basis),
                   tax_id, tax_taxclass_id,
                   COALESCE(cohisttax.taxhist_sequence, cmheadtax.taxhist_sequence),
                   COALESCE(cohisttax.taxhist_basis_tax_id, 
                            cmheadtax.taxhist_basis_tax_id),
                   COALESCE(cohisttax.taxhist_amount, cmheadtax.taxhist_amount),
                   COALESCE(cohisttax.taxhist_percent, cmheadtax.taxhist_percent),
                   COALESCE(cohisttax.taxhist_tax, cmheadtax.taxhist_tax),
                   taxpay_distdate, taxpay_tax
              FROM cmhead
              JOIN taxhead ON taxhead_doc_type = 'CM'
                          AND cmhead_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND taxline_line_type = 'F'
              LEFT OUTER JOIN cohist ON cohist_doctype = 'C'
                                    AND cmhead_number = cohist_ordernumber
                                    AND cohist_misc_type = 'F'
              LEFT OUTER JOIN cohisttax ON cohist_id = cohisttax.taxhist_parent_id
              LEFT OUTER JOIN taxpay ON cohisttax.taxhist_id = taxpay_taxhist_id
              LEFT OUTER JOIN cmheadtax ON cmhead_void
                                       AND cmhead_id = cmheadtax.taxhist_parent_id
                                       AND cmheadtax.taxhist_taxtype_id = getFreightTaxtypeId()
              LEFT OUTER JOIN tax ON COALESCE(cohisttax.taxhist_tax_id,
                                              cmheadtax.taxhist_tax_id) = tax_id
             WHERE cohisttax.taxhist_id IS NOT NULL OR cmheadtax.taxhist_id IS NOT NULL
            UNION
            SELECT cmhead_id, taxline_id,
                   COALESCE(cohisttax.taxhist_basis, cmheadtax.taxhist_basis),
                   tax_id, tax_taxclass_id,
                   COALESCE(cohisttax.taxhist_sequence, cmheadtax.taxhist_sequence),
                   COALESCE(cohisttax.taxhist_basis_tax_id, 
                            cmheadtax.taxhist_basis_tax_id),
                   COALESCE(cohisttax.taxhist_amount, cmheadtax.taxhist_amount),
                   COALESCE(cohisttax.taxhist_percent, cmheadtax.taxhist_percent),
                   COALESCE(cohisttax.taxhist_tax, cmheadtax.taxhist_tax),
                   taxpay_distdate, taxpay_tax
              FROM cmhead
              JOIN taxhead ON taxhead_doc_type = 'CM'
                          AND cmhead_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND taxline_line_type = 'A'
              LEFT OUTER JOIN cohist ON cohist_doctype = 'C'
                                    AND cmhead_number = cohist_ordernumber
                                    AND cohist_misc_type = 'T'
              LEFT OUTER JOIN cohisttax ON cohist_id = cohisttax.taxhist_parent_id
              LEFT OUTER JOIN taxpay ON cohisttax.taxhist_id = taxpay_taxhist_id
              LEFT OUTER JOIN cmheadtax ON cmhead_void
                                       AND cmhead_id = cmheadtax.taxhist_parent_id
                                       AND cmheadtax.taxhist_taxtype_id = getAdjustmentTaxtypeId()
              LEFT OUTER JOIN tax ON COALESCE(cohisttax.taxhist_tax_id,
                                              cmheadtax.taxhist_tax_id) = tax_id
             WHERE cohisttax.taxhist_id IS NOT NULL OR cmheadtax.taxhist_id IS NOT NULL
           ) lines ON cmhead_id = headid
      WHERE cmhead_posted;

    INSERT INTO taxhead (taxhead_status, taxhead_doc_type, taxhead_doc_id, taxhead_cust_id,
                         taxhead_date,
                         taxhead_curr_id,
                         taxhead_curr_rate,
                         taxhead_taxzone_id,
                         taxhead_distdate,
                         taxhead_journalnumber)
    SELECT DISTINCT ON (aropen_id)
           'P', 'AR', aropen_id, cohist_cust_id,
           COALESCE(taxhist_docdate, cohist_invcdate),
           COALESCE(taxhist_curr_id, cohist_curr_id),
           COALESCE(taxhist_curr_rate, aropen_curr_rate),
           aropen_taxzone_id,
           COALESCE(taxhist_distdate, aropen_distdate),
           COALESCE(taxhist_journalnumber, aropen_journalnumber)
      FROM aropen
      JOIN cohist ON cohist_doctype IN ('C', 'D')
                 AND cohist_misc_type = 'M'
                 AND cohist_misc_descrip ~ 'A/R Misc'
                 AND aropen_docnumber = cohist_invcnumber
      LEFT OUTER JOIN cohisttax ON cohist_id = taxhist_parent_id
     WHERE aropen_posted;

    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_line_id,
                         taxline_taxtype_id, taxline_qty, taxline_amount, taxline_extended)
    SELECT DISTINCT ON (aropen_id, type)
           taxhead_id, type, line_id,
           COALESCE(taxhist_taxtype_id, getAdjustmentTaxtypeId()),
           qty, amt,
           CASE WHEN type != 'A'
                THEN COALESCE(taxhist_basis, ext)
            END
      FROM aropen
      JOIN taxhead ON taxhead_doc_type = 'AR'
                  AND aropen_id = taxhead_doc_id
      JOIN (
            SELECT aropen_id AS headid, 'L' AS type, aropen_id AS line_id,
                   1.0 AS qty,
                   aropen_amount AS amt,
                   aropen_amount AS ext
              FROM aropen
            UNION
            SELECT aropen_id, 'A', NULL,
                   NULL,
                   NULL,
                   NULL
              FROM aropen
              JOIN cohist ON cohist_doctype IN ('C', 'D')
                         AND cohist_misc_type = 'M'
                         AND cohist_misc_descrip ~ 'A/R Misc'
                         AND aropen_docnumber = cohist_invcnumber
              JOIN cohisttax ON cohist_id = taxhist_parent_id
             WHERE taxhist_amount = 0.0 AND taxhist_percent = 0.0
             GROUP BY aropen_id
           ) lines ON aropen_id = headid
      JOIN cohist ON cohist_doctype IN ('C', 'D')
                 AND cohist_misc_type = 'M'
                 AND cohist_misc_descrip ~ 'A/R Misc'
                 AND aropen_docnumber = cohist_invcnumber
      LEFT OUTER JOIN cohisttax ON aropen_id = taxhist_parent_id
                               AND ((type = 'L'
                                     AND (taxhist_amount != 0.0
                                          OR taxhist_percent != 0.0))
                                    OR (type = 'A'
                                        AND taxhist_amount = 0.0
                                        AND taxhist_percent = 0.0))
     WHERE aropen_posted;

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                           taxdetail_taxclass_id, taxdetail_sequence, taxdetail_basis_tax_id, 
                           taxdetail_amount, taxdetail_percent, taxdetail_tax, taxdetail_paydate,
                           taxdetail_tax_paid)
    SELECT taxline_id, taxhist_basis, tax_id,
           tax_taxclass_id, taxhist_sequence, taxhist_basis_tax_id, 
           taxhist_amount, taxhist_percent, taxhist_tax, taxpay_distdate,
           taxpay_tax
      FROM aropen
      JOIN (
            SELECT aropen_id AS headid, taxline_id, taxhist_basis, tax_id, tax_taxclass_id,
                   taxhist_sequence, taxhist_basis_tax_id, taxhist_amount, taxhist_percent,
                   taxhist_tax, taxpay_distdate, taxpay_tax
              FROM aropen
              JOIN taxhead ON taxhead_doc_type = 'AR'
                          AND aropen_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND taxline_line_type = 'L'
              JOIN cohist ON cohist_doctype IN ('C', 'D')
                         AND cohist_misc_type = 'M'
                         AND cohist_misc_descrip ~ 'A/R Misc'
                         AND aropen_docnumber = cohist_invcnumber
              JOIN cohisttax ON cohist_id = taxhist_parent_id
              LEFT OUTER JOIN taxpay ON taxhist_id = taxpay_taxhist_id
              JOIN tax ON taxhist_tax_id = tax_id
             WHERE (taxhist_amount != 0.0 OR taxhist_percent != 0.0)
            UNION
            SELECT aropen_id, taxline_id, taxhist_basis, tax_id, tax_taxclass_id,
                   taxhist_sequence, taxhist_basis_tax_id, taxhist_amount, taxhist_percent,
                   taxhist_tax, taxpay_distdate, taxpay_tax
              FROM aropen
              JOIN taxhead ON taxhead_doc_type = 'AR'
                          AND aropen_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND taxline_line_type = 'L'
              JOIN cohist ON cohist_doctype IN ('C', 'D')
                         AND cohist_misc_type = 'M'
                         AND cohist_misc_descrip ~ 'A/R Misc'
                         AND aropen_docnumber = cohist_invcnumber
              JOIN cohisttax ON cohist_id = taxhist_parent_id
              LEFT OUTER JOIN taxpay ON taxhist_id = taxpay_taxhist_id
              JOIN tax ON taxhist_tax_id = tax_id
             WHERE taxhist_amount = 0.0 AND taxhist_percent = 0.0
           ) lines ON aropen_id = headid
      WHERE aropen_posted;

    INSERT INTO taxhead (taxhead_status, taxhead_doc_type, taxhead_doc_id, taxhead_cust_id,
                         taxhead_date,
                         taxhead_curr_id,
                         taxhead_curr_rate,
                         taxhead_taxzone_id,
                         taxhead_distdate,
                         taxhead_journalnumber)
    SELECT DISTINCT ON (apopen_id)
           'P', 'AP', apopen_id, apopen_vend_id,
           COALESCE(taxhist_docdate, apopen_docdate),
           COALESCE(taxhist_curr_id, apopen_curr_id),
           COALESCE(taxhist_curr_rate, apopen_curr_rate),
           apopen_taxzone_id,
           COALESCE(taxhist_distdate, apopen_distdate),
           COALESCE(taxhist_journalnumber, apopen_journalnumber)
      FROM apopen
      LEFT OUTER JOIN apopentax ON apopen_id = taxhist_parent_id
     WHERE apopen_posted
       AND apopen_doctype IN ('C', 'D');

    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_line_id,
                         taxline_taxtype_id, taxline_qty, taxline_amount, taxline_extended)
    SELECT DISTINCT ON (apopen_id, type)
           taxhead_id, type, line_id,
           COALESCE(taxhist_taxtype_id, getAdjustmentTaxtypeId()),
           qty, amt,
           CASE WHEN type != 'A'
                THEN COALESCE(taxhist_basis, ext)
            END
      FROM apopen
      JOIN taxhead ON taxhead_doc_type = 'AP'
                  AND apopen_id = taxhead_doc_id
      JOIN (
            SELECT apopen_id AS headid, 'L' AS type, apopen_id AS line_id,
                   1.0 AS qty,
                   apopen_amount AS amt,
                   apopen_amount AS ext
              FROM apopen
            UNION
            SELECT apopen_id, 'A', NULL,
                   NULL,
                   NULL,
                   NULL
              FROM apopen
              JOIN apopentax ON apopen_id = taxhist_parent_id
             WHERE taxhist_amount = 0.0 AND taxhist_percent = 0.0
             GROUP BY apopen_id
           ) lines ON apopen_id = headid
      LEFT OUTER JOIN apopentax ON apopen_id = taxhist_parent_id
                               AND ((type = 'L'
                                     AND (taxhist_amount != 0.0
                                          OR taxhist_percent != 0.0))
                                    OR (type = 'A'
                                        AND taxhist_amount = 0.0
                                        AND taxhist_percent = 0.0))
     WHERE apopen_posted
       AND apopen_doctype IN ('C', 'D');

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                           taxdetail_taxclass_id, taxdetail_sequence, taxdetail_basis_tax_id, 
                           taxdetail_amount, taxdetail_percent, taxdetail_tax)
    SELECT taxline_id, taxhist_basis, tax_id,
           tax_taxclass_id, taxhist_sequence, taxhist_basis_tax_id, 
           taxhist_amount, taxhist_percent, taxhist_tax
      FROM apopen
      JOIN (
            SELECT apopen_id AS headid, taxline_id, taxhist_basis, tax_id, tax_taxclass_id,
                   taxhist_sequence, taxhist_basis_tax_id, taxhist_amount, taxhist_percent,
                   taxhist_tax
              FROM apopen
              JOIN taxhead ON taxhead_doc_type = 'AP'
                          AND apopen_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND taxline_line_type = 'L'
              JOIN apopentax ON apopen_id = taxhist_parent_id
              JOIN tax ON taxhist_tax_id = tax_id
             WHERE (taxhist_amount != 0.0 OR taxhist_percent != 0.0)
            UNION
            SELECT apopen_id, taxline_id, taxhist_basis, tax_id, tax_taxclass_id,
                   taxhist_sequence, taxhist_basis_tax_id, taxhist_amount, taxhist_percent,
                   taxhist_tax
              FROM apopen
              JOIN taxhead ON taxhead_doc_type = 'AP'
                          AND apopen_id = taxhead_doc_id
              JOIN taxline ON taxhead_id = taxline_taxhead_id
                          AND taxline_line_type = 'L'
              JOIN apopentax ON apopen_id = taxhist_parent_id
              JOIN tax ON taxhist_tax_id = tax_id
             WHERE taxhist_amount = 0.0 AND taxhist_percent = 0.0
           ) lines ON apopen_id = headid
      WHERE apopen_posted
       AND apopen_doctype IN ('C', 'D');

    INSERT INTO taxhead (taxhead_status, taxhead_doc_type, taxhead_doc_id, taxhead_cust_id,
                         taxhead_date,
                         taxhead_curr_id,
                         taxhead_curr_rate,
                         taxhead_taxzone_id,
                         taxhead_distdate,
                         taxhead_journalnumber)
    SELECT DISTINCT ON (checkhead_id)
           CASE WHEN checkhead_void THEN 'V' ELSE 'P' END, 'CK', checkhead_id, checkhead_recip_id,
           COALESCE(taxhist_docdate, checkhead_checkdate),
           COALESCE(taxhist_curr_id, checkhead_curr_id),
           COALESCE(taxhist_curr_rate, checkhead_curr_rate),
           checkhead_taxzone_id,
           NULL,
           NULL
      FROM checkhead
      LEFT OUTER JOIN checkheadtax ON checkhead_id = taxhist_parent_id
     WHERE checkhead_posted;

    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_line_id,
                         taxline_taxtype_id, taxline_qty, taxline_amount, taxline_extended)
    SELECT DISTINCT ON (checkhead_id)
           taxhead_id, 'L', checkhead_id,
           COALESCE(taxhist_taxtype_id, checkhead_taxtype_id),
           1.0, checkhead_amount,
           COALESCE(taxhist_basis, checkhead_amount)
      FROM checkhead
      JOIN taxhead ON taxhead_doc_type = 'CK'
                  AND checkhead_id = taxhead_doc_id
      LEFT OUTER JOIN checkheadtax ON checkhead_id = taxhist_parent_id
     WHERE checkhead_posted;

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                           taxdetail_taxclass_id, taxdetail_sequence, taxdetail_basis_tax_id, 
                           taxdetail_amount, taxdetail_percent, taxdetail_tax, taxdetail_paydate,
                           taxdetail_tax_paid)
    SELECT taxline_id, taxhist_basis, tax_id,
           tax_taxclass_id, taxhist_sequence, taxhist_basis_tax_id, 
           taxhist_amount, taxhist_percent, taxhist_tax, taxpay_distdate,
           taxpay_tax
      FROM checkhead
      JOIN taxhead ON taxhead_doc_type = 'CK'
                  AND checkhead_id = taxhead_doc_id
      JOIN taxline ON taxhead_id = taxline_taxhead_id
      JOIN checkheadtax ON checkhead_id = taxhist_parent_id
      LEFT OUTER JOIN taxpay ON taxhist_id = taxpay_taxhist_id
      JOIN tax ON taxhist_tax_id = tax_id
     WHERE checkhead_posted;

    PERFORM archiveSalesHistory(asohist_id)
       FROM asohisttmp;

    DROP TABLE taxpay CASCADE;
    DROP TABLE taxhist CASCADE;
  END IF;

END
$$ language plpgsql;
