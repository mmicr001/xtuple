create or replace function xt.prj_budget_exp(prj_id integer) returns numeric stable as $$
  select coalesce(sum(task_exp_budget),0) from task where task_prj_id=$1;
$$ language sql;