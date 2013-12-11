Shop.controller "OrderCycleCtrl", ($scope, $rootScope, OrderCycle) ->
  $scope.order_cycle = OrderCycle.order_cycle
  $scope.changeOrderCycle = ->
    OrderCycle.set_order_cycle()
