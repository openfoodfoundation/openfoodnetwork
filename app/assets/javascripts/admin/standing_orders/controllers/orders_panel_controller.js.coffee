angular.module("admin.standingOrders").controller "OrdersPanelController", ($scope, OrderCycles) ->
  $scope.standingOrder = $scope.object
  $scope.orderCyclesByID = OrderCycles.byID
