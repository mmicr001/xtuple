CREATE OR REPLACE FUNCTION distributeDiscount(pLines NUMERIC[],
                                              pDiscount NUMERIC,
                                              pPrecision INTEGER) RETURNS NUMERIC[] IMMUTABLE AS $$
BEGIN

  RETURN (WITH total AS
          (
           SELECT SUM(ROUND(line, pPrecision)) AS total
             FROM UNNEST(pLines) AS line
          )
          SELECT roundTotal(array_agg(line - pDiscount * line / total), total - pDiscount, 2)
            FROM total, UNNEST(pLines) AS line
            GROUP BY total);

END
$$ language plpgsql;
