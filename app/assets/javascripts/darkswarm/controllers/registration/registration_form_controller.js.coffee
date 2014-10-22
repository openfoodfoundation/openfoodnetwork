Darkswarm.controller "RegistrationFormCtrl", ($scope, RegistrationService, EnterpriseRegistrationService) ->
  $scope.submitted = false

  $scope.valid = (form) ->
    $scope.submitted = !form.$valid
    form.$valid

  $scope.create = (form) ->
    EnterpriseRegistrationService.create() if $scope.valid(form)

  $scope.update = (nextStep, form) ->
    EnterpriseRegistrationService.update(nextStep) if $scope.valid(form)

  $scope.selectIfValid = (nextStep, form) ->
    RegistrationService.select(nextStep) if $scope.valid(form)
