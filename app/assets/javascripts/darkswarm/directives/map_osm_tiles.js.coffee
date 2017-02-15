Darkswarm.directive 'mapOsmTiles', ($timeout) ->
  restrict: 'E'
  require: '^googleMap'
  scope: {}
  link: (scope, elem, attrs, ctrl) ->
    $timeout =>
      map = ctrl.getMap()

      map.mapTypes.set 'OSM', new google.maps.ImageMapType
        getTileUrl: (coord, zoom) ->
          # "Wrap" x (logitude) at 180th meridian properly
          # NB: Don't touch coord.x because coord param is by reference, and changing its x property breaks something in Google's lib
          tilesPerGlobe = 1 << zoom
          x = coord.x % tilesPerGlobe
          if x < 0
            x = tilesPerGlobe + x
          # Wrap y (latitude) in a like manner if you want to enable vertical infinite scroll
          'https://a.tile.openstreetmap.org/' + zoom + '/' + x + '/' + coord.y + '.png'
        tileSize: new google.maps.Size(256, 256)
        name: 'OpenStreetMap'
        maxZoom: 18
