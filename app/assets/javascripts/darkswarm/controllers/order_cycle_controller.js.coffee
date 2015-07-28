# TODO this SUCKS. Fix it

Darkswarm.controller "OrderCycleCtrl", ($scope, $timeout, OrderCycle) ->
  $scope.order_cycle = OrderCycle.order_cycle
  $scope.OrderCycle = OrderCycle

  # Timeout forces this to be evaluated after everything is loaded
  # This is a hack. We should probably write our own "popover" directive
  # That takes an expression instead of a trigger, and binds to that
  $timeout =>
    if !$scope.OrderCycle.selected()
      $("#order_cycle_id").trigger("openTrigger")


Darkswarm.controller "OrderCycleChangeCtrl", ($scope, $timeout, OrderCycle, Products, Variants) ->
  $scope.changeOrderCycle = ->
    OrderCycle.push_order_cycle $scope.orderCycleChanged
    $timeout ->
      $("#order_cycle_id").trigger("closeTrigger")

  $scope.orderCycleChanged = ->
    Variants.clear()
    Products.update()
