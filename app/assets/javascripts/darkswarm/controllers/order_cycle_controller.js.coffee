Darkswarm.controller "OrderCycleCtrl", ($scope, $rootScope, OrderCycle, $tour) ->
  $scope.order_cycle = OrderCycle.order_cycle
  $scope.OrderCycle = OrderCycle
  $scope.changeOrderCycle = ->
    $tour.end()
    OrderCycle.push_order_cycle()

  if !OrderCycle.selected()
    $tour.start()

