Darkswarm.controller "GroupEnterprisesCtrl", ($scope, Search, FilterSelectorsService, EnterpriseBox) ->
  $scope.filterSelectors = FilterSelectorsService.createSelectors()
  $scope.query = Search.search()
  $scope.openModal = EnterpriseBox.open
  $scope.activeTaxons = []
  $scope.show_profiles = false
  $scope.filtersActive = false

  $scope.$watch "query", (query)->
    Search.search query

  $scope.$watch "filtersActive", (value) ->
    $scope.$broadcast 'filtersToggled'
