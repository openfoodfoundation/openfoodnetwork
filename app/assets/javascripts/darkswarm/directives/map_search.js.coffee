angular.module('Darkswarm').directive 'mapSearch', ($timeout, Search) ->
  # Install a basic search field in a map
  restrict: 'E'
  require: ['^uiGmapGoogleMap', 'ngModel']
  replace: true
  template: '<input id="pac-input" ng-model="query" placeholder="' + t('location_placeholder') + '" onfocus="this.select()"></input>'
  scope: {}

  controller: ($scope) ->
    $scope.query = Search.search()

    $scope.$watch 'query', (query) ->
      Search.search query


  link: (scope, elem, attrs, ctrls) ->
    [ctrl, model] = ctrls
    scope.input = document.getElementById("pac-input")

    $timeout =>
      map = ctrl.getMap()

      if !map
        alert(t('gmap_load_failure'))
      else
        searchBox = scope.createSearchBox map
        scope.bindSearchResponse map, searchBox
        scope.biasResults map, searchBox
        scope.performUrlSearch map

    scope.createSearchBox = (map) ->
      map.controls[google.maps.ControlPosition.TOP_LEFT].push scope.input
      return new google.maps.places.SearchBox(scope.input)

    scope.bindSearchResponse = (map, searchBox) ->
      google.maps.event.addListener searchBox, "places_changed", =>
        scope.showSearchResult map, searchBox

    scope.showSearchResult = (map, searchBox) ->
      places = searchBox.getPlaces()
      for place in places when place.geometry.viewport?
        map.fitBounds place.geometry.viewport
        scope.$apply ->
          model.$setViewValue elem.val()

    # When the map loads, and we have a search from ?query, perform that search
    scope.performUrlSearch = (map) ->
      google.maps.event.addListenerOnce map, "idle", =>
        google.maps.event.trigger(scope.input, 'focus',{});
        google.maps.event.trigger(scope.input, 'keydown', {keyCode: 13});

    # Bias the SearchBox results towards places that are within the bounds of the
    # current map's viewport.
    scope.biasResults = (map, searchBox) ->
      google.maps.event.addListener map, "bounds_changed", ->
        bounds = map.getBounds()
        searchBox.setBounds bounds
