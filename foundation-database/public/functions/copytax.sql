CREATE OR REPLACE FUNCTION copyTax(pSourceType   TEXT,
                                   pSourceId     INTEGER,
                                   pTargetType   TEXT,
                                   pTargetId     INTEGER,
                                   pTargetHeadId INTEGER DEFAULT NULL) RETURNS BOOLEAN AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _r         RECORD;
  _taxlineid INTEGER;

BEGIN

  IF pTargetHeadId IS NULL THEN
    INSERT INTO taxhead (taxhead_service, taxhead_status, taxhead_valid, taxhead_doc_type,
                         taxhead_doc_id, taxhead_cust_id, taxhead_exemption_code, taxhead_date,
                         taxhead_orig_doc_type, taxhead_orig_doc_id, taxhead_orig_date,
                         taxhead_curr_id, taxhead_curr_rate, taxhead_taxzone_id,
                         taxhead_shiptoaddr_line1, taxhead_shiptoaddr_line2,
                         taxhead_shiptoaddr_line3, taxhead_shiptoaddr_city,
                         taxhead_shiptoaddr_region, taxhead_shiptoaddr_postalcode,
                         taxhead_shiptoaddr_country, taxhead_discount, taxhead_tax_paid,
                         taxhead_distdate, taxhead_journalnumber)
    SELECT taxhead_service, taxhead_status, taxhead_valid, pTargetType,
           pTargetId, taxhead_cust_id, taxhead_exemption_code, taxhead_date,
           taxhead_orig_doc_type, taxhead_orig_doc_id, taxhead_orig_date,
           taxhead_curr_id, taxhead_curr_rate, taxhead_taxzone_id,
           taxhead_shiptoaddr_line1, taxhead_shiptoaddr_line2,
           taxhead_shiptoaddr_line3, taxhead_shiptoaddr_city,
           taxhead_shiptoaddr_region, taxhead_shiptoaddr_postalcode,
           taxhead_shiptoaddr_country, taxhead_discount, taxhead_tax_paid,
           taxhead_distdate, taxhead_journalnumber
      FROM taxhead
     WHERE taxhead_doc_type = pSourceType
       AND taxhead_doc_id = pSourceId;
  END IF;

  FOR _r IN SELECT taxline_id
              FROM taxhead
              JOIN taxline ON taxhead_id = taxline_taxhead_id
             WHERE taxhead_doc_type = pSourceType
               AND CASE WHEN pTargetHeadId IS NULL
                        THEN taxhead_doc_id = pSourceId AND taxline_line_type != 'L'
                        ELSE taxline_line_id = pSourceId
                    END
  LOOP
    INSERT INTO taxline (taxline_taxhead_id, taxline_line_type, taxline_line_id,
                         taxline_linenumber, taxline_subnumber, taxline_number,
                         taxline_item_number, taxline_shipfromaddr_line1,
                         taxline_shipfromaddr_line2, taxline_shipfromaddr_line3,
                         taxline_shipfromaddr_city, taxline_shipfromaddr_region,
                         taxline_shipfromaddr_postalcode, taxline_shipfromaddr_country,
                         taxline_taxtype_id, taxline_taxtype_external_code, taxline_qty,
                         taxline_amount, taxline_extended)
    SELECT taxhead_id, taxline_line_type, CASE WHEN pTargetHeadId IS NOT NULL
                                               THEN pTargetId
                                               ELSE taxline_line_id
                                           END,
           taxline_linenumber, taxline_subnumber, taxline_number,
           taxline_item_number, taxline_shipfromaddr_line1,
           taxline_shipfromaddr_line2, taxline_shipfromaddr_line3,
           taxline_shipfromaddr_city, taxline_shipfromaddr_region,
           taxline_shipfromaddr_postalcode, taxline_shipfromaddr_country,
           taxline_taxtype_id, taxline_taxtype_external_code, taxline_qty,
           taxline_amount, taxline_extended
      FROM taxhead, taxline
     WHERE taxhead_doc_type = pTargetType
       AND taxhead_doc_id = COALESCE(pTargetHeadId, pTargetId)
       AND taxline_id = _r.taxline_id
    RETURNING taxline_id INTO _taxlineid;

    INSERT INTO taxdetail (taxdetail_taxline_id, taxdetail_taxable, taxdetail_tax_id,
                           taxdetail_tax_code, taxdetail_taxclass_id, taxdetail_sequence,
                           taxdetail_basis_tax_id, taxdetail_amount, taxdetail_percent,
                           taxdetail_tax, taxdetail_tax_owed, taxdetail_paydate,
                           taxdetail_tax_paid)
    SELECT _taxlineid, taxdetail_taxable, taxdetail_tax_id,
           taxdetail_tax_code, taxdetail_taxclass_id, taxdetail_sequence,
           taxdetail_basis_tax_id, taxdetail_amount, taxdetail_percent,
           taxdetail_tax, taxdetail_tax_owed, taxdetail_paydate,
           taxdetail_tax_paid
      FROM taxhead, taxdetail
     WHERE taxhead_doc_type = pTargetType
       AND taxhead_doc_id = COALESCE(pTargetHeadId, pTargetId)
       AND taxdetail_taxline_id = _r.taxline_id;
  END LOOP;

  UPDATE taxhead
     SET taxhead_valid = src.taxhead_valid
    FROM taxline
    JOIN taxhead src ON taxline_taxhead_id = src.taxhead_id
   WHERE src.taxhead_doc_type = pSourceType
     AND taxline_line_id = pSourceId
     AND taxhead.taxhead_doc_type = pTargetType
     AND taxhead.taxhead_doc_id = pTargetHeadId;

  RETURN TRUE;

END
$$ language plpgsql;
