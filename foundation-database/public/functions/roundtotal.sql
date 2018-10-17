CREATE OR REPLACE FUNCTION roundTotal(pValues NUMERIC[], pTotal NUMERIC, pPrecision INTEGER) RETURNS NUMERIC[] IMMUTABLE AS $$
BEGIN

  -- Total must be rounded
  pTotal := ROUND(pTotal, pPrecision);

  -- Sanity check
  IF NOT pTotal BETWEEN (SELECT SUM(XTFLOOR(value, pPrecision))
                           FROM UNNEST(pValues) AS value)
                    AND (SELECT SUM(XTCEILING(value, pPrecision))
                           FROM UNNEST(pValues) AS value) THEN
    RAISE EXCEPTION 'Values cannot add up to total [xtuple: roundTotal, -1]';
  END IF;

  RETURN ARRAY(WITH values AS (SELECT value, ROW_NUMBER() OVER () AS index
                                 FROM UNNEST(pValues) AS value),
                    diff AS (SELECT (SUM(ROUND(value, pPrecision)) - pTotal) * 10^(pPrecision)
                                    AS diff
                               FROM values)
               SELECT CASE WHEN index IN (SELECT index
                                            FROM values
                                            CROSS JOIN diff
                                           WHERE (diff > 0 AND value < ROUND(value, pPrecision))
                                              OR (diff < 0 AND value > ROUND(value, pPrecision))
                                           ORDER BY ABS(value - ROUND(value, pPrecision)) DESC,
                                                    index
                                           LIMIT (SELECT ABS(diff) FROM diff))
                           THEN CASE WHEN diff > 0 THEN XTFLOOR(value, pPrecision)
                                     WHEN diff < 0 THEN XTCEILING(value, pPrecision)
                                     ELSE ROUND(value, pPrecision)
                                 END
                           ELSE ROUND(value, pPrecision)
                       END
                  FROM values
                  CROSS JOIN diff
                 ORDER BY index);

END
$$ LANGUAGE plpgsql;
