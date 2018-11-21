DROP function IF EXISTS xt.cm_tax_total(cmhead_id integer) CASCADE;

create or replace function xt.cm_tax_total(cmhead_id integer)
returns numeric as $$
BEGIN
  RETURN 0.00; -- DEPRECATED taxation function;
END;
$$ language plpgsql;

