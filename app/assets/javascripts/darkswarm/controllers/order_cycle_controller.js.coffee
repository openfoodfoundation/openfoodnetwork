Darkswarm.controller "OrderCycleCtrl", ($scope, OrderCycle, $timeout) ->
  $scope.order_cycle = OrderCycle.order_cycle
  $scope.OrderCycle = OrderCycle

  # Timeout forces this to be evaluated after everything is loaded
  # This is a hack. We should probably write our own "popover" directive
  # That takes an expression instead of a trigger, and binds to that
  $timeout =>
    if !$scope.OrderCycle.selected()
      $("#order_cycle_id").trigger("openTrigger") 


Darkswarm.controller "OrderCycleChangeCtrl", ($scope, OrderCycle, Product, $timeout) ->
  $scope.changeOrderCycle = ->
    OrderCycle.push_order_cycle Product.update
    $timeout ->
      $("#order_cycle_id").trigger("closeTrigger") 
