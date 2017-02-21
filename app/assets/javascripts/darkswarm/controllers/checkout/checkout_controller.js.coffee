Darkswarm.controller "CheckoutCtrl", ($scope, localStorageService, Checkout, CurrentUser, CurrentHub) ->
  $scope.Checkout = Checkout
  $scope.submitted = false

  # Bind to local storage
  $scope.fieldsToBind = ["bill_address", "email", "payment_method_id", "shipping_method_id", "ship_address"]
  prefix = "order_#{Checkout.order.id}#{CurrentUser.id or ""}#{CurrentHub.hub.id}"

  for field in $scope.fieldsToBind
    localStorageService.bind $scope, "Checkout.order.#{field}", Checkout.order[field], "#{prefix}_#{field}"

  localStorageService.bind $scope, "Checkout.ship_address_same_as_billing", true, "#{prefix}_sameasbilling"
  localStorageService.bind $scope, "Checkout.default_bill_address", false, "#{prefix}_defaultasbilladdress"
  localStorageService.bind $scope, "Checkout.default_ship_address", false, "#{prefix}_defaultasshipaddress"

  $scope.order = Checkout.order # Ordering is important
  $scope.secrets = Checkout.secrets

  $scope.enabled = !!CurrentUser.id?

  $scope.purchase = (event, form) ->
    event.preventDefault()
    $scope.submitted = true
    if form.$valid
      $scope.Checkout.purchase()
    else
      $scope.$broadcast 'purchaseFormInvalid', form
