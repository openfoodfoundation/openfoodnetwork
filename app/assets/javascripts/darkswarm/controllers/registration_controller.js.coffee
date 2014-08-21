Darkswarm.controller "RegistrationCtrl", ($scope, RegistrationService, EnterpriseRegistrationService, availableCountries) ->
  $scope.currentStep = RegistrationService.currentStep
  $scope.select = RegistrationService.select
  $scope.enterprise = EnterpriseRegistrationService.enterprise
  $scope.create = EnterpriseRegistrationService.create
  $scope.update = EnterpriseRegistrationService.update

  $scope.steps = ['details','address','contact','about','images','social']

  $scope.countries = availableCountries

  $scope.countryHasStates = ->
    $scope.enterprise.country.states.length > 0
