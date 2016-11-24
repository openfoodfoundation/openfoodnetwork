angular.module("admin.standingOrders").controller "StandingLineItemsController", ($scope, InfoDialog) ->
  $scope.newItem = { variant_id: 0, quantity: 1 }

  $scope.addStandingLineItem = ->
    existing_ids = $scope.standingOrder.standing_line_items.map (sli) -> sli.variant_id
    if $scope.newItem.variant_id in existing_ids
      InfoDialog.open 'error', t('admin.standing_orders.product_already_in_order')
    else
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
