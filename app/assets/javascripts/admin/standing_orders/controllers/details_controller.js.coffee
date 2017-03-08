angular.module("admin.standingOrders").controller "DetailsController", ($scope, StatusMessage) ->
  $scope.registerNextCallback 'details', ->
    $scope.standing_order_form.$submitted = true
    if $scope.standing_order_details_form.$valid
      $scope.standing_order_form.$setPristine()
      StatusMessage.clear()
      $scope.setView('address')
    else
      StatusMessage.display 'failure', t('admin.standing_orders.details.invalid_error')
