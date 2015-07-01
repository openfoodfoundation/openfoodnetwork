# Usage:
# Geocoder.geocode address, (results, status) ->
#   if status == Geocoder.OK
#     console.log results[0].geometry.location
#   else
#     console.log "Error: #{status}"

Darkswarm.service "Geocoder", ->
  new class Geocoder
    OK: google.maps.GeocoderStatus.OK

    geocode: (address, callback) ->
      geocoder = new google.maps.Geocoder()
      geocoder.geocode {'address': address}, callback
