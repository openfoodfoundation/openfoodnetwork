angular.module("admin.standingOrders").controller "DetailsController", ($scope, $http, CreditCardResource, StatusMessage) ->
  $scope.cardRequired = false

  $scope.registerNextCallback 'details', ->
    $scope.standing_order_form.$submitted = true
    if $scope.standing_order_details_form.$valid
      $scope.standing_order_form.$setPristine()
      StatusMessage.clear()
      $scope.setView('address')
    else
      StatusMessage.display 'failure', t('admin.standing_orders.details.invalid_error')

  $scope.$watch "standingOrder.customer_id", (newValue, oldValue) ->
    return if !newValue?
    $scope.loadAddresses(newValue) unless $scope.standingOrder.id?
    $scope.loadCreditCards(newValue)

  $scope.$watch "standingOrder.payment_method_id", (newValue, oldValue) ->
    return if !newValue?
    paymentMethod = ($scope.paymentMethods.filter (pm) -> pm.id == newValue)[0]
    return unless paymentMethod?
    if paymentMethod.type == "Spree::Gateway::StripeConnect"
      $scope.cardRequired = true
    else
      $scope.cardRequired = false
      $scope.standingOrder.credit_card_id = null

  $scope.loadAddresses = (customer_id) ->
    $http.get("/admin/customers/#{customer_id}/addresses")
    .success (response) =>
      delete response.bill_address.id
      delete response.ship_address.id
      angular.extend($scope.standingOrder.bill_address, response.bill_address)
      angular.extend($scope.standingOrder.ship_address, response.ship_address)
      $scope.shipAddressFromBilling() unless response.ship_address.address1?

  $scope.loadCreditCards = (customer_id) ->
    $scope.creditCards = CreditCardResource.index(customer_id: customer_id)
