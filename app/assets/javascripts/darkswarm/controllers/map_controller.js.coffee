angular.module('Darkswarm').controller "MapCtrl", ($scope, MapConfiguration, OfnMap)->
  $scope.OfnMap = OfnMap
  $scope.map = angular.copy MapConfiguration.options
