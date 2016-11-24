angular.module("admin.standingOrders").controller "StandingOrderController", ($scope, StatusMessage, StandingOrder, customers, schedules, paymentMethods, shippingMethods) ->
  $scope.standingOrder = StandingOrder.standingOrder
  $scope.customers = customers
  $scope.schedules = schedules
  $scope.paymentMethods = paymentMethods
  $scope.shippingMethods = shippingMethods
  $scope.errors = StandingOrder.errors
  $scope.newItem = { variant_id: 0, quantity: 1 }
  $scope.distributor_id = $scope.standingOrder.shop_id # variant selector requires distributor_id
  $scope.view = if $scope.standingOrder.id? then 'review' else 'details'

  $scope.save = ->
    $scope.standing_order_form.$setPristine()
    if $scope.standingOrder.id?
      StandingOrder.update()
    else
      StandingOrder.create()

  $scope.setView = (view) -> $scope.view = view

  $scope.stepTitleFor = (step) -> t("admin.standing_orders.steps.#{step}")

  $scope.addStandingLineItem = ->
    $scope.standing_order_form.$setDirty()
    $scope.standingOrder.buildItem($scope.newItem)

  $scope.removeStandingLineItem = (item) ->
    if confirm(t('are_you_sure'))
      $scope.standing_order_form.$setDirty()
      $scope.standingOrder.removeItem(item)

  $scope.estimatedSubtotal = ->
    $scope.standingOrder.standing_line_items.reduce (subtotal, item) ->
      subtotal += item.price_estimate * item.quantity
    , 0

  $scope.estimatedTotal = ->
    $scope.estimatedSubtotal()
