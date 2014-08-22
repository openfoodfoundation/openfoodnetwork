Darkswarm.factory "EnterpriseRegistrationService", ($http, RegistrationService, CurrentUser, SpreeApiKey, Loading, availableCountries) ->
  new class EnterpriseRegistrationService
    enterprise:
      user_ids: [CurrentUser.id]
      email: CurrentUser.email
      address: {}
      country: availableCountries[0]

    create: =>
      # Loading.message = "Creating " + @enterprise.name
      # $http(
      #   method: "POST"
      #   url: "/api/enterprises"
      #   data:
      #     enterprise: @prepare()
      #   params:
      #     token: SpreeApiKey
      # ).success((data) =>
      #   Loading.clear()
      #   @enterprise.id = data
      #   RegistrationService.select('about')
      # ).error((data) =>
      #   Loading.clear()
      #   console.log angular.toJson(data)
      #   alert('Failed to create your enterprise.\nPlease ensure all fields are completely filled out.')
      # )
      RegistrationService.select('about')

    update: (step) =>
      # Loading.message = "Updating " + @enterprise.name
      # $http(
      #   method: "PUT"
      #   url: "/api/enterprises/#{@enterprise.id}"
      #   data:
      #     enterprise: @prepare()
      #   params:
      #     token: SpreeApiKey
      # ).success((data) ->
      #   Loading.clear()
      #   RegistrationService.select(step)
      # ).error((data) ->
      #   Loading.clear()
      #   console.log angular.toJson(data)
      #   alert('Failed to create your enterprise.\nPlease ensure all fields are completely filled out.')
      # )
      RegistrationService.select(step)

    prepare: =>
      enterprise = {}
      for a, v of @enterprise when a isnt 'address' && a isnt 'country' && a isnt 'id'
        enterprise[a] = v
      enterprise.address_attributes = @enterprise.address
      enterprise.address_attributes.country_id = @enterprise.country.id
      enterprise