Darkswarm.controller "EnterprisesCtrl", ($scope, Enterprises, Search, $document, $rootScope, HashNavigation, FilterSelectorsService, EnterpriseModal) ->
  $scope.Enterprises = Enterprises
  $scope.totalActive =  FilterSelectorsService.totalActive
  $scope.clearAll =  FilterSelectorsService.clearAll
  $scope.filterText =  FilterSelectorsService.filterText
  $scope.FilterSelectorsService =  FilterSelectorsService
  $scope.query = Search.search()
  $scope.openModal = EnterpriseModal.open
  $scope.activeTaxons = []
  $scope.show_profiles = false
  $scope.filtersActive = false

  $scope.$watch "query", (query)->
    Search.search query

  $rootScope.$on "$locationChangeSuccess", (newRoute, oldRoute) ->
    if HashNavigation.active "hubs"
      $document.scrollTo $("#hubs"), 100, 200
