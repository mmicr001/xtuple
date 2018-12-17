var _      = require("underscore"),
    dblib  = require('../dblib'),
    assert = require('chai').assert;

(function () {
  "use strict";

  describe('sanity check all api views', function () {
    var datasource  = dblib.datasource,
        adminCred   = dblib.generateCreds(),
        view        = []
        ;

    it("test the views", function(done) {
      var query = "DO $$"
                + " DECLARE _view TEXT; _out RECORD;"
                + " BEGIN"
                + " FOR _view IN SELECT viewname FROM pg_views WHERE schemaname = 'api' LOOP"
                + "  EXECUTE format('SELECT * FROM api.%I LIMIT 1;', _view) INTO _out;"
                + "  RAISE NOTICE '% %', _view, row_to_json(_out);"
                + " END LOOP;"
                + "END; $$;";
      datasource.query(query, adminCred, function(err, res) {
        assert.isNull(err);
        done();
      });
    });

  });

})();
