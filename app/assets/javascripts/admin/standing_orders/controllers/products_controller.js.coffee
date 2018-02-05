angular.module("admin.standingOrders").controller "ProductsController", ($scope, StatusMessage) ->
  $scope.registerNextCallback 'products', ->
    $scope.standing_order_form.$submitted = true
    if $scope.standingOrder.standing_line_items.length > 0
      $scope.standing_order_form.$setPristine()
      StatusMessage.clear()
      $scope.setView('review')
    else
      StatusMessage.display 'failure', 'Please add at least one product'

  $scope.registerBackCallback 'products', ->
    StatusMessage.clear()
    $scope.setView('address')
