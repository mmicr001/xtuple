DROP function IF EXISTS xt.co_line_tax(coitem) CASCADE;

create or replace function xt.co_line_tax(coitem)  
returns numeric as $$
BEGIN
  RETURN 0.00; -- DEPRECATED taxation function;
END;
$$ language plpgsql;
