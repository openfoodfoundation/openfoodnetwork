Darkswarm.controller "GroupPageCtrl", ($scope, enterprises, Enterprises, MapConfiguration, OfnMap) ->
  $scope.Enterprises = Enterprises

  $scope.map = angular.copy MapConfiguration.options
  $scope.mapMarkers = OfnMap.enterprise_markers enterprises
  $scope.embedded_layout = window.location.search.indexOf("embedded_shopfront=true") != -1
