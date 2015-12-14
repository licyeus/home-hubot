require('dotenv').load()

request = require 'superagent'
moment  = require 'moment'

ONEBUSAWAY_API_KEY = process.env.ONEBUSAWAY_API_KEY

stops = {
  '26': '1_26510',
  '28': '1_26510',
  '40': '1_26510'
}

get_stop_times = (stop_id, cb) =>
  request.get("http://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/#{stop_id}.json")
    .query({ key: ONEBUSAWAY_API_KEY })
    .end (err, response) ->
      return console.log 'error!', err if err
      console.log(response.body)
      cb(response.body)

module.exports = (robot) ->
  robot.hear /^where['’]s (my|the) bus\?/i, (res) ->
    stop_id = '1_26510'

    get_stop_times stop_id, (body) =>
      trips = body.data.entry.arrivalsAndDepartures
      ['26', '28', '40'].forEach((short_name) =>
        requested_trips = trips.filter((trip) => trip.routeShortName == short_name && trip.scheduledDepartureTime >= body.currentTime)
        times = requested_trips.map((trip) => "#{moment(trip.scheduledDepartureTime).fromNow()} (#{moment(trip.scheduledDepartureTime).format('h:mma')})")
        res.send("the #{short_name} departs #{times.join(', ')}")
      )


  robot.hear /^where['’]s the ([0-9ABCDE]*)\?/i, (res) ->
    short_name = res.match[1]
    stop_id = stops[short_name]

    get_stop_times stop_id, (body) =>
      trips = body.data.entry.arrivalsAndDepartures
      requested_trips = trips.filter((trip) => trip.routeShortName == short_name)

      times = requested_trips.map((trip) => moment(trip.scheduledDepartureTime).fromNow())
      res.send("the #{short_name} departs #{times.join(', ')}")

