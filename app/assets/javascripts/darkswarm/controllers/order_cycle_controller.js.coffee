Darkswarm.controller "OrderCycleCtrl", ($scope, $timeout, OrderCycle) ->
  $scope.order_cycle = OrderCycle.order_cycle
  $scope.OrderCycle = OrderCycle

  # Timeout forces this to be evaluated after everything is loaded
  # This is a hack. We should probably write our own "popover" directive
  # That takes an expression instead of a trigger, and binds to that
  $timeout =>
    if !$scope.OrderCycle.selected()
      $("#order_cycle_id").trigger("openTrigger")


Darkswarm.controller "OrderCycleChangeCtrl", ($scope, $timeout, OrderCycle, Products, Variants, Cart) ->
  # Track previous order cycle id for use with revertOrderCycle()
  $scope.previous_order_cycle_id = OrderCycle.order_cycle.order_cycle_id
  $scope.$watch 'order_cycle.order_cycle_id', (newValue, oldValue)->
    $scope.previous_order_cycle_id = oldValue

  $scope.changeOrderCycle = ->
    OrderCycle.push_order_cycle $scope.orderCycleChanged
    $timeout ->
      $("#order_cycle_id").trigger("closeTrigger")

  $scope.revertOrderCycle = ->
    $scope.order_cycle.order_cycle_id = $scope.previous_order_cycle_id

  $scope.orderCycleChanged = ->
    # push_order_cycle clears the cart server-side. Here we call Cart.clear() to clear the
    # client-side cart.
    Variants.clear()
    Cart.clear()
    Products.update()
