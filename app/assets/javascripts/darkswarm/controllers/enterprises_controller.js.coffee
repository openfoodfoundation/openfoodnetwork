Darkswarm.controller "EnterprisesCtrl", ($scope, Enterprises, Search, $document, $rootScope, HashNavigation, FilterSelectorsService, EnterpriseModal, visibleFilter, taxonsFilter, shippingFilter, showHubProfilesFilter, enterpriseMatchesNameQueryFilter, distanceWithinKmFilter) ->
  $scope.Enterprises = Enterprises
  $scope.totalActive = FilterSelectorsService.totalActive
  $scope.clearAll = FilterSelectorsService.clearAll
  $scope.filterText = FilterSelectorsService.filterText
  $scope.FilterSelectorsService = FilterSelectorsService
  $scope.query = Search.search()
  $scope.openModal = EnterpriseModal.open
  $scope.activeTaxons = []
  $scope.show_profiles = false
  $scope.filtersActive = false
  $scope.distanceMatchesShown = false


  $scope.$watch "query", (query)->
    Enterprises.evaluateQuery query
    Search.search query
    $scope.filterEnterprises()
    $scope.distanceMatchesShown = false


  $rootScope.$on "$locationChangeSuccess", (newRoute, oldRoute) ->
    if HashNavigation.active "hubs"
      $document.scrollTo $("#hubs"), 100, 200


  $scope.filterEnterprises = ->
    es = Enterprises.hubs
    es = visibleFilter(es)
    es = taxonsFilter(es, $scope.activeTaxons)
    es = shippingFilter(es, $scope.shippingTypes)
    es = showHubProfilesFilter(es)
    $scope.nameMatches = enterpriseMatchesNameQueryFilter(es, true)
    $scope.distanceMatches = enterpriseMatchesNameQueryFilter(es, false)
    $scope.distanceMatches = distanceWithinKmFilter($scope.distanceMatches, 50)


  $scope.showDistanceMatches = ->
    $scope.distanceMatchesShown = true