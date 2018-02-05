angular.module("admin.subscriptions").controller "ProductsController", ($scope, StatusMessage) ->
  $scope.registerNextCallback 'products', ->
    $scope.subscription_form.$submitted = true
    if $scope.subscription.subscription_line_items.length > 0
      $scope.subscription_form.$setPristine()
      StatusMessage.clear()
      $scope.setView('review')
    else
      StatusMessage.display 'failure', 'Please add at least one product'

  $scope.registerBackCallback 'products', ->
    StatusMessage.clear()
    $scope.setView('address')
