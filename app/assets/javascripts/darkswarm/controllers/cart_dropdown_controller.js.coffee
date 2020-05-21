Darkswarm.controller "CartDropdownCtrl", ($scope, Cart) ->
  $scope.Cart = Cart
  $scope.showCartSidebar = false

  $scope.toggleCartSidebar = ->
    $scope.showCartSidebar = !$scope.showCartSidebar
