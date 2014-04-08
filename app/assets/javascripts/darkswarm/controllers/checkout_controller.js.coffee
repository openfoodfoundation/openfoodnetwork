Darkswarm.controller "CheckoutCtrl", ($scope, Order, storage) ->
  $scope.order = $scope.Order = Order

  storage.bind $scope, "user", { defaultValue: true}
  $scope.disable = ->
    $scope.user = false

  storage.bind $scope, "details"
  storage.bind $scope, "billing"
  storage.bind $scope, "shipping"
  storage.bind $scope, "payment"


  $scope.purchase = (event)->
    event.preventDefault()
    checkout.submit()
