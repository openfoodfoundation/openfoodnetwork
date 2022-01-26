angular.module("admin.subscriptions").controller "DetailsController", ($scope, $http, CustomerResource, StatusMessage) ->
  $scope.cardRequired = false

  $scope.registerNextCallback 'details', ->
    $scope.subscription_form.$submitted = true
    return unless $scope.validate()
    $scope.subscription_form.$setPristine()
    StatusMessage.clear()
    $scope.setView('address')

  $scope.$watch "subscription.customer_id", (newValue, oldValue) ->
    return if !newValue?
    $scope.loadCustomer(newValue) unless $scope.subscription.id?

  $scope.$watch "subscription.payment_method_id", (newValue, oldValue) ->
    return if !newValue?
    paymentMethod = ($scope.paymentMethods.filter (pm) -> pm.id == newValue)[0]
    return unless paymentMethod?
    $scope.cardRequired = paymentMethod.type == "Spree::Gateway::StripeSCA"
    $scope.loadCustomer() if $scope.cardRequired && !$scope.customer

  $scope.loadCustomer = ->
    params = { id: $scope.subscription.customer_id }
    params.ams_prefix = 'subscription' unless $scope.subscription.id
    $scope.customer = CustomerResource.get params, (response) ->
      for address in ['bill_address','ship_address']
        return unless response[address]
        delete response[address].id
        return if $scope.subscription[address].address1?
        angular.extend($scope.subscription[address], response[address])
      $scope.shipAddressFromBilling() unless response.ship_address?.address1?

  $scope.validate = ->
    return true if $scope.subscription_details_form.$valid && $scope.creditCardOk()
    StatusMessage.display 'failure', t('admin.subscriptions.details.invalid_error')
    false

  $scope.creditCardOk = ->
    return true unless $scope.cardRequired
    return false unless $scope.customer
    return false unless $scope.customer.allow_charges
    return false unless $scope.customer.default_card_present
    true
