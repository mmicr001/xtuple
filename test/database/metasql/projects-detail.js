var _      = require("underscore"),
    assert = require('chai').assert,
    dblib  = require('../dblib');

(function () {
  "use strict";
  var group  = "projects",
      name   = "detail"
      ;

  describe(group + '-' + name + ' mql', function () {

    var datasource = dblib.datasource,
        adminCred  = dblib.generateCreds(),
        constants  = { assigned:   'assigned',
                       canceled:   'canceled',
                       closed:     'closed',
                       complete:   'complete',
                       confirmed:  'confirmed',
                       converted:  'converted',
                       expired:    'expired',
                       exploded:   'exploded',
                       feedback:   'feedback',
                       inprocess:  'inprocess',
                       invoices:   'invoices',
                       "new":      'new',
                       open:       'open',
                       planning:   'planning',
                       pos:        'pos',
                       posted:     'posted',
                       prs:        'prs',
                       quotes:     'quotes',
                       released:   'released',
                       resolved:   'resolved',
                       sos:        'sos',
                       tasks:      'tasks',
                       total:      'total',
                       unposted:   'unposted',
                       unreleased: 'unreleased',
                       wos:        'wos'
        },
        mql,
        testcase   = []
        ;

    before("needs the query", function (done) {
      var sql = "select metasql_query from metasql"        +
                " where metasql_group = '"  + group + "'"  +
                "   and metasql_name  = '"  + name  + "'"  +
                "   and metasql_grade = 0;";
      datasource.query(sql, adminCred, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        mql = res.rows[0].metasql_query;
        mql = mql.replace(/"/g, "'").replace(/--.*\n/g, "").replace(/\n/g, " ");
        done();
      });
    });

    //before
    it.skip("needs relevant characteristics", function (done) {
      var sql = "select min(char_id) as char_id, char_type"     +
                "  from char"                                   +
                "  join charuse on char_id = charuse_char_id"   +
                " where char_search"                            +
                "   and charuse_target_type = 'SO'"             +
                " group by char_type;";
      datasource.query(sql, adminCred, function (err, res) {
        assert.isNull(err);
        _.each(res.rows, function (row) {
          var test = { charClause: [] };
          switch (row.char_type) {
            // TODO: where do we put the VALUE?
            case dblib.CHARTEXT:
              test.char_id_text_list = [ row.char_id ];
              test.charClause.push("charass_alias" + row.char_id +
                                   ".charass_value ~* '[a-z]'");
              break;
            case dblib.CHARLIST:
              /* skip for now - we need to get list options from the db
              test.char_id_list_list = row.char_id;
              test.charClause.push("charass_alias" + row.char_id +
                               ".charass_value ~* '[a-z]'";
              */
              break;
            case dblib.CHARDATE:
              test.char_id_date_list = row.char_id;
              test.charClause.push("charass_alias" + row.char_id +
                                   ".charass_value::date >= '2016-01-01'");
              test.charClause.push("charass_alias" + row.char_id +
                                   ".charass_value::date <= '2016-12-31'");
              break;
            default:
              assert.isFalse("found unknown char_type" + row.char_type);
              break;
          }
          test.charClause = "AND " + test.charClause.join(" AND ");
          testcase.push(test);
        });
        done();
      });
    });

    // TODO: add charClause and char_id_{date,list,text}_list
    _.each([ constants,
             _.extend({}, constants, { assignedEndDate:      '2019-12-31'       }),
             _.extend({}, constants, { assignedStartDate:    '2010-01-01'       }),
             _.extend({}, constants, { assigned_username:    'admin'            }),
             _.extend({}, constants, { assigned_usr_pattern: '[aeiou]'          }),
             _.extend({}, constants, { cntct_id:              1                 }),
             _.extend({}, constants, { cohead_id:             2                 }),
             _.extend({}, constants, { completedEndDate:     '2018-12-15'       }),
             _.extend({}, constants, { completedStartDate:   '2011-01-01'       }),
             _.extend({}, constants, { crmacct_id:            3                 }),
             _.extend({}, constants, { dueEndDate:           '2017-12-31'       }),
             _.extend({}, constants, { dueStartDate:         '2012-01-01'       }),
             _.extend({}, constants, { owner_username:       'admin'            }),
             _.extend({}, constants, { owner_usr_pattern:    'admin'            }),
             _.extend({}, constants, { pohead_id:             4                 }),
             _.extend({}, constants, { prj_id:                5                 }),
             _.extend({}, constants, { prjtype_id:            6                 }),
             _.extend({}, constants, { project_task:         '[tT][aA][sS][kK]' }),
             _.extend({}, constants, { search_pattern:       '^[asdf]'          }),
             _.extend({}, constants, { showComplete:         true               }),
             _.extend({}, constants, { showIn:               true               }),
             _.extend({}, constants, { showPo:               true               }),
             _.extend({}, constants, { showSo:               true               }),
             _.extend({}, constants, { showWo:               true               }),
             _.extend({}, constants, { startEndDate:         '2016-12-31'       }),
             _.extend({}, constants, { startStartDate:       '2013-01-01'       }),
             _.extend({}, constants, { username:             'admin'            }),
             _.extend({}, constants, { wo_id:                 7                 })
      ], function (p) {

        beforeEach("needs to set the search_path", function (done) {
          var sql = "SELECT login(true);";
          datasource.query(sql, adminCred, function (err, res) {
            assert.isNull(err);
            assert.equal(res.rowCount, 1);
            done();
          });
        });

        it("should succeed with " + JSON.stringify(p), function (done) {
          var sql = "do $$"                 +
                    "var params = { params: " + JSON.stringify(p) + "}," +
                    "    mql    = \""         + mql              + "\"," +
                    "    sql    = XT.MetaSQL.parser.parse(mql, params)," +
                    "    rows   = plv8.execute(sql);"                    +
                    "$$ language plv8;";
          datasource.query(sql, adminCred, function (err, res) {
            assert.isNull(err);
            done();
          });
        });
      });

  });

})();
