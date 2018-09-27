UPDATE cohist
   SET cohist_invchead_id = COALESCE(cohist.cohist_invchead_id, invchead_id),
       cohist_invcitem_id = COALESCE(cohist.cohist_invcitem_id, invcitem_id),
       cohist_coitem_id = COALESCE(cohist.cohist_coitem_id, coitem_id)
  FROM cohist c
  JOIN invchead ON (c.cohist_doctype = 'I' OR
                    (c.cohist_doctype = 'C' AND (c.cohist_misc_type IS DISTINCT FROM 'M' OR
                                                 c.cohist_misc_descrip != 'A/R Misc Credit Memo' OR
                                                 c.cohist_misc_id IS NOT NULL)))
               AND c.cohist_invcnumber = invchead_invcnumber
  LEFT OUTER JOIN invcitem ON c.cohist_doctype = 'I'
                          AND invchead_id = invcitem_invchead_id
                          AND CASE WHEN (SELECT COUNT(*) = 1
                                           FROM invcitem
                                          WHERE invcitem_invchead_id = invchead_id
                                            AND ((c.cohist_misc_type IS NULL AND
                                                  c.cohist_itemsite_id =
                                                  (SELECT itemsite_id
                                                     FROM itemsite
                                                    WHERE itemsite_item_id = invcitem_item_id
                                                      AND itemsite_warehous_id =
                                                          invcitem_warehous_id
                                                  )) OR
                                                 (c.cohist_misc_type = 'M' AND
                                                  c.cohist_misc_id IS NULL AND
                                                  c.cohist_misc_descrip =
                                                  invcitem_number || '-' || invcitem_descrip)))
                                   THEN ((c.cohist_misc_type IS NULL AND
                                          c.cohist_itemsite_id =
                                          (SELECT itemsite_id
                                             FROM itemsite
                                            WHERE itemsite_item_id = invcitem_item_id
                                              AND itemsite_warehous_id = 
                                                  invcitem_warehous_id
                                          )) OR
                                         (c.cohist_misc_type = 'M' AND
                                          c.cohist_misc_id IS NULL AND
                                          c.cohist_misc_descrip = 
                                          invcitem_number || '-' || invcitem_descrip))
                                   ELSE invcitem_id =
                                        (SELECT invcitem_id
                                           FROM (
                                                 SELECT invcitem_id,
                                                        CASE WHEN c.cohist_qtyshipped = 
                                                                  invcitem_billed *
                                                                  invcitem_qty_invuomratio
                                                             THEN 4
                                                             ELSE 0
                                                         END +
                                                        CASE WHEN c.cohist_unitprice =
                                                                  invcitem_price /
                                                                  invcitem_price_invuomratio
                                                             THEN 2
                                                             ELSE 0
                                                         END +
                                                        CASE WHEN c.cohist_taxtype_id
                                                                  IS NOT DISTINCT FROM
                                                                  invcitem_taxtype_id
                                                             THEN 1
                                                             ELSE 0
                                                         END AS ord
                                                   FROM invcitem
                                                  WHERE invcitem_invchead_id = invchead_id
                                                    AND ((c.cohist_misc_type IS NULL AND
                                                          c.cohist_itemsite_id =
                                                          (SELECT itemsite_id
                                                             FROM itemsite
                                                            WHERE itemsite_item_id =
                                                                  invcitem_item_id
                                                              AND itemsite_warehous_id = 
                                                                  invcitem_warehous_id
                                                          )) OR
                                                         (c.cohist_misc_type = 'M' AND
                                                          c.cohist_misc_id IS NULL AND
                                                          c.cohist_misc_descrip = 
                                                          invcitem_number || '-' ||
                                                          invcitem_descrip))
                                                  ORDER BY ord DESC
                                                  LIMIT 1
                                                 ) match
                                        )
                               END
  LEFT OUTER JOIN coitem ON invcitem_coitem_id = coitem_id
 WHERE c.cohist_id = cohist.cohist_id;
