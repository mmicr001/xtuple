DO $$
BEGIN

  IF compareVersion(fetchMetricText('ServerVersion'), '5.0.0-alpha') = -1 THEN
    PERFORM saveTax('Q', quhead_id, calculateOrderTax('Q', quhead_id))
       FROM quhead;

    PERFORM saveTax('S', cohead_id, calculateOrderTax('S', cohead_id))
       FROM cohead;

    PERFORM saveTax('COB', cobmisc_id, calculateOrderTax('COB', cobmisc_id))
       FROM cobmisc;

    PERFORM saveTax('INV', invchead_id, calculateOrderTax('INV', invchead_id))
       FROM invchead
      WHERE NOT invchead_posted;
  END IF;

END
$$ language plpgsql;
