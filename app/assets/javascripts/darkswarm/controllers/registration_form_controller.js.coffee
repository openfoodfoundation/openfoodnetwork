Darkswarm.controller "RegistrationFormCtrl", ($scope, RegistrationService, EnterpriseRegistrationService) ->
  $scope.submitted = false

  $scope.create = (form) ->
    $scope.submitted = true
    if form.$valid
      EnterpriseRegistrationService.create()
      $scope.submitted = false

  $scope.update = (nextStep, form) ->
    $scope.submitted = true
    if form.$valid
      EnterpriseRegistrationService.update(nextStep)
      $scope.submitted = false

  $scope.select = (nextStep, form) ->
    $scope.submitted = true
    if form.$valid
      RegistrationService.select(nextStep)
      $scope.submitted = false