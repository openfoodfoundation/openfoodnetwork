Darkswarm.controller "ProducersCtrl", ($scope, Producers, $filter, FilterSelectorsService, Search) ->
  $scope.Producers = Producers
  $scope.totalActive =  FilterSelectorsService.totalActive
  $scope.clearAll =  FilterSelectorsService.clearAll
  $scope.filterText =  FilterSelectorsService.filterText
  $scope.filtersActive = true
  $scope.activeTaxons = []
  $scope.query = Search.search()

  $scope.$watch "query", (query)->
    Search.search query
    
     

