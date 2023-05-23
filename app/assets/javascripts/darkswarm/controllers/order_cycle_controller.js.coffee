angular.module('Darkswarm').controller "OrderCycleCtrl", ($scope, $rootScope, $timeout, OrderCycle) ->
  $scope.order_cycle = OrderCycle.order_cycle
  $scope.OrderCycle = OrderCycle

angular.module('Darkswarm').controller "OrderCycleChangeCtrl", ($scope, $rootScope, $timeout, OrderCycle, Products, Variants, Cart, ChangeableOrdersAlert) ->
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
    Cart.reloadFinalisedLineItems()
    ChangeableOrdersAlert.reload()
    $rootScope.$broadcast 'orderCycleSelected'
    event = new CustomEvent('orderCycleSelected')
    window.dispatchEvent(event)

  $scope.closesInLessThan3Months = () ->
    moment().diff(moment(OrderCycle.orders_close_at(),  "YYYY-MM-DD HH:mm:SS Z"), 'days') > -75
