angular.module('Darkswarm').factory "EnterpriseRegistrationService", ($http, RegistrationService, EnterpriseImageService, CurrentUser, spreeApiKey, Loading, availableCountries, enterpriseAttributes) ->
  new class EnterpriseRegistrationService
    enterprise:
      user_ids: [CurrentUser.id]
      email_address: CurrentUser.email
      address: {}
      country: availableCountries[0]

    constructor: ->
      for key, value of enterpriseAttributes
        @enterprise[key] = value

    # Creates the enterprise and redirects to the about step on success.
    #
    # @param callback [Function] executed at the end of the operation both in
    #   case of success or failure.
    create: (callback) =>
      Loading.message = t('creating') + " " + @enterprise.name
      $http(
        method: "POST"
        url: "/api/v0/enterprises"
        data:
          enterprise: @prepare()
          use_geocoder: @useGeocoder()
        params:
          token: spreeApiKey
      ).then((response) =>
        Loading.clear()
        @enterprise.id = response.data
        EnterpriseImageService.configure(@enterprise)
        RegistrationService.select('about')
      ).catch((response) =>
        Loading.clear()
        if response.data?.errors?
          errors = ("#{k.capitalize()} #{v[0]}" for k, v of response.data.errors when v.length > 0)
          alert t('failed_to_create_enterprise') + "\n" + errors.join('\n')
        else
          alert(t('failed_to_create_enterprise_unknown'))
      )
      callback.call() if callback?

    update: (step) =>
      Loading.message = t('updating') + " " + @enterprise.name
      $http(
        method: "PUT"
        url: "/api/v0/enterprises/#{@enterprise.id}"
        data:
          enterprise: @prepare()
          use_geocoder: @useGeocoder()
        params:
          token: spreeApiKey
      ).then((response) ->
        Loading.clear()
        RegistrationService.select(step)
      ).catch((response) ->
        Loading.clear()
        alert(t('failed_to_update_enterprise_unknown'))
        if response.data.errors.instagram
          igErr = document.querySelector("#instagram-error")
          igErr.style.display = 'block'
          igErr.textContent = response.data.errors.instagram[0]
      )

    prepare: =>
      enterprise = {}
      excluded = [ 'address', 'country', 'id' ]
      for key, value of @enterprise when key not in excluded
        if (key == 'long_description')
          enterprise[key] = value.replace(/(?:\r\n|\r|\n)/g, '<br>')
        else enterprise[key] = value
      enterprise.address_attributes = @enterprise.address if @enterprise.address?
      enterprise.address_attributes.country_id = @enterprise.country.id if @enterprise.country?
      enterprise

    useGeocoder: =>
      if @enterprise.address? && !@enterprise.address.latitude? && !@enterprise.address.longitude?
        return "1"
