Darkswarm.controller "OrderCycleCtrl", ($scope, $rootScope, OrderCycle) ->
  $scope.order_cycle = OrderCycle.order_cycle
  $scope.OrderCycle = OrderCycle
  $scope.changeOrderCycle = ->
    OrderCycle.push_order_cycle()
