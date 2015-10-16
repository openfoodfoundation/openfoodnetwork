Darkswarm.controller "LineItemCtrl", ($scope)->
  $scope.$watch '[line_item.quantity, line_item.max_quantity]', (newValue, oldValue)->
    if newValue != oldValue
      $scope.Cart.orderChanged()
  , true