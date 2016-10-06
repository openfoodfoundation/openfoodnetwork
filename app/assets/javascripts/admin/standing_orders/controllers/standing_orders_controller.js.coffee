angular.module("admin.standingOrders").controller "StandingOrdersController", ($scope, StandingOrders) ->
  $scope.standingOrders = StandingOrders.index {} # {enterprise_id: $scope.shop_id}
