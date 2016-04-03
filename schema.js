var r = require('rethinkdb');
var settings = {};

r.connect(function(err, conn) {
  r.dbCreate("tracker").run(conn);
  r.db("tracker").tableCreate("readings").run(conn);

  conn.close();
});