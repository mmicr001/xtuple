# Share Users Feature

`WARNING!!!` This feature is deprecated. It is still used by the v1 REST API. The code has been moved to this directory to allow it all to be easily removed when the v1 REST API is removed.

## Feature Overview
The Share Users Feature enforces access restriction to various business objects by only alowing a CRM Account's Users, the CRM Account's Owner user and the CRM Account's Sales Rep user to access the resource. This is accomplished by the `xt.share_users` view that contains a map of each business object/resource `obj_uuid` to the `username`s who have access to it. Several child views like, `xt.share_users_foo`, define the mappings. There is also a static mapping table, `xt.obj_share`, that contains explic maps.

The `xt.sharetype` table is used to register the various types of shares. The `xt.share_users` view is then built from it.

To improve performance of the `xt.share_users` view, a static `xt.cache_share_users` table was created that is used by the access restriction checks logic in the `XT.Data` layer. The records in the `xt.cache_share_users` table are maintained by triggers on various tables suck as `xt.refresh_invchead_share_users_cache()`. The cache table is "warmed" during the Node.js server statup process.
