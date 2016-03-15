var io = require('socket.io')(8050);
var r = require('rethinkdb');

var emitInitialReadings = function(socket, conn) {
  r.table('readings').run(conn, function(err, results) {
    if (err) throw err;

    results.each(function(err, result) {
      socket.emit('reading', result);
    });
  });
};

var emitNewReadings = function(socket, conn) {
  r.table('readings').changes().run(conn, function(err, cursor) {
    if (err) throw err;

    cursor.each(function(err, result) {
      if (err) throw err;

      if (result.new_val && !result.old_val) {
        socket.emit('reading', result.new_val);
      }
    });
  });
};

io.on('connection', function (socket) {
  r.connect({db: 'weather_balloon_tracker'}, function(err, conn) {
    emitInitialReadings(socket, conn);
    emitNewReadings(socket, conn);
  });
});