DROP TABLE IF EXISTS xt.rptdef CASCADE;
DROP FUNCTION IF EXISTS xt.add_report_definition(text, integer, text);
DROP TABLE IF EXISTS xt.clientcode;
DROP FUNCTION IF EXISTS xt.insert_client(text, text, text, text);
DROP FUNCTION IF EXISTS xt.set_dictionary(text, text, text);

DELETE FROM xt.grpext
 WHERE grpext_ext_id IN (
   SELECT ext_id
     FROM xt.ext
    WHERE ext_location = '/core-extensions'
      AND ext_name IN (
        'crm',
        'project',
        'sales',
        'billing',
        'purchasing',
        'oauth2'
      )
 )
;

DELETE FROM xt.usrext
 WHERE usrext_ext_id IN (
   SELECT ext_id
     FROM xt.ext
    WHERE ext_location = '/core-extensions'
      AND ext_name IN (
        'crm',
        'project',
        'sales',
        'billing',
        'purchasing',
        'oauth2'
      )
 )
;

DELETE FROM xt.ext
 WHERE ext_location = '/core-extensions'
   AND ext_name IN (
    'crm',
    'project',
    'sales',
    'billing',
    'purchasing',
    'oauth2'
   )
;
