Darkswarm.controller "OrdersCtrl", ($scope, $rootScope, $timeout, Orders, Search, $document, HashNavigation, FilterSelectorsService, EnterpriseModal, enterpriseMatchesNameQueryFilter, distanceWithinKmFilter) ->
  $scope.Orders = Orders
