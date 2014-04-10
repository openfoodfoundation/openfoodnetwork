Darkswarm.controller "CheckoutCtrl", ($scope, Order, storage) ->
  window.tmp = $scope
  $scope.Order = Order
  $scope.order = Order.order 
  $scope.accordion = {}

  $scope.show = (name)->
    $scope.accordion[name] = true

  storage.bind $scope, "accordion.user", { defaultValue: true}
  storage.bind $scope, "accordion.details"
  storage.bind $scope, "accordion.billing"
  storage.bind $scope, "accordion.shipping"
  storage.bind $scope, "accordion.payment"

  $scope.purchase = (event)->
    event.preventDefault()
    $scope.Order.submit()

