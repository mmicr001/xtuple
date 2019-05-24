var _      =  require("underscore"),
    assert = require("chai").assert,
    dblib  = require("../dblib");

(function () {
  "use strict";

  describe("createPr()", function () {
    var datasource       = dblib.datasource,
        adminCred        = dblib.generateCreds(),
        hasPlannedOrders = false,
        mpr, prs
        ;

    before(function(done) {
      var sql = "SELECT EXISTS(SELECT 1"
              + "                FROM pg_class"
              + "               WHERE relname = 'planord') AS result;";
      datasource.query(sql, adminCred, function (err, res) {
        hasPlannedOrders = (res.rowCount == 1 && res.rows[0].result);
        done();
      });
    });

    before(function(done) {
      var sql = "SELECT MIN(pr_id) AS pr_id, pr_order_type"
              + "  FROM pr"
              + " GROUP BY pr_order_type;";
      datasource.query(sql, adminCred, function (err, res) {
        assert.isNull(err);
        prs = res.rows;
        done();
      });
    });

    describe("createPr(pParentType, pParentId)", function () {
      it("should raise an error for a bad order type", function (done) {
        var sql = "SELECT createPr('InvalidType', -2)  AS result;";
        datasource.query(sql, adminCred, function (err, res) {
          dblib.assertErrorCode(err, res, "createPr", -2);
          done();
        });
      });

      it("should raise an error for a non-existent work order", function (done) {
        var sql = "SELECT createPr('W', -2)  AS result;";
        datasource.query(sql, adminCred, function (err, res) {
          dblib.assertErrorCode(err, res, "createPr", -1);
          done();
        });
      });

      it("should raise an error for a non-existent sales order", function (done) {
        var sql = "SELECT createPr('S', -2)  AS result;";
        datasource.query(sql, adminCred, function (err, res) {
          dblib.assertErrorCode(err, res, "createPr", -1);
          done();
        });
      });

      it("should raise an error for a non-existent planned order", function (done) {
        var sql = "SELECT createPr('F', -2)  AS result;";
        datasource.query(sql, adminCred, function (err, res) {
          if (hasPlannedOrders)
            dblib.assertErrorCode(err, res, "createPr", -1);
          else
            assert.isNotNull(err);
          done();
        });
      });

      it("should return the pr_id for an existing pr", function(done) {
        if (Array.isArray(prs) && prs.length >= 1) {
          var sql  = "SELECT createPr(pr_order_type, pr_order_id) AS result"
                   + "  FROM pr"
                   + " WHERE pr_id = $1;",
              cred = _.extend({}, adminCred, { parameters: [ prs[0].pr_id ] });
          datasource.query(sql, cred, function (err, res) {
            assert.isNull(err);
            assert.equal(prs[0].pr_id, res.rows[0].result);
            done();
          });
        } else {
          console.warning("no pre-existing prs");
          done();
        }
      });
    });

    describe.skip("createPr(pOrderNumber, pParentType, pParentId)");
    /*
      if pOrderNumber == -1
        get a new pr number
      fi

      if the demand order is a work order, sales order, or planned order
        get itemsite, quantity, notes, and project id from demand order
      else
        fail -2
      fi
      if the demand order does not exist
        fail -1
      fi
      call 8-arg createpr
      return new pr_id
    */

    describe.skip("createPr(pOrderNumber, pParentType, pParentId, pParentNotes)");
    /*
      if pOrderNumber == -1
        get a new pr number
      fi

      if the demand order is a work order, sales order, or planned order
        get itemsite, quantity, notes, and project id from demand order
      else
        fail -2
      fi
      if the demand order does not exist
        fail -1
      fi
      call 8-arg createpr
      return new pr_id
    */

    describe("createPr(pOrderNumber, pItemsiteid, pQty, pDueDate, pNotes)", function () {

      it("should create a pr even if one already exists", function (done) {
        var sql = "SELECT createpr(NULL, pr_itemsite_id, 13, CURRENT_DATE, 'testing') AS result"
                + "  FROM pr"
                + " WHERE pr_id = $1;",
              cred = _.extend({}, adminCred, { parameters: [ prs[0].pr_id ] });
        datasource.query(sql, cred, function (err, res) {
          assert.isNull(err);
          assert.notEqual(prs[0].pr_id, res.rows[0].result);
          mpr = {"pr_id": res.rows[0].result, "pr_order_type": "M" };
          prs.push(mpr);
          done();
        });
      });

      it("should have created an 'M' pr", function(done) {
        var sql  = "SELECT pr_order_type FROM pr WHERE pr_id = $1;",
            cred = _.extend({}, adminCred, { parameters: [ mpr.pr_id ] });
        datasource.query(sql, cred, function (err, res) {
          assert.isNull(err);
          assert.equal(res.rowCount, 1);
          assert.equal(res.rows[0].pr_order_type, 'M');
          done();
        });
      });
    });

    describe.skip("createPr(pOrderNumber, pItemsiteid, pQty, pDueDate, pNotes, pOrderType, pOrderId");
    /*
      if existing pr for demand order and demand is not a manufacturing order
        return the existing pr_id
      else
        insert new pr
        return new pr_id
      fi
    */


    describe("createPr(pOrderNumber, pItemsiteid, pQty, pDueDate, pNotes, pOrderType, pOrderId, pProjId)", function() {
      it("should return the pr_id for an existing pr for non 'M'", function(done) {
        if (Array.isArray(prs) && prs.length >= 1) {
          var sql  = "SELECT createPr(NULL, pr_itemsite_id, 10, CURRENT_DATE, 'Testing createPr',"
                   + "                pr_order_type, pr_order_id, pr_prj_id) AS result"
                   + "  FROM pr"
                   + " WHERE pr_id = $1;",
              cred = _.extend({}, adminCred, { parameters: [ prs[0].pr_id ] });
          datasource.query(sql, cred, function (err, res) {
            assert.isNull(err);
            assert.equal(prs[0].pr_id, res.rows[0].result);
            done();
          });
        } else {
          console.warning("no pre-existing prs");
          done();
        }
      });

      it("should return a new pr_id for an existing 'M' pr", function(done) {
        if (mpr) {
          var sql  = "SELECT createPr(NULL, pr_itemsite_id, 10,"
                   + "                CURRENT_DATE, 'Testing createPr',"
                   + "                pr_order_type, pr_order_id, pr_prj_id) AS result"
                   + "  FROM pr"
                   + " WHERE pr_id = $1;",
              cred = _.extend({}, adminCred, { parameters: [ mpr.pr_id ] });
          datasource.query(sql, cred, function (err, res) {
            assert.isNull(err);
            assert.notEqual(prs[0].pr_id, res.rows[0].result);
            done();
          });
        } else {
          console.log("no pre-existing 'M' prs");
          done();
        }
      });

      it("should return a new pr_id for a sales order", function(done) {
        var sql = "SELECT createPr(NULL, coitem_itemsite_id, coitem_qtyord,"
                + "                CURRENT_DATE, 'Testing createPr',"
                + "                'S', coitem_cohead_id, NULL) AS result"
                + "  FROM coitem"
                + "  JOIN itemsite ON coitem_itemsite_id = itemsite_id"
                + " WHERE coitem_status = 'O'"
                + "   AND coitem_cohead_id NOT IN (SELECT pr_order_id"
                + "                                  FROM pr)"
                + " LIMIT 1;";
        datasource.query(sql, adminCred, function (err, res) {
          var pr;
          assert.isNull(err);
          if (res.rowCount > 0)
          {
            pr = prs.filter(function (e) { e.pr_id == res.rows[0].result });
            assert.isEmpty(pr);
          } else
            console.log("could not create a sales order pr");
          done();
        });
      });

    });
  });
})();
