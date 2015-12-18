Darkswarm.controller "OrdersCtrl", ($scope, $rootScope, $timeout, Orders, Search, $document, HashNavigation, FilterSelectorsService, EnterpriseModal, enterpriseMatchesNameQueryFilter, distanceWithinKmFilter) ->
  $scope.Orders = Orders

  $scope.filterEnterprises = ->
    es = Enterprises.hubs
    $scope.nameMatches = enterpriseMatchesNameQueryFilter(es, true)
    $scope.distanceMatches = enterpriseMatchesNameQueryFilter(es, false)
    $scope.distanceMatches = distanceWithinKmFilter($scope.distanceMatches, 50)
