/*jshint node:true, indent:2, curly:false, eqeqeq:true, immed:true, latedef:true, newcap:true, noarg:true,
regexp:true, undef:true, strict:true, trailing:true, white:true */
/*global _:true */

(function () {
  "use strict";

  var path = require('path');

  exports.extensions = [
    path.join(__dirname, '../../../foundation-database'),
    path.join(__dirname, '../../../lib/orm'),
    path.join(__dirname, '../../..')
  ];
}());
