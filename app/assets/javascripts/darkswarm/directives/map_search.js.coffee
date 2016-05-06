Darkswarm.directive 'mapSearch', ($timeout)->
  # Install a basic search field in a map
  restrict: 'E'
  require: '^googleMap'
  replace: true
  template: '<input id="pac-input" placeholder="' + t('location_placeholder') + '"></input>'
  link: (scope, elem, attrs, ctrl)->
    $timeout =>
      map = ctrl.getMap()

      # Use OSM tiles server
      map.mapTypes.set 'OSM', new (google.maps.ImageMapType)(
        getTileUrl: (coord, zoom) ->
          # "Wrap" x (logitude) at 180th meridian properly
          # NB: Don't touch coord.x because coord param is by reference, and changing its x property breakes something in Google's lib
          tilesPerGlobe = 1 << zoom
          x = coord.x % tilesPerGlobe
          if x < 0
            x = tilesPerGlobe + x
          # Wrap y (latitude) in a like manner if you want to enable vertical infinite scroll
          'http://tile.openstreetmap.org/' + zoom + '/' + x + '/' + coord.y + '.png'
        tileSize: new (google.maps.Size)(256, 256)
        name: 'OpenStreetMap'
        maxZoom: 18)

      input = (document.getElementById("pac-input"))
      map.controls[google.maps.ControlPosition.TOP_LEFT].push input
      searchBox = new google.maps.places.SearchBox((input))

      google.maps.event.addListener searchBox, "places_changed", ->
        places = searchBox.getPlaces()
        return if places.length is 0
        # For each place, get the icon, place name, and location.
        markers = []
        bounds = new google.maps.LatLngBounds()
        for place in places
          #map.setCenter place.geometry.location
          map.fitBounds place.geometry.viewport
        #map.fitBounds bounds

      # Bias the SearchBox results towards places that are within the bounds of the
      # current map's viewport.
      google.maps.event.addListener map, "bounds_changed", ->
        bounds = map.getBounds()
        searchBox.setBounds bounds

