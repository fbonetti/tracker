var r = require('rethinkdb');
var settings = {};

r.connect(function(err, conn) {
  r.dbCreate("weather_balloon_tracker").run(conn);
  r.db("weather_balloon_tracker").tableCreate("readings").run(conn);
});