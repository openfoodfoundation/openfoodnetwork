angular.module("admin.standingOrders").controller "DetailsController", ($scope, StatusMessage) ->
  $scope.submitted = false

  $scope.registerNextCallback 'details', ->
    $scope.submitted = true
    if $scope.standing_order_details_form.$valid
      StatusMessage.clear()
      $scope.setView('address')
    else
      StatusMessage.display 'failure', t('admin.standing_orders.details.invalid_error')
