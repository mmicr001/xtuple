DROP function IF EXISTS xt.quote_line_tax(quitem) CASCADE;

create or replace function xt.quote_line_tax(quitem)
returns numeric as $$
BEGIN
  RETURN 0.00; -- DEPRECATED taxation function;
END;
$$ language plpgsql;

