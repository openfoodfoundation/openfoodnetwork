angular.module("Checkout").controller "CheckoutCtrl", ($scope, $rootScope) ->
  $scope.require_ship_address = false
  $scope.shipping_method = -1
  $scope.payment_method = -1

  $scope.shippingMethodChanged = ->
   $scope.require_ship_address = $("#order_shipping_method_" + $scope.shipping_method).attr("data-require-ship-address")

