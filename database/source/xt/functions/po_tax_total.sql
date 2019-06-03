DROP function IF EXISTS xt.po_tax_total(pohead) CASCADE;

create or replace function xt.po_tax_total(pohead)
returns numeric as $$
BEGIN
  RETURN 0.00; -- DEPRECATED taxation function;
END;
$$ language plpgsql;

