select xt.create_view('xt.resource', $$

select emp_code as resource_code,
       coalesce(emp_name, emp_code) as resource_name,
       obj_uuid
  from emp
union all
select groups_name,
       coalesce(groups_descrip, groups_name),
       obj_uuid
  from empgrp;

$$, false);
