DROP function IF EXISTS xt.quote_tax_total(quhead) CASCADE;

create or replace function xt.quote_tax_total(quhead)
returns numeric as $$
BEGIN
  RETURN 0.00; -- DEPRECATED taxation function;
END;
$$ language plpgsql;

