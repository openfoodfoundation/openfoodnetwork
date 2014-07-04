Darkswarm.controller "ProducersCtrl", ($scope, Producers, TaxonSelector) ->
  $scope.Producers = Producers
  $scope.TaxonSelector = TaxonSelector
  $scope.filtersActive = false
