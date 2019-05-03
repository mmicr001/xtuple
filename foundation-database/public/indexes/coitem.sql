select xt.add_index('coitem', 'coitem_cohead_id', 'coitem_cohead_id_key', 'btree', 'public');
select xt.add_index('coitem', 'coitem_itemsite_id', 'coitem_itemsite_id', 'btree', 'public');
select xt.add_index('coitem', 'coitem_linenumber', 'coitem_linenumber_key', 'btree', 'public');
select xt.add_index('coitem', 'coitem_status', 'coitem_status_key', 'btree', 'public');

DO $$
BEGIN
  IF NOT EXISTS (
      SELECT 1
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relname = 'coitem_status_open_idx'
        AND n.nspname = 'public'
  ) THEN
    CREATE INDEX coitem_status_open_idx
    ON coitem (coitem_id)
    WHERE (coitem_status != ALL ('{X,C}'::bpchar[]));
  END IF;
END
$$;
