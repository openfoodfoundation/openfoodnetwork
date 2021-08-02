angular.module('Darkswarm').controller "RegistrationCtrl", ($scope, RegistrationService, EnterpriseRegistrationService, availableCountries, GmapsGeo) ->
  $scope.currentStep = RegistrationService.currentStep
  $scope.enterprise = EnterpriseRegistrationService.enterprise
  $scope.select = RegistrationService.select
  $scope.geocodedAddress = ''
  $scope.latLong = null
  $scope.addressConfirmed = false
  $scope.steps = ['details', 'contact', 'type', 'about', 'images', 'social']

  # Filter countries without states since the form requires a state to be selected.
  # Consider changing the form to require a state only if a country requires them (Spree option).
  # Invalid countries still need to be filtered (better server-side).
  $scope.countries = availableCountries.filter (country) ->
    country.states.length > 0

  $scope.countriesById = $scope.countries.reduce (obj, country) ->
    obj[country.id] = country
    obj
  , {}

  $scope.setDefaultCountry = (id) ->
    country = $scope.countriesById[id]
    $scope.enterprise.country = country if country

  $scope.countryHasStates = ->
    $scope.enterprise.country.states.length > 0

  $scope.map = {center: {latitude: 0.000000, longitude: 0.000000 }, zoom: 1}
  $scope.options = {scrollwheel: false}
  $scope.locateAddress = () ->
    { address1, address2, city, state_id, zipcode } = $scope.enterprise.address
    addressQuery = [address1, address2, city, state_id, zipcode].filter((value) => !!value).join(", ")
    GmapsGeo.geocode addressQuery, (results, status) =>
      $scope.geocodedAddress = results && results[0]?.formatted_address
      location = results[0]?.geometry?.location
      if location
        $scope.$apply(() =>
          $scope.latLong = {latitude: location.lat(), longitude: location.lng()}
          $scope.map = {center: {latitude: location.lat(), longitude: location.lng()}, zoom: 16 }
        )

  $scope.toggleAddressConfirmed = ->
    $scope.addressConfirmed = !$scope.addressConfirmed
    if $scope.addressConfirmed
      $scope.enterprise.address.latitude = $scope.latLong.latitude
      $scope.enterprise.address.longitude = $scope.latLong.longitude
    else
      $scope.enterprise.address.latitude = null
      $scope.enterprise.address.longitude = null
