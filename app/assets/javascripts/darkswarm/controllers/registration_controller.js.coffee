Darkswarm.controller "RegistrationCtrl", ($scope, RegistrationService, CurrentUser) ->
  $scope.current_user = CurrentUser
  
  $scope.currentStep = RegistrationService.currentStep
  $scope.select = RegistrationService.select

  $scope.steps = ['details','address']
  # ,'contact','about','images','social'

  $scope.enterprise = {}