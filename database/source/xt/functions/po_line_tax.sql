DROP function IF EXISTS xt.po_line_tax(poitem) CASCADE;

create or replace function xt.po_line_tax(poitem)
returns numeric as $$
BEGIN
  RETURN 0.00; -- DEPRECATED taxation function;
END;
$$ language plpgsql;

