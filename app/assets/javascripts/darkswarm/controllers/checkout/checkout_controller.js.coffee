Darkswarm.controller "CheckoutCtrl", ($scope, storage, Checkout, CurrentUser, CurrentHub) ->
  $scope.Checkout = Checkout

  # Bind to local storage
  $scope.fieldsToBind = ["bill_address", "email", "payment_method_id", "shipping_method_id", "ship_address"]
  prefix = "order_#{Checkout.order.id}#{CurrentUser?.id}#{CurrentHub.hub.id}"

  for field in $scope.fieldsToBind
    storage.bind $scope, "Checkout.order.#{field}",
      storeName: "#{prefix}_#{field}"
  storage.bind $scope, "Checkout.ship_address_same_as_billing",
    storeName: "#{prefix}_sameasbilling"
    defaultValue: true

  $scope.order = Checkout.order # Ordering is important
  $scope.secrets = Checkout.secrets

  $scope.enabled = if CurrentUser then true else false

  $scope.purchase = (event)->
    event.preventDefault()
    $scope.Checkout.submit()
