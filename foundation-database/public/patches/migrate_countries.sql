DO $$
DECLARE
  _columns TEXT[];
  _column TEXT;
  _table TEXT;
  _metricstr TEXT;
  _count INTEGER;

BEGIN

  UPDATE country
     SET country_abbr = 'GB'
   WHERE country_abbr = 'UK';

  _columns := ARRAY['addr_country',
                    'quhead_billtocountry', 'quhead_shiptocountry',
                    'cohead_billtocountry', 'cohead_shiptocountry',
                    'invchead_billto_country', 'invchead_shipto_country',
                    'cmhead_billtocountry', 'cmhead_shipto_country',
                    'pohead_vendcountry', 'pohead_shiptocountry',
                    'metric_value'];

  IF (SELECT EXISTS(SELECT 1
                      FROM pg_attribute
                      JOIN pg_class ON attrelid = pg_class.oid
                     WHERE relname = 'cohist'
                       AND attname = 'cohist_billtocountry'
                       AND attnum > 0)) THEN
    _columns := _columns || 'cohist_billtocountry'::TEXT || 'cohist_shiptocountry'::TEXT;
  END IF;

  IF (SELECT EXISTS(SELECT 1
                      FROM pg_attribute
                      JOIN pg_class ON attrelid = pg_class.oid
                     WHERE relname = 'asohist'
                       AND attname = 'asohist_billtocountry'
                       AND attnum > 0)) THEN
    _columns := _columns || 'asohist_billtocountry'::TEXT || 'asohist_shiptocountry'::TEXT;
  END IF;

  IF (SELECT EXISTS(SELECT 1
                      FROM pg_class
                     WHERE relname = 'rahead'
                       AND relkind = 'r')) THEN
    _columns := _columns || 'rahead_billtocountry'::TEXT || 'rahead_shipto_country'::TEXT;
  END IF;

  IF (SELECT EXISTS(SELECT 1
                      FROM pg_class
                     WHERE relname = 'tohead'
                       AND relkind = 'r')) THEN
    _columns := _columns || 'tohead_srccountry'::TEXT || 'tohead_destcountry'::TEXT;
  END IF;

  FOREACH _column IN ARRAY _columns
  LOOP
    _table = split_part(_column, '_', 1);

    IF _column = 'metric_value' THEN
      _metricstr := 'AND metric_name IN (''DefaultAddressCountry'', ''remitto_country'')';
    ELSE
      _metricstr := '';
    END IF;

    EXECUTE format('ALTER TABLE %I DISABLE TRIGGER ALL', _table);

    EXECUTE format('UPDATE %I
                       SET %I = country_abbr
                      FROM country
                     WHERE lower(country_name) = lower(%I)
                       %s', _table, _column, _column, _metricstr);

    EXECUTE format('ALTER TABLE %I DISABLE TRIGGER ALL', _table);
  END LOOP;

  SELECT COUNT(*) INTO _count
    FROM (
          SELECT addr_country AS country
            FROM addr
          UNION ALL
          SELECT quhead_billtocountry
            FROM quhead
          UNION ALL
          SELECT quhead_shiptocountry
            FROM quhead
          UNION ALL
          SELECT cohead_billtocountry
            FROM cohead
          UNION ALL
          SELECT cohead_shiptocountry
            FROM cohead
          UNION ALL
          SELECT invchead_billto_country
            FROM invchead
          UNION ALL
          SELECT invchead_shipto_country
            FROM invchead
          UNION ALL
          SELECT cmhead_billtocountry
            FROM cmhead
          UNION ALL
          SELECT cmhead_shipto_country
            FROM cmhead
          UNION ALL
          SELECT pohead_vendcountry
            FROM pohead
          UNION ALL
          SELECT pohead_shiptocountry
            FROM pohead
          UNION ALL
          SELECT metric_value
            FROM metric
           WHERE metric_name IN ('DefaultAddressCountry', 'remitto_country')
         ) AS countries
   WHERE COALESCE(trim(country), '') != ''
     AND country NOT IN (SELECT COALESCE(country_abbr, '')
                           FROM country);

  IF 'cohist_billtocountry' IN (SELECT (UNNEST(_columns))) THEN
    SELECT _count + COUNT(*) INTO _count
      FROM (
            SELECT cohist_billtocountry AS country
              FROM cohist
            UNION ALL
            SELECT cohist_shiptocountry
              FROM cohist
           ) AS countries
     WHERE COALESCE(trim(country), '') != ''
       AND country NOT IN (SELECT COALESCE(country_abbr, '')
                             FROM country);
  END IF;

  IF 'asohist_billtocountry' IN (SELECT (UNNEST(_columns))) THEN
    SELECT _count + COUNT(*) INTO _count
      FROM (
            SELECT asohist_billtocountry AS country
              FROM asohist
            UNION ALL
            SELECT asohist_shiptocountry
              FROM asohist
           ) AS countries
     WHERE COALESCE(trim(country), '') != ''
       AND country NOT IN (SELECT COALESCE(country_abbr, '')
                             FROM country);
  END IF;

  IF 'rahead_billtocountry' IN (SELECT (UNNEST(_columns))) THEN
    SELECT _count + COUNT(*) INTO _count
      FROM (
            SELECT rahead_billtocountry AS country
              FROM rahead
            UNION ALL
            SELECT rahead_shipto_country
              FROM rahead
           ) AS countries
     WHERE COALESCE(trim(country), '') != ''
       AND country NOT IN (SELECT COALESCE(country_abbr, '')
                             FROM country);
  END IF;

  IF 'tohead_srccountry' IN (SELECT (UNNEST(_columns))) THEN
    SELECT _count + COUNT(*) INTO _count
      FROM (
            SELECT tohead_srccountry AS country
              FROM tohead
            UNION ALL
            SELECT tohead_destcountry
              FROM tohead
           ) AS countries
     WHERE COALESCE(trim(country), '') != ''
       AND country NOT IN (SELECT COALESCE(country_abbr, '')
                             FROM country);
  END IF;

  IF _count > 0 THEN
    RAISE EXCEPTION 'It looks as though % record(s) were not successfully migrated. Please requery and try again. If you have repeated problems contact xTuple Support.', _count;
  END IF;

  PERFORM setMetric('ISOCountries', 't');

END
$$ language plpgsql;
