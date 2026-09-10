angular.module('Darkswarm').controller "CartDropdownCtrl", ($scope, Cart, BodyScroll) ->
  $scope.Cart = Cart
  $scope.showCartSidebar = false

  $scope.toggleCartSidebar = ->
    $scope.showCartSidebar = !$scope.showCartSidebar
    BodyScroll.toggle()
