require 'rethinkdb'
require 'date'
include RethinkDB::Shortcuts

r.connect(:host=>"localhost", :port=>28015).repl

start_lat = 42.1
start_lng = -87.6

12.times do
  start_lat += ((0.01)..(0.1)).step(0.01).to_a.sample
  start_lng -= ((0.01)..(0.1)).step(0.01).to_a.sample

  r.db("tracker").table("readings").insert(
    latitude: start_lat,
    longitude: start_lng,
    timestamp: Time.now
  ).run

  sleep 2
end
