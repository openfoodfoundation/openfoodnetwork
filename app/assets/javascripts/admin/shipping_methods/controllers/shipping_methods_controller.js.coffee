angular.module("admin.shippingMethods").controller "shippingMethodsCtrl", ($scope, ShippingMethods) ->
  $scope.findShippingMethodByID = (id) ->
    $scope.ShippingMethod = ShippingMethods.findByID(id)
