angular.module("admin.standingOrders").controller "DetailsController", ($scope, StatusMessage) ->
  $scope.cardRequired = false

  $scope.registerNextCallback 'details', ->
    $scope.standing_order_form.$submitted = true
    if $scope.standing_order_details_form.$valid
      $scope.standing_order_form.$setPristine()
      StatusMessage.clear()
      $scope.setView('address')
    else
      StatusMessage.display 'failure', t('admin.standing_orders.details.invalid_error')

  $scope.$watch "standingOrder.payment_method_id", (newValue, oldValue) ->
    return if !newValue? || newValue == oldValue
    paymentMethod = ($scope.paymentMethods.filter (pm) -> pm.id == newValue)[0]
    return unless paymentMethod?
    if paymentMethod.type == "Spree::Gateway::StripeConnect"
      $scope.cardRequired = true
    else
      $scope.cardRequired = false
      $scope.standingOrder.credit_card_id = null
