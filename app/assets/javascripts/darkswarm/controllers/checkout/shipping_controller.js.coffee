Darkswarm.controller "ShippingCtrl", ($scope, $timeout, ShippingMethods) ->
  angular.extend(this, new FieldsetMixin($scope))
  $scope.ShippingMethods = ShippingMethods
  $scope.name = "shipping"
  $scope.nextPanel = "payment"
  
  $timeout $scope.onTimeout 
