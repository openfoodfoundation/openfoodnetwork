Darkswarm.controller "CheckoutCtrl", ($scope, Order, storage) ->
  $scope.order = $scope.Order = Order
  #$scope.order = Order.order 
  $scope.accordion = {}

  $scope.show = (name)->
    $scope.accordion[name] = true

  storage.bind $scope, "accordion.user", { defaultValue: true}
  storage.bind $scope, "accordion.details"
  storage.bind $scope, "accordion.billing"
  storage.bind $scope, "accordion.shipping"
  storage.bind $scope, "accordion.payment"

  storage.bind $scope, "Order.formstate.ship_address_same_as_billing", { defaultValue: true}
  storage.bind $scope, "order", {storeName: "order_#{$scope.order.id}"}

  $scope.purchase = (event)->
    event.preventDefault()
    $scope.Order.submit()
