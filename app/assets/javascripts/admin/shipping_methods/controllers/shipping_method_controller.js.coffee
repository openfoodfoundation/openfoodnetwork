angular.module("admin.shipping_methods")
  .controller "shippingMethodCtrl", ($scope, ShippingMethods) ->
    $scope.findShippingMethodByID = (id) ->
      $scope.ShippingMethod = ShippingMethods.findByID(id)