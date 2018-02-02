angular.module("admin.subscriptions").controller "DetailsController", ($scope, $http, CreditCardResource, StatusMessage) ->
  $scope.cardRequired = false

  $scope.registerNextCallback 'details', ->
    $scope.subscription_form.$submitted = true
    if $scope.subscription_details_form.$valid
      $scope.subscription_form.$setPristine()
      StatusMessage.clear()
      $scope.setView('address')
    else
      StatusMessage.display 'failure', t('admin.subscriptions.details.invalid_error')

  $scope.$watch "subscription.customer_id", (newValue, oldValue) ->
    return if !newValue?
    $scope.loadAddresses(newValue) unless $scope.subscription.id?
    $scope.loadCreditCards(newValue)

  $scope.$watch "subscription.payment_method_id", (newValue, oldValue) ->
    return if !newValue?
    paymentMethod = ($scope.paymentMethods.filter (pm) -> pm.id == newValue)[0]
    return unless paymentMethod?
    if paymentMethod.type == "Spree::Gateway::StripeConnect"
      $scope.cardRequired = true
    else
      $scope.cardRequired = false
      $scope.subscription.credit_card_id = null

  $scope.loadAddresses = (customer_id) ->
    $http.get("/admin/customers/#{customer_id}/addresses")
    .success (response) =>
      delete response.bill_address.id
      delete response.ship_address.id
      angular.extend($scope.subscription.bill_address, response.bill_address)
      angular.extend($scope.subscription.ship_address, response.ship_address)
      $scope.shipAddressFromBilling() unless response.ship_address.address1?

  $scope.loadCreditCards = (customer_id) ->
    $scope.creditCards = CreditCardResource.index(customer_id: customer_id)
