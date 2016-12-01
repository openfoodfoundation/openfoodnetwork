angular.module("admin.standingOrders").controller "OrdersPanelController", ($scope, OrderCycles) ->
  $scope.standingOrder = $scope.object
  $scope.orderCyclesByID = OrderCycles.byID

  $scope.cancelOrder = (order) ->
    if confirm(t('are_you_sure'))
      $scope.standingOrder.cancelOrder(order)
