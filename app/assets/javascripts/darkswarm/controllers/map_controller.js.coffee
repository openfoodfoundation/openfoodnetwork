Darkswarm.controller "MapCtrl", ($scope, MapConfiguration, OfnMap)->
  $scope.OfnMap = OfnMap
  $scope.map = 
    center: 
      latitude: -37.775757
      longitude: 144.743663
    zoom: 8
    styles: MapConfiguration.options

