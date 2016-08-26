angular.module("admin.standingOrders").controller "StandingOrderController", ($scope, StatusMessage, StandingOrder, customers, schedules, paymentMethods, shippingMethods) ->
  $scope.standingOrder = StandingOrder.standingOrder
  $scope.customers = customers
  $scope.schedules = schedules
  $scope.paymentMethods = paymentMethods
  $scope.shippingMethods = shippingMethods
  $scope.errors = {}

  $scope.save = ->
    StatusMessage.display 'progress', 'Saving...'
    $scope.standing_order_form.$setPristine()
    delete $scope.errors[k] for k, v of $scope.errors
    $scope.standingOrder.$save().then (response) ->
      StatusMessage.display 'success', 'Saved'
    , (response) ->
      StatusMessage.display 'failure', 'Oh no! I was unable to save your changes.'
      $scope.errors = response.data.errors
