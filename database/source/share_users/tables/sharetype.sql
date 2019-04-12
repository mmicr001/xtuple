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
