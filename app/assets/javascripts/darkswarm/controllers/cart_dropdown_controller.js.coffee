angular.module('Darkswarm').controller "CartDropdownCtrl", ($scope, Cart, BodyScroll, Variants, $window) ->
  $scope.Cart = Cart
  $scope.showCartSidebar = false

  $scope.toggleCartSidebar = ->
    $scope.showCartSidebar = !$scope.showCartSidebar
    BodyScroll.toggle()

  # Listening for addtocart event
  $window.addEventListener 'updateCart', (e) ->
    variant = Variants.variants[e.detail.variant.id]
    line_item = variant.line_item
    line_item.quantity = e.detail.quantity

    Cart.adjust(line_item)
