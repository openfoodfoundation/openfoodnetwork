Darkswarm.factory "EnterpriseRegistrationService", ($http, RegistrationService, CurrentUser, spreeApiKey, Loading, availableCountries, enterpriseAttributes) ->
  new class EnterpriseRegistrationService
    enterprise:
      user_ids: [CurrentUser.id]
      email: CurrentUser.email
      address: {}
      country: availableCountries[0]

    constructor: ->
      for key, value of enterpriseAttributes
        @enterprise[key] = value

    create: =>
      Loading.message = "Creating " + @enterprise.name
      $http(
        method: "POST"
        url: "/api/enterprises"
        data:
          enterprise: @prepare()
        params:
          token: spreeApiKey
      ).success((data) =>
        Loading.clear()
        @enterprise.id = data
        RegistrationService.select('about')
      ).error((data) =>
        Loading.clear()
        alert('Failed to create your enterprise.\nPlease ensure all fields are completely filled out.')
      )
      # RegistrationService.select('about')

    update: (step) =>
      Loading.message = "Updating " + @enterprise.name
      $http(
        method: "PUT"
        url: "/api/enterprises/#{@enterprise.id}"
        data:
          enterprise: @prepare()
        params:
          token: spreeApiKey
      ).success((data) ->
        Loading.clear()
        RegistrationService.select(step)
      ).error((data) ->
        Loading.clear()
        alert('Failed to update your enterprise.\nPlease ensure all fields are completely filled out.')
      )
      # RegistrationService.select(step)

    prepare: =>
      enterprise = {}
      excluded = [ 'address', 'country', 'id' ]
      for key, value of @enterprise when key not in excluded
        enterprise[key] = value
      enterprise.address_attributes = @enterprise.address if @enterprise.address?
      enterprise.address_attributes.country_id = @enterprise.country.id if @enterprise.country?
      enterprise