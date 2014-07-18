Darkswarm.controller "LineItemCtrl", ($scope)->
  $scope.$watch "line_item.quantity", ->
    $scope.Cart.orderChanged()
