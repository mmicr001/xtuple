(function () {
  "use strict";

  var DEBUG = false,
    _      = require("underscore"),
    assert = require('chai').assert,
    dblib  = require('../dblib'),
    datasource = dblib.datasource,
    adminCred = dblib.generateCreds();

  // TODO - write unit tests for the other versions of issueToShipping()
  describe("issueToShipping(text, integer, numeric, integer, timestamp with time zone, integer, boolean, boolean)", function () {
    this.timeout(10 * 1000);

    var params = {
      itemNumber: "BTRUCK1",
      whCode: "WH1",
      qty: 1
    };

    it("should get the itemsite_id and qoh",function (done) {
      var sql = "SELECT itemsite_qtyonhand, itemsite_id" +
                "  FROM itemsite" +
                " WHERE itemsite_id = getitemsiteid($1, $2);",
        options = _.extend({}, adminCred, { parameters: [ params.whCode, params.itemNumber ]});

      datasource.query(sql, options, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        assert.operator(res.rows[0].itemsite_id, ">", 0);
        assert.operator((+res.rows[0].itemsite_qtyonhand + +params.qty), ">", 0);
        params.itemsiteId = res.rows[0].itemsite_id;
        params.qohBefore = res.rows[0].itemsite_qtyonhand;
        done();
      });
    });

    // Create a Sales Order
    it("should create a sales order", function (done) {
     var callback = function (result) {
        if (DEBUG)
          console.log("issuetoshipping createSalesOrder callback result: ", result);

        assert.isNotNull(result);
        params.coheadId = result;
        done();
      };

      dblib.createSalesOrder(callback);
    });

    // Create a line item
    it("should add a line item to the SO",function (done) {
      var callback = function (result) {  
        params.coitemId = result;
        done();
      };

      dblib.createSalesOrderLineItem(params, callback);
    });


    it.skip("should check site security", function (done) {
      // TODO
    });

    it.skip("should check for average cost items going negative", function (done) {
      // TODO
    });

    it.skip("should check auto registration", function (done) {
      // TODO
    });

    it.skip("should check hold", function (done) {
      // TODO
    });

    it.skip("should handle g/l transaction", function (done) {
      // TODO
    });

    it.skip("should handle reservation", function (done) {
      // TODO
    });

    it.skip("should check order type is either SO or TO", function (done) {
      // TODO
    });

    // Note: Don't handle distribution detail here, that will be done in private-extensions/test/inventory

    it.skip("should check possible negative inventory restrictions", function (done) {
      // TODO
    });

    it("issuetoshipping() should succeed", function (done) {
      var sql = "SELECT issueToShipping('SO', $1::integer, $2::numeric, NULL::integer, NOW(), NULL, FALSE, FALSE) AS result;",
        options = _.extend({}, adminCred, { parameters: [ params.coitemId, params.qty ]});
        
      datasource.query(sql, options, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        assert.operator(res.rows[0].result, ">", 0);
        done();
      });
    });

    it("should have updated qoh", function (done) {
      var sql = "SELECT itemsite_qtyonhand AS result" +
                "  FROM itemsite" +
                " WHERE itemsite_id=$1::integer;",
        options = _.extend({}, adminCred, { parameters: [ params.itemsiteId ]});
        
      datasource.query(sql, options, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        assert.equal(res.rows[0].result, (params.qohBefore - params.qty));
        done();
      });
    });

    it("there should be no unposted invhist records", function (done) {
      var sql = "SELECT true AS result" +
                "  FROM invhist" +
                " WHERE invhist_posted = false;";

      datasource.query(sql, adminCred, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 0);
        done();
      });
    });
  }); 
}());

