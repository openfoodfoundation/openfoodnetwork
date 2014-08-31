Darkswarm.controller "MapCtrl", ($scope, MapConfiguration, OfnMap)->
  $scope.OfnMap = OfnMap
  $scope.map = MapConfiguration.options
