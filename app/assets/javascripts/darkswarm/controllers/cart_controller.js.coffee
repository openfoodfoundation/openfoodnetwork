angular.module('Darkswarm').controller "CartCtrl", ($scope, Cart, CurrentHub) ->
  $scope.Cart = Cart
  $scope.CurrentHub = CurrentHub
  $scope.max_characters = 20
