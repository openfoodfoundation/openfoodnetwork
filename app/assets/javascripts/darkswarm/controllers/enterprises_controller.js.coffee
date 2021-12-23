angular.module('Darkswarm').controller "EnterprisesCtrl", ($scope, $rootScope, $timeout, $location, Enterprises, Search, $document, HashNavigation, FilterSelectorsService, EnterpriseModal, enterpriseMatchesQueryFilter, distanceWithinKmFilter) ->
  $scope.Enterprises = Enterprises
  $scope.producers_to_filter = Enterprises.producers
  $scope.filterSelectors = FilterSelectorsService.createSelectors()
  $scope.query = Search.search()
  $scope.openModal = EnterpriseModal.open
  $scope.activeTaxons = []
  $scope.show_profiles = false
  $scope.show_closed = false
  $scope.filtersActive = false
  $scope.distanceMatchesShown = false
  $scope.closed_shops_loading = false
  $scope.closed_shops_loaded = false

  $scope.$watch "query", (query)->
    $scope.resetSearch(query)

  $scope.resetSearch = (query) ->
    Enterprises.flagMatching query
    Search.search query
    $rootScope.$broadcast 'enterprisesChanged'
    $scope.distanceMatchesShown = false

    $timeout ->
      Enterprises.calculateDistance query, $scope.firstNameMatch()
      $rootScope.$broadcast 'enterprisesChanged'
      $scope.closed_shops_loading = false

  $timeout ->
    if $location.search()['show_closed']?
      $scope.showClosedShops()

  $scope.$watch "filtersActive", (value) ->
    $scope.$broadcast 'filtersToggled'

  $rootScope.$on "enterprisesChanged", ->
    $scope.filterEnterprises()
    $scope.updateVisibleMatches()


  # When filter settings change, this could change which name match is at the top, or even
  # result in no matches. This affects the reference point that the distance matches are
  # calculated from, so we need to recalculate distances.
  $scope.$watch '[activeTaxons, activeProperties, shippingTypes, show_profiles, show_closed]', ->
    $timeout ->
      Enterprises.calculateDistance $scope.query, $scope.firstNameMatch()
      $rootScope.$broadcast 'enterprisesChanged'
  , true


  $rootScope.$on "$locationChangeSuccess", (newRoute, oldRoute) ->
    if HashNavigation.active "hubs"
      $document.scrollTo $("#hubs"), 100, 200


  $scope.filterEnterprises = ->
    es = Enterprises.hubs
    $scope.nameMatches = enterpriseMatchesQueryFilter(es, true)
    noNameMatches = enterpriseMatchesQueryFilter(es, false)
    $scope.distanceMatches = distanceWithinKmFilter(noNameMatches, 50)


  $scope.updateVisibleMatches = ->
    $scope.visibleMatches = if $scope.nameMatches.length == 0 || $scope.distanceMatchesShown
      $scope.nameMatches.concat $scope.distanceMatches
    else
      $scope.nameMatches


  $scope.showDistanceMatches = ->
    $scope.distanceMatchesShown = true
    $scope.updateVisibleMatches()


  $scope.firstNameMatch = ->
    if $scope.nameMatchesFiltered?
      $scope.nameMatchesFiltered[0]
    else
      undefined

  $scope.showClosedShops = ->
    unless $scope.closed_shops_loaded
      $scope.closed_shops_loading = true
      $scope.closed_shops_loaded = true
      Enterprises.loadClosedEnterprises().then ->
        $scope.resetSearch($scope.query)

    $scope.show_closed = true
    $location.search('show_closed', '1')

  $scope.hideClosedShops = ->
    $scope.show_closed = false
    $location.search('show_closed', null)
