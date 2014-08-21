Darkswarm.controller "RegistrationCtrl", ($scope, RegistrationService, EnterpriseCreationService, availableCountries) ->
  $scope.currentStep = RegistrationService.currentStep
  $scope.select = RegistrationService.select
  $scope.enterprise = EnterpriseCreationService.enterprise
  $scope.create = EnterpriseCreationService.create

  $scope.steps = ['details','address','contact','about']
  # ,'images','social'

  $scope.countries = availableCountries

  $scope.countryHasStates = ->
    $scope.enterprise.country.states.length > 0
