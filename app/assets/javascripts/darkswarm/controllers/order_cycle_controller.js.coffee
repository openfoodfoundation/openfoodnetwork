Shop.controller "OrderCycleCtrl", ($scope, $rootScope, OrderCycle) ->
  $scope.order_cycle = OrderCycle.order_cycle
  $scope.changeOrderCycle = ->
    OrderCycle.push_order_cycle()
