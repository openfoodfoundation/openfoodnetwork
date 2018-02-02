angular.module("admin.subscriptions").controller "StandingLineItemsController", ($scope, InfoDialog) ->
  $scope.newItem = { variant_id: 0, quantity: 1 }

  $scope.addStandingLineItem = ->
    match = $scope.match()
    if match
      if match._destroy
        angular.extend(match, $scope.newItem)
        delete match._destroy
      else
        InfoDialog.open 'error', t('admin.subscriptions.product_already_in_order')
    else
      $scope.subscription_form.$setDirty()
      $scope.subscription.buildItem($scope.newItem)

  $scope.removeStandingLineItem = (item) ->
    $scope.subscription_form.$setDirty()
    $scope.subscription.removeItem(item)

  $scope.match = ->
    matching = $scope.subscription.standing_line_items.filter (sli) ->
      sli.variant_id == $scope.newItem.variant_id
    return matching[0] if matching.length > 0
    null

  $scope.estimatedSubtotal = ->
    $scope.subscription.standing_line_items.reduce (subtotal, item) ->
      return subtotal if item._destroy
      subtotal += item.price_estimate * item.quantity
    , 0

  $scope.estimatedTotal = ->
    $scope.estimatedSubtotal()
