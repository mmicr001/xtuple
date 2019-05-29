var _    = require("underscore"),
  assert = require('chai').assert,
  dblib  = require('../dblib');

(function () {
  "use strict";

  describe('Create Contact', function () {

    var datasource = dblib.datasource,
        adminCred = dblib.generateCreds(),
        newcntct,
        crmacct
        ;

    it("should create a new contact", function (done) {
      var sql = "select saveCntct(NEXTVAL('cntct_cntct_id_seq')::INT, CURRVAL('cntct_cntct_id_seq')::TEXT,NULL::INT," +
		   "'Mr'::TEXT,'Test'::TEXT,''::TEXT,'Contact'::TEXT,''::TEXT,'TEST'::TEXT," +
		   "true,'{}'::json,'test_contact@example.com'::TEXT,'www.xtuple.com'::TEXT," +
                   "'This is a test contact'::TEXT,''::TEXT,'CHECK'::TEXT,''::TEXT, true, 'A Test Company'::TEXT) AS result;";
      datasource.query(sql, adminCred, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        newcntct = res.rows[0].result;
        done();
      });
    });

    it("should find a random CRM Account", function (done) {
      var sql  = "SELECT crmacct_id FROM crmacct " +
          	 " OFFSET floor(random() * (SELECT COUNT(*) FROM crmacct)) LIMIT 1;";
      datasource.query(sql, adminCred, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        crmacct = res.rows[0].crmacct_id;
        done();
      });
    });

    it("should assign new contact to found CRM Account", function (done) {
      var sql = "INSERT INTO crmacctcntctass (crmacctcntctass_crmacct_id, crmacctcntctass_cntct_id," +
            "      crmacctcntctass_crmrole_id, crmacctcntctass_default, crmacctcntctass_active)" +
            " VALUES ($1::INTEGER, $2::INTEGER, getcrmroleid(), true, true);",
         cred = _.extend({}, adminCred,
            { parameters: [ crmacct, newcntct ] });
      
      datasource.query(sql, cred, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        done();
      });
    });

    it("should delete the new contact", function (done) {
      var sql = "select deleteCntct($1, FALSE) AS result;",
        cred = _.extend({}, adminCred,
                        { parameters: [ newcntct ] });
      datasource.query(sql, cred, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        assert.equal(res.rows[0].result, true);
        done();
      });
    });

    it("should check contact was deleted", function (done) {
      var sql = "select * from cntct WHERE cntct_id=$1;",
        cred = _.extend({}, adminCred,
                        { parameters: [ newcntct ] });
      datasource.query(sql, cred, function (err, res) {
        assert.equal(res.rowCount, 0);
        done();
      });
    });

    it("should check contact assignments were deleted", function (done) {
      var sql = "select * from crmacctcntctass WHERE crmacctcntctass_cntct_id=$1;",
        cred = _.extend({}, adminCred,
                        { parameters: [ newcntct ] });
      datasource.query(sql, cred, function (err, res) {
        assert.equal(res.rowCount, 0);
        done();
      });
    });

  });

}());
