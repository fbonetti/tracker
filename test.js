var r = require('rethinkdb');

r.connect({db: 'weather_balloon_tracker'}, function(err, conn) {
  r.table('readings').run(conn, function(err, result) {
    if (err) throw err;

    result.each(function(err, result) {
      console.log(result);
    });



    conn.close();
  });
});
