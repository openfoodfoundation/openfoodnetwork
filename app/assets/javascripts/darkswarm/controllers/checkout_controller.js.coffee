Darkswarm.controller "CheckoutCtrl", ($scope, $rootScope, Order, storage) ->
  $scope.order = $scope.Order = Order

  # Binding accordion panel states to local storage
  storage.bind $scope, "user", { defaultValue: true }
  storage.bind $scope, "details"
  storage.bind $scope, "billing"
  storage.bind $scope, "shipping"
  storage.bind $scope, "payment"

  $scope.purchase = (event)->
    event.preventDefault()
    checkout.submit()
