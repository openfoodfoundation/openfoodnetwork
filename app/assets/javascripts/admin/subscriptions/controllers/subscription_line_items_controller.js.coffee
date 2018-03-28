angular.module("admin.subscriptions").controller "SubscriptionLineItemsController", ($scope, InfoDialog) ->
  $scope.newItem = { variant_id: 0, quantity: 1 }

  $scope.addSubscriptionLineItem = ->
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

  $scope.removeSubscriptionLineItem = (item) ->
    $scope.subscription_form.$setDirty()
    $scope.subscription.removeItem(item)

  $scope.match = ->
    matching = $scope.subscription.subscription_line_items.filter (sli) ->
      sli.variant_id == $scope.newItem.variant_id
    return matching[0] if matching.length > 0
    null
