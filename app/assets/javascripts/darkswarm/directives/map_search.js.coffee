Darkswarm.directive 'mapSearch', ($timeout) ->
  # Install a basic search field in a map
  restrict: 'E'
  require: '^googleMap'
  replace: true
  template: '<input id="pac-input" placeholder="' + t('location_placeholder') + '"></input>'
  scope: {}
  link: (scope, elem, attrs, ctrl) ->
    $timeout =>
      map = ctrl.getMap()

      # Does this *really* belong here? It's not about search.
      scope.useOsmTiles map

      searchBox = scope.createSearchBox map
      scope.respondToSearch map, searchBox
      scope.biasResults map, searchBox


    scope.useOsmTiles = (map) ->
      map.mapTypes.set 'OSM', new google.maps.ImageMapType
        getTileUrl: (coord, zoom) ->
          # "Wrap" x (logitude) at 180th meridian properly
          # NB: Don't touch coord.x because coord param is by reference, and changing its x property breaks something in Google's lib
          tilesPerGlobe = 1 << zoom
          x = coord.x % tilesPerGlobe
          if x < 0
            x = tilesPerGlobe + x
          # Wrap y (latitude) in a like manner if you want to enable vertical infinite scroll
          'http://tile.openstreetmap.org/' + zoom + '/' + x + '/' + coord.y + '.png'
        tileSize: new (google.maps.Size)(256, 256)
        name: 'OpenStreetMap'
        maxZoom: 18

    scope.createSearchBox = (map) ->
      input = document.getElementById("pac-input")
      map.controls[google.maps.ControlPosition.TOP_LEFT].push input
      return new google.maps.places.SearchBox(input)

    scope.respondToSearch = (map, searchBox) ->
      google.maps.event.addListener searchBox, "places_changed", ->
        places = searchBox.getPlaces()
        for place in places when place.geometry.viewport?
          map.fitBounds place.geometry.viewport

    # Bias the SearchBox results towards places that are within the bounds of the
    # current map's viewport.
    scope.biasResults = (map, searchBox) ->
      google.maps.event.addListener map, "bounds_changed", ->
        bounds = map.getBounds()
        searchBox.setBounds bounds
