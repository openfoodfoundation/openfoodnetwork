Darkswarm.controller "MapCtrl", ($scope, MapConfiguration, OfnMap, Marker)->
  $scope.OfnMap = OfnMap
  console.log Marker
  window.Marker = Marker
  $scope.map = 
    center: 
      latitude: -37.775757
      longitude: 144.743663
    zoom: 8
    styles: MapConfiguration.options
