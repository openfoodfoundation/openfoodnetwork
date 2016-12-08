angular.module("admin.standingOrders").controller "ProductsController", ($scope, StatusMessage) ->
  $scope.registerNextCallback 'products', ->
    if $scope.standingOrder.standing_line_items.length > 0
      StatusMessage.clear()
      $scope.setView('review')
    else
      StatusMessage.display 'failure', 'Please add at least one product'

  $scope.registerBackCallback 'products', ->
    StatusMessage.clear()
    $scope.setView('address')
