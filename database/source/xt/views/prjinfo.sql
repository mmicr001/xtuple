select xt.create_view('xt.prjinfo', $$

   select  
   prj_id, prj_number, prj_name, prj_status, prj_start_date, prj_assigned_date, prj_due_date, prj_completed_date,  
   prj_username, prj_owner_username, prj_crmacct_id, prj_cntct_id, prj_prjtype_id,
   coalesce(sum(task_hours_budget),0) as prj_hours_budget,  
   coalesce(sum(task_hours_actual),0) as prj_hours_actual,  
   coalesce(sum(task_hours_budget),0) - coalesce(sum(task_hours_actual),0) as prj_hours_balance,  
   coalesce(sum(task_exp_budget),0) as prj_exp_budget,  
   coalesce(sum(task_exp_actual),0) as prj_exp_actual,  
   coalesce(sum(task_exp_budget),0) - coalesce(sum(task_exp_actual),0) as prj_exp_balance,  
   crmacct_number, cntct_number  
   from prj  
     left join task on task_prj_id=prj_id AND task_parent_type='J'
     left join crmacct on prj_crmacct_id=crmacct_id   
     left join cntct on prj_cntct_id=cntct_id  
   group by prj_id, prj_number, prj_name, prj_status, prj_start_date, prj_assigned_date, prj_due_date, prj_completed_date,  
   prj_username, prj_owner_username, prj_crmacct_id, crmacct_number, cntct_number, prj_prjtype_id;

$$);


