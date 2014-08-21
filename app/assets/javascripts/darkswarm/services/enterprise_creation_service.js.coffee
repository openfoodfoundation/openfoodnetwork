Darkswarm.factory "EnterpriseCreationService", ($http, RegistrationService, CurrentUser, SpreeApiKey, availableCountries) ->
  new class EnterpriseCreationService
    enterprise:
      user_ids: [CurrentUser.id]
      email: CurrentUser.email
      address: {}
      country: availableCountries[0]

    create: =>
      $http(
        method: "POST"
        url: "/api/enterprises"
        data:
          enterprise: @prepare()
        params:
          token: SpreeApiKey
      ).success((data) ->
        RegistrationService.select('about')
      ).error((data) ->
        console.log angular.toJson(data)
        alert('Failed to create your enterprise.\nPlease ensure all fields are completely filled out.')
      )
      # RegistrationService.select('about')

    prepare: =>
      enterprise = {}
      for a, v of @enterprise when a isnt 'address' && a isnt 'country'
        enterprise[a] = v
      enterprise.address_attributes = @enterprise.address
      enterprise.address_attributes.country_id = @enterprise.country.id
      enterprise