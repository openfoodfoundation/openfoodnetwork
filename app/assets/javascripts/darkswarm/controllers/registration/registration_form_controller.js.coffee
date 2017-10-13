Darkswarm.controller "RegistrationFormCtrl", ($scope, RegistrationService, EnterpriseRegistrationService) ->
  $scope.submitted = false
  $scope.isDisabled = false

  $scope.valid = (form) ->
    $scope.submitted = !form.$valid
    form.$valid

  $scope.create = (form) ->
    $scope.disableButton()
    EnterpriseRegistrationService.create($scope.enableButton) if $scope.valid(form)

  $scope.update = (nextStep, form) ->
    EnterpriseRegistrationService.update(nextStep) if $scope.valid(form)

  $scope.selectIfValid = (nextStep, form) ->
    RegistrationService.select(nextStep) if $scope.valid(form)

  $scope.disableButton = ->
    $scope.isDisabled = true

  $scope.enableButton = ->
    $scope.isDisabled = false
