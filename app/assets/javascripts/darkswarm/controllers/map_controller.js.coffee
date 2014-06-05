Darkswarm.controller "MapCtrl", ($scope, MapConfiguration)->
  $scope.map = 
    center: 
      latitude: 45
      longitude: -73
    zoom: 8
    styles: MapConfiguration.options
