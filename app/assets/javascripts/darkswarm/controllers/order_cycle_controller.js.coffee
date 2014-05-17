Darkswarm.controller "OrderCycleCtrl", ($scope, $rootScope, OrderCycle, $timeout) ->
  $scope.order_cycle = OrderCycle.order_cycle
  $scope.OrderCycle = OrderCycle

  $scope.changeOrderCycle = ->
    OrderCycle.push_order_cycle()
    $timeout ->
      $("#order_cycle_id").trigger("closeTrigger") 

  # Timeout forces this to be evaluated after everything is loaded
  # This is a hack. We should probably write our own "popover" directive
  # That takes an expression instead of a trigger, and binds to that
  $timeout =>
    if !$scope.OrderCycle.selected()
      $("#order_cycle_id").trigger("openTrigger") 
