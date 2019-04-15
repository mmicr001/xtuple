drop view if exists xt.share_users cascade;

-- placeholder view

create view xt.share_users as
select
  null::uuid as obj_uuid,
  null::text as username;

select dropIfExists('TRIGGER', 'sharetype_did_change', 'xt');

-- table definition

select xt.create_table('sharetype', 'xt');
select xt.add_column('sharetype','sharetype_id', 'serial', 'primary key', 'xt');
select xt.add_column('sharetype','sharetype_nsname', 'text');
select xt.add_column('sharetype','sharetype_tblname', 'text');
select xt.add_column('sharetype','sharetype_col_obj_uuid', 'text');
select xt.add_column('sharetype','sharetype_col_username', 'text');

select xt.add_constraint('sharetype','sharetype_unique', 'unique(sharetype_nsname, sharetype_tblname, sharetype_col_obj_uuid, sharetype_col_username)');

comment on table xt.sharetype is 'Share User Type Map';

-- create trigger

create trigger sharetype_did_change after insert or update or delete on xt.sharetype for each row execute procedure xt.sharetype_did_change();

delete from xt.sharetype;

-- Default shared access grants.
insert into xt.sharetype (
  sharetype_nsname,
  sharetype_tblname,
  sharetype_col_obj_uuid,
  sharetype_col_username
) values (
  'xt',
  'share_users_default',
  'obj_uuid',
  'username'
);



-- Invoice CRM Account's users.
delete from xt.sharetype where sharetype_tblname = 'share_users_invchead';
insert into xt.sharetype (
  sharetype_nsname,
  sharetype_tblname,
  sharetype_col_obj_uuid,
  sharetype_col_username
) values (
  'xt',
  'share_users_invchead',
  'obj_uuid',
  'username'
);

-- Contact CRM Account's users.
insert into xt.sharetype (
  sharetype_nsname,
  sharetype_tblname,
  sharetype_col_obj_uuid,
  sharetype_col_username
) values (
  'xt',
  'share_users_cntct',
  'obj_uuid',
  'username'
);

-- Address CRM Account's users.
insert into xt.sharetype (
  sharetype_nsname,
  sharetype_tblname,
  sharetype_col_obj_uuid,
  sharetype_col_username
) values (
  'xt',
  'share_users_addr',
  'obj_uuid',
  'username'
);

-- Customer CRM Account's users.
delete from xt.sharetype where sharetype_tblname = 'share_users_cust';
insert into xt.sharetype (
  sharetype_nsname,
  sharetype_tblname,
  sharetype_col_obj_uuid,
  sharetype_col_username
) values (
  'xt',
  'share_users_cust',
  'obj_uuid',
  'username'
);

-- Contact that is on a Customer CRM Account's users.
delete from xt.sharetype where sharetype_tblname = 'share_users_cust_cntct';
insert into xt.sharetype (
  sharetype_nsname,
  sharetype_tblname,
  sharetype_col_obj_uuid,
  sharetype_col_username
) values (
  'xt',
  'share_users_cust_cntct',
  'obj_uuid',
  'username'
);

-- Ship To CRM Account's users.
delete from xt.sharetype where sharetype_tblname = 'share_users_shipto';
insert into xt.sharetype (
  sharetype_nsname,
  sharetype_tblname,
  sharetype_col_obj_uuid,
  sharetype_col_username
) values (
  'xt',
  'share_users_shipto',
  'obj_uuid',
  'username'
);

-- Contact that is on a Ship To CRM Account's users.
delete from xt.sharetype where sharetype_tblname = 'share_users_shipto_cntct';
insert into xt.sharetype (
  sharetype_nsname,
  sharetype_tblname,
  sharetype_col_obj_uuid,
  sharetype_col_username
) values (
  'xt',
  'share_users_shipto_cntct',
  'obj_uuid',
  'username'
);

-- Address that is on a Ship To CRM Account's users.
delete from xt.sharetype where sharetype_tblname = 'share_users_shipto_addr';
insert into xt.sharetype (
  sharetype_nsname,
  sharetype_tblname,
  sharetype_col_obj_uuid,
  sharetype_col_username
) values (
  'xt',
  'share_users_shipto_addr',
  'obj_uuid',
  'username'
);

-- Customer that a Ship To is on CRM Account's users.
delete from xt.sharetype where sharetype_tblname = 'share_users_shipto_cust';
insert into xt.sharetype (
  sharetype_nsname,
  sharetype_tblname,
  sharetype_col_obj_uuid,
  sharetype_col_username
) values (
  'xt',
  'share_users_shipto_cust',
  'obj_uuid',
  'username'
);

-- Sales Order CRM Account's users.
delete from xt.sharetype where sharetype_tblname = 'share_users_cohead';
insert into xt.sharetype (
  sharetype_nsname,
  sharetype_tblname,
  sharetype_col_obj_uuid,
  sharetype_col_username
) values (
  'xt',
  'share_users_cohead',
  'obj_uuid',
  'username'
);
