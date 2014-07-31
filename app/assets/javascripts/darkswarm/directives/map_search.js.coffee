Darkswarm.directive 'mapSearch', ($timeout)->
  # Install a basic search field in a map
  restrict: 'E'
  require: '^googleMap'
  replace: true
  template: '<input id="pac-input" placeholder="Type in a location..."></input>' 
  link: (scope, elem, attrs, ctrl)->
    $timeout =>
      map = ctrl.getMap()
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

