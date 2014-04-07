Darkswarm.controller "CheckoutCtrl", ($scope, $rootScope, Order) ->
  $scope.require_ship_address = false
  $scope.order = $scope.Order = Order

  $scope.shippingMethodChanged = ->
    Order.shippingMethodChanged()

  $scope.purchase = (event)->
    event.preventDefault()
    checkout.submit()
