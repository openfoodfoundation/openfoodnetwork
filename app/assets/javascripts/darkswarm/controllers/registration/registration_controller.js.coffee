Darkswarm.controller "RegistrationCtrl", ($scope, RegistrationService, EnterpriseRegistrationService, availableCountries) ->
  $scope.currentStep = RegistrationService.currentStep
  $scope.enterprise = EnterpriseRegistrationService.enterprise
  $scope.select = RegistrationService.select

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
