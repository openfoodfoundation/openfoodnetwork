angular.module("admin.standingOrders").controller "StandingOrdersController", ($scope, StandingOrders, Columns) ->
  $scope.standingOrders = StandingOrders.index({ams_prefix: 'index'}) # {enterprise_id: $scope.shop_id}
  $scope.columns = Columns.columns
