Darkswarm.controller "ShippingCtrl", ($scope, $timeout) ->
  angular.extend(this, new FieldsetMixin($scope))
  $scope.name = "shipping"
  $scope.nextPanel = "payment"
  
  $timeout $scope.onTimeout 
