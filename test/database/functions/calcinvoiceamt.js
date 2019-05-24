var _      = require("underscore"),
    assert = require("chai").assert,
    dblib  = require("../dblib");

(function () {
  "use strict";

  describe("calcInvoiceAmt()", function () {
    var datasource = dblib.datasource,
        adminCred  = dblib.generateCreds(),
        invchead
        ;

    before("need an invoice to work with", function (done) {
      var sql = "SELECT *"
              + "  FROM invchead"
              + " WHERE EXISTS(SELECT 1"
              + "                FROM invcitem"
              + "                WHERE invcitem_invchead_id = invchead_id"
              + "                  AND invcitem_billed > 0"
              + "                  AND invcitem_price  > 0"
              + "             )"
              + " LIMIT 1;";
      datasource.query(sql, adminCred, function (err, res) {
          assert.isNull(err);
          assert.equal(res.rowCount, 1);
          invchead = res.rows[0];
          done();
        });
    });

    describe("calcInvoiceAmt(INTEGER)", function () {
      it("should return NULL for a non-existent invoice", function (done) {
        var sql = "SELECT calcInvoiceAmt(-2) AS result;";
        datasource.query(sql, adminCred, function (err, res) {
          assert.isNull(err);
          assert.equal(res.rowCount, 1);
          assert.isNull(res.rows[0].result);
          done();
        });
      });

      it("should return non-0 for an existing invoice", function (done) {
        var sql = "SELECT calcInvoiceAmt($1) AS result;",
            cred = _.extend({}, adminCred, { parameters: [ invchead.invchead_id ] });
        datasource.query(sql, cred, function (err, res) {
          assert.isNull(err);
          assert.equal(res.rowCount, 1);
          assert.notEqual(res.rows[0].result, 0.0);
          done();
        });
      });
    });

    describe("calcInvoiceAmt(INTEGER, TEXT)", function () {
      _.each([ 'S', 'T', 'X', 'M', '[unknown]' ],
             function (e) {
              it("should return NULL for a non-existent invoice and type " + e, function (done) {
                var sql  = "SELECT calcInvoiceAmt(-2, $1) AS result;",
                    cred = _.extend({}, adminCred, { parameters: [ e ] });
                datasource.query(sql, cred, function (err, res) {
                  assert.isNull(err);
                  assert.equal(res.rowCount, 1);
                  assert.isNull(res.rows[0].result);
                  done();
                });
              });

              it("should usually return non-0 for an invoice order and type " + e, function (done) {
                var sql = "SELECT calcInvoiceAmt($1, $2) AS result;",
                    cred = _.extend({}, adminCred, { parameters: [ invchead.invchead_id, e ] });
                datasource.query(sql, cred, function (err, res) {
                  assert.isNull(err);
                  assert.equal(res.rowCount, 1);
                  switch (e) {
                    case 'X':
                      assert.isNotNull(res.rows[0].result); // TODO: compare with 0.0
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

    describe("calcInvoiceAmt(INTEGER, TEXT, INTEGER)", function () {
      var invcitem;

      before("need an invoice line item to work with", function (done) {
        var sql  = "SELECT *"
                 + "  FROM invcitem"
                 + " WHERE invcitem_invchead_id = $1"
                 + "   AND invcitem_billed > 0"
                 + "   AND invcitem_price  > 0"
                 + " LIMIT 1;",
            cred = _.extend({}, adminCred, { parameters: [ invchead.invchead_id ] });
        datasource.query(sql, cred, function (err, res) {
            assert.isNull(err);
            assert.equal(res.rowCount, 1);
            invcitem = res.rows[0];
            done();
          });
      });
      _.each([ 'S', 'T', 'X', 'M', '[unknown]' ],
             function (e) {
              it("should return NULL for a non-existent invoice and type " + e, function (done) {
                var sql  = "SELECT calcInvoiceAmt(-2, $1, $2) AS result;",
                    cred = _.extend({}, adminCred, { parameters: [ e, invcitem.invcitem_id ] });
                datasource.query(sql, cred, function (err, res) {
                  assert.isNull(err);
                  assert.equal(res.rowCount, 1);
                  assert.isNull(res.rows[0].result);
                  done();
                });
              });

              it("should usually return non-0 for an invoice and type " + e, function (done) {
                var sql = "SELECT calcInvoiceAmt($1, $2, $3) AS result;",
                    cred = _.extend({}, adminCred,
                                    { parameters: [ invchead.invchead_id, e, invcitem.invcitem_id ] });
                datasource.query(sql, cred, function (err, res) {
                  assert.isNull(err);
                  assert.equal(res.rowCount, 1);
                  switch (e) {
                    case 'X':
                      assert.isNotNull(res.rows[0].result); // TODO: compare with 0.0
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
  });
})();
