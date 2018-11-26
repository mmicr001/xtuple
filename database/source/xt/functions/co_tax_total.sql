DROP function IF EXISTS xt.co_tax_total(cohead) CASCADE;
  
create or replace function xt.co_tax_total(cohead) 
returns numeric as $$
BEGIN
  RETURN 0.00; -- DEPRECATED taxation function;
END;
$$ language plpgsql;
