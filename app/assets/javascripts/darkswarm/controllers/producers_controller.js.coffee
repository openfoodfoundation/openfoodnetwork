Darkswarm.controller "ProducersCtrl", ($scope, Producers, $filter) ->
  $scope.Producers = Producers
  $scope.filtersActive = true
  $scope.activeTaxons = []
