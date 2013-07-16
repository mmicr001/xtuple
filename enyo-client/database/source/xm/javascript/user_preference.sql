select xt.install_js('XM','UserPreference','xtuple', $$
  /* Copyright (c) 1999-2011 by OpenMFG LLC, d/b/a xTuple. 
     See www.xm.ple.com/CPAL for the full text of the software license. */
  
  XM.UserPreference = {};

  XM.UserPreference.isDispatchable = true,

  XM.UserPreference.options = [
    "PreferredWarehouse"
  ]

  /* 
  Return DatabaseInfo configuration settings.

  @returns {Object}
  */
  XM.UserPreference.settings = function() {
    var keys = XM.DatabaseInformation.options.slice(0),
      data = Object.create(XT.Data);
    
    return JSON.stringify([]);
  }

  /* 
  Update DatabaseInfo configuration settings. Only valid options as defined in the array
  XM.DatabaseInfo.options will be processed.

   @param {Object} settings
   @returns {Boolean}
  */
  XM.DatabaseInformation.commitSettings = function(patches) {
    var settings, options = XM.DatabaseInformation.options.slice(0),
        data = Object.create(XT.Data), metrics = {};

    /* check privileges */
    if(!data.checkPrivilege('ConfigDatabaseInfo')) throw new Error('Access Denied');

    /* Compose our commit settings by applying the patch to what we already have */
    settings = JSON.parse(XM.DatabaseInformation.settings());
    if (!XT.jsonpatch.apply(settings, patches)) {
      plv8.elog(NOTICE, 'Malformed patch document');
    }

    /* remove read only settings */
    options.remove('Application');
    options.remove('ServerVersion');
    options.remove('ServerPatchVersion');

    /* update remaining options as metrics.
       first make sure we pass an object that only has valid metric options for this type */
    for(var i = 0; i < options.length; i++) {
      var prop = options[i];
      if(settings[prop] !== undefined) metrics[prop] = settings[prop];
    }
 
    return data.commitMetrics(metrics);
  }
  
$$ );

