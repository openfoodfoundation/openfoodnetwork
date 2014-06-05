Darkswarm.controller "CheckoutCtrl", ($scope, storage, Order, CurrentUser) ->
  $scope.Order = Order
  Order.bindFieldsToLocalStorage($scope)

  $scope.order = Order.order # Ordering is important
  $scope.secrets = Order.secrets

  $scope.enabled = if CurrentUser then true else false

  $scope.purchase = (event)->
    event.preventDefault()
    $scope.Order.submit()
