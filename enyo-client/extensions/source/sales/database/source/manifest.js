{
  "name": "sales",
  "comment": "Sales extension",
  "loadOrder": 20,
  "databaseScripts": [
    "xt/trigger_functions/refresh_cohead_share_users_cache.sql",
    "public/tables/cohead.sql",
    "public/tables/custinfo.sql",
    "public/tables/shiptoinfo.sql",
    "xt/tables/rptdef.sql",
    "xt/views/share_users_cust_cntct.sql",
    "xt/views/share_users_shipto_cntct.sql",
    "xt/tables/sharetype.sql"
  ]
}
