Darkswarm.controller "RegistrationCtrl", ($scope, RegistrationService, EnterpriseRegistrationService, availableCountries) ->
  $scope.currentStep = RegistrationService.currentStep
  $scope.enterprise = EnterpriseRegistrationService.enterprise
  $scope.select = RegistrationService.select

  $scope.steps = ['details', 'contact', 'type', 'about', 'images', 'social']

  $scope.countries = availableCountries

  $scope.countryHasStates = ->
    $scope.enterprise.country.states.length > 0
