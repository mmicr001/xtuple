select xt.create_table('prjtaskext');

select xt.add_column('prjtaskext','prjtaskext_id', 'integer', 'primary key');
select xt.add_column('prjtaskext','prjtaskext_priority_id', 'integer', 'references incdtpriority (incdtpriority_id)');
select xt.add_column('prjtaskext','prjtaskext_pct_complete', 'numeric');

comment on table xt.prjtaskext is 'Project extension table';

insert into xt.prjtaskext
select task_id, null, case when task_status = 'C' then 1 else 0 end
  from task
 where not exists (
    select prjtaskext_id 
    from xt.prjtaskext 
    where task_id=prjtaskext_id
 );
