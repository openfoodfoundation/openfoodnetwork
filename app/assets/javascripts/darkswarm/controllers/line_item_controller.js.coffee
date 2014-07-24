Darkswarm.controller "LineItemCtrl", ($scope)->
  $scope.$watch "line_item.quantity", (newValue, oldValue)->
    if newValue != oldValue
      $scope.Cart.orderChanged()
