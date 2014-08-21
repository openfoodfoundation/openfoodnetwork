Darkswarm.controller "RegistrationCtrl", ($scope, $http, RegistrationService, CurrentUser, SpreeApiKey) ->
  $scope.current_user = CurrentUser
  
  $scope.currentStep = RegistrationService.currentStep
  $scope.select = RegistrationService.select

  $scope.steps = ['details','address','contact','about']
  # ,'images','social'

  $scope.enterprise =
    user_ids: [CurrentUser.id]
    email: CurrentUser.email
    address: {
      country_id: 12
      state_id: 1061493592
    }

  $scope.createEnterprise = ->
    $http(
      method: "POST"
      url: "/api/enterprises"
      data:
        enterprise: $scope.prepare($scope.enterprise)
      params:
        token: SpreeApiKey
    ).success((data) ->
      $scope.select('about')
    ).error((data) ->
      console.log angular.toJson(data)
      alert('Failed to create your enterprise.\nPlease ensure all fields are completely filled out.')
    )
    # $scope.select('about')

  $scope.prepare = (ent_obj) ->
    enterprise = {}
    for a, v of ent_obj when a isnt 'address'
      enterprise[a] = v
    enterprise.address_attributes = ent_obj.address
    enterprise
