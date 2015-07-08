Darkswarm.controller "EnterprisesCtrl", ($scope, $rootScope, Enterprises, Search, $document, HashNavigation, FilterSelectorsService, EnterpriseModal, visibleFilter, taxonsFilter, shippingFilter, showHubProfilesFilter, enterpriseMatchesNameQueryFilter, distanceWithinKmFilter) ->
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
    $rootScope.$broadcast 'enterprisesChanged'
    $scope.distanceMatchesShown = false


  $rootScope.$on "enterprisesChanged", ->
    $scope.filterEnterprises()
    $scope.updateVisibleMatches()


  $rootScope.$on "$locationChangeSuccess", (newRoute, oldRoute) ->
    if HashNavigation.active "hubs"
      $document.scrollTo $("#hubs"), 100, 200


  $scope.filterEnterprises = ->
    es = Enterprises.hubs
    $scope.nameMatches = enterpriseMatchesNameQueryFilter(es, true)
    $scope.distanceMatches = enterpriseMatchesNameQueryFilter(es, false)
    $scope.distanceMatches = distanceWithinKmFilter($scope.distanceMatches, 50)


  $scope.updateVisibleMatches = ->
    $scope.visibleMatches = if $scope.nameMatches.length == 0 || $scope.distanceMatchesShown
      $scope.nameMatches.concat $scope.distanceMatches
    else
      $scope.nameMatches



  $scope.showDistanceMatches = ->
    $scope.distanceMatchesShown = true
    $scope.updateVisibleMatches()