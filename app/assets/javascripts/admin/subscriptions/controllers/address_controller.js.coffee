angular.module("admin.subscriptions").controller "AddressController", ($scope, $filter, StatusMessage, availableCountries) ->
  $scope.countries = availableCountries
  $scope.statesFor = (country_id) ->
    return [] unless country_id
    $filter('filter')(availableCountries, {id: country_id})[0].states
  $scope.billStates = $scope.statesFor($scope.subscription.bill_address.country_id)
  $scope.shipStates = $scope.statesFor($scope.subscription.ship_address.country_id)

  $scope.registerNextCallback 'address', ->
    $scope.subscription_form.$submitted = true
    if $scope.subscription_address_form.$valid
      $scope.subscription_form.$setPristine()
      StatusMessage.clear()
      $scope.setView('products')
    else
      StatusMessage.display 'failure', t('admin.subscriptions.details.invalid_error')

  $scope.registerBackCallback 'address', ->
    StatusMessage.clear()
    $scope.setView('details')

  $scope.$watch 'subscription.bill_address.country_id', (newValue, oldValue) ->
    $scope.billStates = $scope.statesFor(newValue) if newValue?

  $scope.$watch 'subscription.ship_address.country_id', (newValue, oldValue) ->
    $scope.shipStates = $scope.statesFor(newValue) if newValue?
