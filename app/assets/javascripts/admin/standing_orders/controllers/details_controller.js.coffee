angular.module("admin.standingOrders").controller "DetailsController", ($scope, StatusMessage) ->
  $scope.submitted = false

  $scope.next = ->
    $scope.submitted = true
    if $scope.standing_order_details_form.$valid
      StatusMessage.clear()
      $scope.setView('products')
    else
      StatusMessage.display 'failure', 'Oops! There seems to be a problem...'
