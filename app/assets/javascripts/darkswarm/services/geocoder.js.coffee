# Usage:
# Geo.geocode address, (results, status) ->
#   if status == Geo.OK
#     console.log results[0].geometry.location
#   else
#     console.log "Error: #{status}"

Darkswarm.service "Geo", ->
  new class Geo
    OK: google.maps.GeocoderStatus.OK

    geocode: (address, callback) ->
      geocoder = new google.maps.Geocoder()
      geocoder.geocode {'address': address}, callback

    distanceBetween: (locatable, location) ->
      latLng = new google.maps.LatLng locatable.latitude, locatable.longitude
      google.maps.geometry.spherical.computeDistanceBetween latLng, results[0].geometry.location
