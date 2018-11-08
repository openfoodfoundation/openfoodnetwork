angular.module("admin.subscriptions").controller "AddressController", ($scope, StatusMessage, availableCountries, CountryStates) ->
  $scope.countries = availableCountries

  $scope.billStates = CountryStates.statesFor(availableCountries, $scope.subscription.bill_address.country_id)
  $scope.shipStates = CountryStates.statesFor(availableCountries, $scope.subscription.ship_address.country_id)

  $scope.$watch 'subscription.bill_address.country_id', (newCountryID) ->
    return unless newCountryID
    $scope.billStates = CountryStates.statesFor(availableCountries, newCountryID)
    unless CountryStates.addressStateMatchesCountryStates($scope.billStates, $scope.subscription.bill_address.state_id)
      $scope.subscription.bill_address.state_id = ""

  $scope.$watch 'subscription.ship_address.country_id', (newCountryID) ->
    return unless newCountryID
    $scope.shipStates = CountryStates.statesFor(availableCountries, newCountryID)
    unless CountryStates.addressStateMatchesCountryStates($scope.shipStates, $scope.subscription.ship_address.state_id)
      $scope.subscription.ship_address.state_id = ""

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
