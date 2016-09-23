angular.module("admin.standingOrders").controller "ProductsController", ($scope, StatusMessage) ->
  $scope.next = ->
    if $scope.standingOrder.standing_line_items.length > 0
      StatusMessage.clear()
      $scope.setView('review')
    else
      StatusMessage.display 'failure', 'Please add at least one product'

  $scope.back = -> $scope.setView('details')
