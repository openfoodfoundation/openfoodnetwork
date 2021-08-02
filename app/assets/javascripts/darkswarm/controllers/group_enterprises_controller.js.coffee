angular.module('Darkswarm').controller "GroupEnterprisesCtrl", ($scope, Search, FilterSelectorsService, EnterpriseModal) ->
  $scope.filterSelectors = FilterSelectorsService.createSelectors()
  $scope.query = Search.search()
  $scope.openModal = EnterpriseModal.open
  $scope.activeTaxons = []
  $scope.show_profiles = false
  $scope.filtersActive = false

  $scope.$watch "query", (query)->
    Search.search query

  $scope.$watch "filtersActive", (value) ->
    $scope.$broadcast 'filtersToggled'
