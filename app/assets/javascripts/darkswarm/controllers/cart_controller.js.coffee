Darkswarm.controller "CartCtrl", ($scope, Cart, $timeout) ->
  $scope.Cart = Cart
  initializing = true

  $scope.$watchCollection "Cart.line_items_present()", ->
    if initializing
      $timeout ->
        initializing = false
    else
      $scope.Cart.orderChanged()
