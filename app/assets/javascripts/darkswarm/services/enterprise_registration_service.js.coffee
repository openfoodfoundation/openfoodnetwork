Darkswarm.factory "EnterpriseRegistrationService", ($http, RegistrationService, EnterpriseImageService, CurrentUser, spreeApiKey, Loading, availableCountries, enterpriseAttributes) ->
  new class EnterpriseRegistrationService
    enterprise:
      user_ids: [CurrentUser.id]
      email: CurrentUser.email
      email_address: CurrentUser.email
      address: {}
      country: availableCountries[0]

    constructor: ->
      for key, value of enterpriseAttributes
        @enterprise[key] = value

    create: =>
      Loading.message = t('creating') + " " + @enterprise.name
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
        EnterpriseImageService.configure(@enterprise)
        RegistrationService.select('about')
      ).error((data) =>
        Loading.clear()
        if data?.errors?
          errors = ("#{k.capitalize()} #{v[0]}" for k, v of data.errors when v.length > 0)
          alert t('failed_to_create_enterprise') + "\n" + errors.join('\n')
        else
          alert(t('failed_to_create_enterprise_unknown'))
      )

    update: (step) =>
      Loading.message = t('updating') + " " + @enterprise.name
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
        alert(t('failed_to_update_enterprise_unknown'))
      )

    prepare: =>
      enterprise = {}
      excluded = [ 'address', 'country', 'id' ]
      for key, value of @enterprise when key not in excluded
        enterprise[key] = value
      enterprise.address_attributes = @enterprise.address if @enterprise.address?
      enterprise.address_attributes.country_id = @enterprise.country.id if @enterprise.country?
      enterprise
