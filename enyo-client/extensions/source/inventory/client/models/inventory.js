/*jshint indent:2, curly:true, eqeqeq:true, immed:true, latedef:true,
newcap:true, noarg:true, regexp:true, undef:true, strict:true, trailing:true,
white:true*/
/*global XT:true, XM:true, _:true */

(function () {
  "use strict";

  XT.extensions.inventory.initInventoryModels = function () {

    /**
      @class

      @extends XM.Model
    */
    XM.InventoryHistory = XM.Model.extend({

      recordType: "XM.InventoryHistory"

    });

    /**
      @class

      @extends XM.Model
    */
    XM.InventoryDetail = XM.Model.extend({

      recordType: "XM.InventoryDetail"

    });

    /**
      @class

      @extends XM.Model
    */
    XM.IssueToShipping = XM.Model.extend({

      recordType: "XM.IssueToShipping",

      readOnlyAttributes: [
        "atShipping",
        "balance",
        "item",
        "order",
        "ordered",
        "returned",
        "site",
        "shipment",
        "shipped"
      ],

      name: function () {
        return this.get("order") + " #" + this.get("lineNumber");
      },

      bindEvents: function () {
        XM.Model.prototype.bindEvents.apply(this, arguments);

        // Bind events
        this.on("statusChange", this.statusDidChange);
        this.on("change:toIssue", this.toIssueDidChange);
      },

      canIssueStock: function (callback) {
        var isShipped = this.getValue("shipment.isShipped") || false;
        if (callback) {
          callback(!isShipped);
        }
        return this;
      },

      canReturnStock: function (callback) {
        var isShipped = this.getValue("shipment.isShipped") || false,
          atShipping = this.get("atShipping");
        if (callback) {
          callback(!isShipped && atShipping > 0);
        }
        return this;
      },

      /**
        Attempt to distribute any undistributed inventory to default location.

        @returns {Object} Receiver
      */
      distributeToDefault: function () {
        var itemSite = this.get("itemSite"),
          autoIssue = itemSite.get("stockLocationAuto"),
          stockLoc,
          toIssue,
          undistributed,
          detail;

        if (!autoIssue) { return this; }

        stockLoc = itemSite.get("stockLocation");
        toIssue = this.get("toIssue");
        undistributed = this.undistributed();
        detail = _.find(itemSite.get("detail").models, function (model) {
          return  model.get("location").id === stockLoc.id;
        });
        
        if (detail) { // Might not be any inventory there now
          detail.distribute(undistributed);
        }

        return this;
      },

      doIssueStock: function (callback) {
        if (callback) {
          callback(true);
        }
        return this;
      },

      doReturnStock: function (callback) {
        var that = this,
          options = {};

        // Refresh once we've completed the work
        options.success = function () {
          that.fetch({
            success: function () {
              if (callback) {
                callback();
              }
            }
          });
        };

        this.setStatus(XM.Model.BUSY_COMMITTING);
        this.dispatch("XM.Inventory", "returnFromShipping", [this.id], options);

        return this;
      },

      /**
        Calculate the balance remaining to issue.

        @returns {Number}
      */
      issueBalance: function () {
        var balance = this.get("balance"),
          atShipping = this.get("atShipping"),
          toIssue = XT.math.subtract(balance, atShipping, XT.QUANTITY_SCALE);
        return toIssue >= 0 ? toIssue : 0;
      },

      /**
        Formats distribution detail to an object that can be processed by
        `issueToShipping` dispatch function called in `save`.

        @returns {Object}
      */
      formatDetail: function () {
        var ret = [],
          details = this.getValue("itemSite.detail").models;
        _.each(details, function (detail) {
          var qty = detail.get("distributed");
          if (qty) {
            ret.push({
              location: detail.get("location").id,
              quantity: qty
            });
          }
        });
        return ret;
      },

      /**
        Overload: Calls `issueToShipping` dispatch function.

        @returns {Object} Receiver
        */
      save: function (key, value, options) {
        options = options ? _.clone(options) : {};

        // Handle both `"key", value` and `{key: value}` -style arguments.
        if (_.isEmpty(key)) {
          options = value ? _.clone(value) : {};
        }

        var toIssue = this.get("toIssue"),
          that = this,
          callback,
          err;
        
        // Callback for after we determine quantity validity
        callback = function (resp) {
          if (!resp.answer) { return; }
            
          var dispOptions = {},
            issOptions = {},
            detail = that.formatDetail(),
            params = [
              that.id,
              that.get("toIssue"),
              issOptions = {}
            ];

          // Refresh once we've completed the work
          dispOptions.success = function () {
            that.fetch(options);
          };

          // Add distribution detail if applicable
          if (detail.length) {
            issOptions.detail = detail;
          }
          that.setStatus(XM.Model.BUSY_COMMITTING);
          that.dispatch("XM.Inventory", "issueToShipping", params, dispOptions);
        };

        // Validate
        if (this.undistributed()) {
          err = XT.Error.clone("xt2017");
        } else if (toIssue <= 0) {
          err = XT.Error.clone("xt2013");
        } else if (!this.issueBalance() && toIssue > 0) {
          this.notify("_issueExcess".loc(), {
            type: XM.Model.QUESTION,
            callback: callback
          });
        }

        if (err) {
          this.trigger("invalid", this, err, options || {});
        } else {
          callback({answer: true});
        }

        return this;
      },

      /**

        Returns with detail distribution is required.

        @returns {Boolean}
        */
      requiresDetail: function () {
        return this.getValue("itemSite.locationControl");
      },

      statusDidChange: function () {
        if (this.getStatus() === XM.Model.READY_CLEAN) {
          this.set("toIssue", this.issueBalance());
        }
      },

      toIssueDidChange: function () {
        this.distributeToDefault();
      },

      /**
        Return the quantity of items that require detail distribution.
      
        @returns {Number}
      */
      undistributed: function () {
        var toIssue = this.get("toIssue"),
          scale = XT.QTY_SCALE,
          undist = 0,
          dist;
        // We only care about distribution on controlled items
        if (this.requiresDetail() && toIssue) {
          // Get the distributed values
          dist = _.pluck(_.pluck(this.getValue("itemSite.detail").models, "attributes"), "distributed");
          // Filter on only ones that actually have a value
          if (dist.length) {
            undist = XT.math.add(dist, scale);
          }
          undist = XT.math.subtract(toIssue, undist, scale);
        }
        return undist;
      }

    });

    // ..........................................................
    // COLLECTIONS
    //

    /**
      @class

      @extends XM.Collection
    */
    XM.InventoryHistoryCollection = XM.Collection.extend({

      model: XM.InventoryHistory

    });

    /**
      @class

      @extends XM.Collection
    */
    XM.IssueToShippingCollection = XM.Collection.extend({

      model: XM.IssueToShipping

    });

  };

}());

