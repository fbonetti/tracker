require('dotenv').config();

var io = require('socket.io')(8001);
var r = require('rethinkdb');
var express = require('express');
var path = require('path');
var bodyParser = require('body-parser')
var app = express();

app.use(bodyParser.urlencoded({
  extended: true
}));

// HTTP stuff

app.get('/', function (req, res) {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/elm.js', function (req, res) {
  res.sendFile(path.join(__dirname, 'elm.js'));
});

app.post('/readings', function (req, res) {
  if (req.query.token != process.env.API_TOKEN) {
    res.status(401);
    return;
  }

  var values = req.body.Body.split(',');
  var reading = {
    latitude: parseFloat(values[0]),
    longitude: parseFloat(values[1]),
    courseDeg: parseFloat(values[2]),
    altitude: parseFloat(values[3]),
    speed: parseFloat(values[4]),
    timestamp: Math.round(Date.parse(values[5]) / 1000)
  };

  r.connect({db: 'tracker'}, function(err, conn) {
    if (err) {
      res.status(500);
      res.send({ message: err.message })
    } else {
      r.table("readings").insert(reading).run(conn, function(obj) {
        console.log('New reading inserted: ', JSON.stringify(reading));
        res.send({ message: 'New reading inserted' });
      });
    }

    conn.close();
  });
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