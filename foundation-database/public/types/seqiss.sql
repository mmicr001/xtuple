DO $$
BEGIN
  CREATE TYPE seqiss AS (
    seqiss_number INTEGER,
    seqiss_time   TIMESTAMP WITH TIME ZONE
  );
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
$$ LANGUAGE plpgsql;
