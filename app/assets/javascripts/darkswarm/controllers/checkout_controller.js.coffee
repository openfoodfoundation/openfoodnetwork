angular.module("Checkout").controller "CheckoutCtrl", ($scope, $rootScope) ->
  $scope.require_ship_address = false
  $scope.shipping_method = -1
  $scope.payment_method = -1
  $scope.same_as_billing = true

  $scope.shippingMethodChanged = ->
    $scope.require_ship_address = $("#order_shipping_method_id_" + $scope.shipping_method).attr("data-require-ship-address")

  $scope.purchase = (event)->
    event.preventDefault()
    checkout.submit()
