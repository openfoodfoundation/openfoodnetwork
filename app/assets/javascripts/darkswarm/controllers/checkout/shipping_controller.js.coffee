angular.module('Darkswarm').controller "ShippingCtrl", ($scope, $timeout, ShippingMethods, $controller) ->
  angular.extend this, $controller('FieldsetMixin', {$scope: $scope})

  $scope.ShippingMethods = ShippingMethods
  $scope.name = "shipping"
  $scope.nextPanel = "payment"

  $scope.summary = ->
    [$scope.Checkout.shippingMethod()?.name]
  
  $timeout $scope.onTimeout 
