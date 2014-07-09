Darkswarm.controller "ProducersCtrl", ($scope, Producers, TaxonSelector, $filter) ->
  $scope.Producers = Producers
  $scope.TaxonSelector = TaxonSelector
  $scope.filtersActive = false
  $scope.oldFiltered = []

  $scope.filteredProducers = ->
    filtered = $filter("filterProducers")(Producers.visible, $scope.query)
    if $scope.oldFiltered != filtered
      $scope.oldFiltered = filtered
      TaxonSelector.collectTaxons filtered
    filtered
