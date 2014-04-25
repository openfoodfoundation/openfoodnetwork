Darkswarm.controller "CheckoutCtrl", ($scope, Order, storage, CheckoutFormState) ->

  # We put Order.order into the scope for convenience
  # However, storage.bind replaces Order.order
  # So we must put Order.order into the scope AFTER it's bound to localStorage
  $scope.Order = Order
  storage.bind $scope, "Order.order", {storeName: "order_#{Order.order.id}"}
  $scope.order = Order.order

  $scope.CheckoutFormState = CheckoutFormState
  #$scope.order = Order.order 
  $scope.accordion = {user: true}

  $scope.show = (name)->
    $scope.accordion[name] = true

  storage.bind $scope, "accordion", {storeName: "accordion_#{$scope.order.id}"}
  storage.bind $scope, "CheckoutFormState.ship_address_same_as_billing", { defaultValue: true}

  $scope.purchase = (event)->
    event.preventDefault()
    $scope.Order.submit()
