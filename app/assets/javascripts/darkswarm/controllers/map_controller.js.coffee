Darkswarm.controller "MapCtrl", ($scope, MapConfiguration, OfnMap)->
  $scope.OfnMap = OfnMap
  $scope.map = 
    center: 
      latitude: -37.4713077
      longitude: 144.7851531
    zoom: 12
    styles: MapConfiguration.options
