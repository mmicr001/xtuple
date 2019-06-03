select xt.create_view('xt.tskresourceanalysis', $$

select resource_name,  
       tskresource_percent * task_hours_budget as budgeted_hours,
       tskresource_percent * task_hours_actual as actual_hours, 
       tskresource_percent * (task_hours_budget - task_hours_actual) as balance_hours, 
       row_number() OVER () as row_number
  from xt.tskresource
  left join task on tskresource_prjtask_id = task_id
  left join xt.resource on tskresource_resource_id = xt.resource.obj_uuid

$$, false);

