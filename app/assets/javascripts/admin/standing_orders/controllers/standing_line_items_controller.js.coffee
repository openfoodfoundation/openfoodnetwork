angular.module("admin.standingOrders").controller "StandingLineItemsController", ($scope) ->
  $scope.newItem = { variant_id: 0, quantity: 1 }

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
