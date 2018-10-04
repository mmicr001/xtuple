DROP function IF EXISTS xt.invc_tax_total(integer) CASCADE;

create or replace function xt.invc_tax_total(invchead_id integer) 
returns numeric as $$
BEGIN
  RETURN 0.00; -- DEPRECATED taxation function;
END;
$$ language plpgsql;

