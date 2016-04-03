var io = require('socket.io')(8050);
var r = require('rethinkdb');
var express = require('express');
var path = require('path');
var app = express();

// HTTP stuff

app.get('/', function (req, res) {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/elm.js', function (req, res) {
  res.sendFile(path.join(__dirname, 'elm.js'));
});

app.get('/readings', function (req, res) {
  res.json({ message: 'Reading logged' });
});


// Real-time stuff

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
  r.connect({db: 'tracker'}, function(err, conn) {
    emitInitialReadings(socket, conn);
    emitNewReadings(socket, conn);
  });
});

// Start the app

app.listen(8000, function () {
  console.log('Example app listening on port 8000!');
});