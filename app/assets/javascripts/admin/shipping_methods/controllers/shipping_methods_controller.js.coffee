angular.module("admin.shipping_methods")
  .controller "shippingMethodsCtrl", ($scope, ShippingMethods) ->
    $scope.findShippingMethodByID = (id) ->
      $scope.ShippingMethod = ShippingMethods.findByID(id)
