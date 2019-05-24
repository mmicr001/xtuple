var _      = require("underscore"),
    assert = require("chai").assert,
    dblib  = require("../dblib");

(function () {
  "use strict";

  describe("calcsalesorderamt()", function () {
    var datasource = dblib.datasource,
        adminCred  = dblib.generateCreds(),
        so
        ;

    before("need a sales order to work with", function (done) {
      var sql = "SELECT cohead.*,"
              + "       EXISTS(SELECT 1 FROM aropenalloc"
              + "               WHERE aropenalloc_doctype = 'S'"
              + "                 AND aropenalloc_doc_id = cohead_id) AS hasMisc,"
              + "       EXISTS(SELECT 1"
              + "                FROM invcitem"
              + "                JOIN invchead ON invcitem_invchead_id = invchead_id"
              + "                JOIN coitem   ON invcitem_coitem_id   = coitem_id"
              + "               WHERE invchead_posted) AS hasCredit"
              + "  FROM cohead"
              + " ORDER BY hasCredit DESC"
              + " LIMIT 1;";
      datasource.query(sql, adminCred, function (err, res) {
          assert.isNull(err);
          assert.equal(res.rowCount, 1);
          so = res.rows[0];
          done();
        });
    });

    describe("calcSalesOrderAmt(INTEGER)", function () {
      it("should return NULL for a non-existent order", function (done) {
        var sql = "SELECT calcSalesOrderAmt(-2) AS result;";
        datasource.query(sql, adminCred, function (err, res) {
          assert.isNull(err);
          assert.equal(res.rowCount, 1);
          assert.isNull(res.rows[0].result);
          done();
        });
      });

      it("should return non-0 for an existing order", function (done) {
        var sql = "SELECT calcSalesOrderAmt($1) AS result;",
            cred = _.extend({}, adminCred, { parameters: [ so.cohead_id ] });
        datasource.query(sql, cred, function (err, res) {
          assert.isNull(err);
          assert.equal(res.rowCount, 1);
          assert.notEqual(res.rows[0].result, 0.0);
          done();
        });
      });
    });

    describe("calcSalesOrderAmt(INTEGER, TEXT)", function () {
      _.each([ 'S', 'T', 'B', 'C', 'X', 'M', 'P', '[unknown]' ],
             function (e) {
              it("should return NULL for a non-existent order and type " + e, function (done) {
                var sql  = "SELECT calcSalesOrderAmt(-2, $1) AS result;",
                    cred = _.extend({}, adminCred, { parameters: [ e ] });
                datasource.query(sql, cred, function (err, res) {
                  assert.isNull(err);
                  assert.equal(res.rowCount, 1);
                  assert.isNull(res.rows[0].result);
                  done();
                });
              });

              it("should usually return non-0 for an existing order and type " + e, function (done) {
                var sql = "SELECT calcSalesOrderAmt($1, $2) AS result;",
                    cred = _.extend({}, adminCred, { parameters: [ so.cohead_id, e ] });
                datasource.query(sql, cred, function (err, res) {
                  assert.isNull(err);
                  assert.equal(res.rowCount, 1);
                  switch (e) {
                    case 'C':
                      if (so.hasCredit)
                        assert.notEqual(res.rows[0].result, 0.0);
                      else
                        assert.equal(res.rows[0].result, 0.0);
                      break;
                    case '[unknown]':
                      assert.equal(res.rows[0].result, 0.0);
                      break;
                    default:
                      assert.notEqual(res.rows[0].result, 0.0);
                      break;
                  }
                  done();
                });
              });
            });
    });

    describe.skip("calcSalesOrderAmt(pCoheadid INTEGER, pTaxzoneId INTEGER, pOrderDate DATE, pCurrId INTEGER, pFreight NUMERIC, pMisc NUMERIC)");
    describe.skip("calcSalesOrderAmt(pCoheadid INTEGER, pType TEXT, pTaxzoneId INTEGER, pOrderDate DATE, pCurrId INTEGER, pFreight NUMERIC, pMisc NUMERIC, pQuick BOOLEAN DEFAULT TRUE)");
  });
})();
