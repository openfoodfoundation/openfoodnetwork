Darkswarm.controller "CartCtrl", ($scope, Cart) ->
  $scope.Cart = Cart
  $scope.$watchCollection "Cart.line_items_present()", ->
    $scope.Cart.orderChanged()
