angular.module("Checkout").controller "CheckoutCtrl", ($scope, $rootScope, order) ->
  $scope.require_ship_address = false
  $scope.order = order

  
  # Our shipping_methods comes through as a hash like so: {id: requires_shipping_address}
  # Here we default to the first shipping method if none is selected
  $scope.order.shipping_method_id ||= Object.keys(order.shipping_methods)[0]
  $scope.order.ship_address_same_as_billing ||= true
  $scope.require_ship_address = $scope.order.shipping_methods[$scope.order.shipping_method_id]
 
  $scope.shippingMethodChanged = ->
    $scope.require_ship_address = $scope.order.shipping_methods[$scope.order.shipping_method_id] 


  $scope.purchase = (event)->
    event.preventDefault()
    checkout.submit()
