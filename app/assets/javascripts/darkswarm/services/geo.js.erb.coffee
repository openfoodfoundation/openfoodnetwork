Darkswarm.service "Geo", ->
  new class Geo
    OK: google.maps.GeocoderStatus.OK

    # Usage:
    # Geo.geocode address, (results, status) ->
    #   if status == Geo.OK
    #     console.log results[0].geometry.location
    #   else
    #     console.log "Error: #{status}"
    geocode: (address, callback) ->
      geocoder = new google.maps.Geocoder()
      geocoder.geocode {'address': address, 'region': "<%= Spree::Country.find_by_id(Spree::Config[:default_country_id]).iso %>"}, callback

    distanceBetween: (src, dst) ->
      google.maps.geometry.spherical.computeDistanceBetween @toLatLng(src), @toLatLng(dst)

    # Wrap an object in a google.maps.LatLng if it has not been already
    toLatLng: (locatable) ->
      if locatable.lat?
        locatable
      else
        new google.maps.LatLng locatable.latitude, locatable.longitude