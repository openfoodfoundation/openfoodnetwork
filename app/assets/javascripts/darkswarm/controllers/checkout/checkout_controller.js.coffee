Darkswarm.controller "CheckoutCtrl", ($scope, storage, CheckoutFormState, Order, CurrentUser) ->
  $scope.Order = Order
  storage.bind $scope, "Order.order", {storeName: "order_#{Order.order.id}#{Order.order.user_id}"}
  $scope.order = Order.order # Ordering is important
  $scope.secrets = Order.secrets

  $scope.enabled = if CurrentUser then true else false

  $scope.purchase = (event)->
    event.preventDefault()
    $scope.Order.submit()

  $scope.CheckoutFormState = CheckoutFormState
  storage.bind $scope, "CheckoutFormState.ship_address_same_as_billing", { defaultValue: true}
