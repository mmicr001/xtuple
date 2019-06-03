/*
 * This view lists all postgres usernames that are associated with a CRM
 * Account that owns a resource. That associaiton is either the main user
 * account, owner's user account, customer's sale rep's user account or
 * a shared access that has been specifically granted.
 *
 * This view can be used to determine which users have personal privilege
 * access to a Ship To based on what CRM Account it belongs to.
 */

select xt.create_view('xt.share_users_shipto', $$

  -- Ship To CRM Account's users.
  SELECT
    shiptoinfo.obj_uuid::uuid AS obj_uuid,
    username::text AS username
  FROM shiptoinfo
  JOIN custinfo ON shipto_cust_id = cust_id
  LEFT JOIN xt.crmacct_users ON cust_crmacct_id = crmacct_id
  WHERE username IS NOT NULL;

$$, false);
