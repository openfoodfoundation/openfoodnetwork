Darkswarm.factory 'CreditCard', ($injector, $rootScope, StripeJS, Navigation, $http, RailsFlashLoader, Loading)->
  new class CreditCard
    errors: {}
    secrets: {}

    requestToken: (secrets) ->
      secrets.name = @full_name(secrets)
      StripeJS.requestToken(secrets, @submit, t("saving_credit_card"))

    submit: =>
      params = @process_params()
      $http.put('/credit_cards/new_from_token', params )
        .success (data, status) ->
          $rootScope.$apply ->
            Loading.clear()
          Navigation.go '/account'
        .error (response, status) ->
          if response.path
            Navigation.go response.path
          else
            Loading.clear()
            @errors = response.errors
            RailsFlashLoader.loadFlash(response.flash)

    full_name: (secrets) ->
      secrets.first_name + " " + secrets.last_name

    process_params: ->
      {"exp_month": @secrets.card.exp_month,
      "exp_year": @secrets.card.exp_year,
      "last4": @secrets.card.last4,
      "token": @secrets.token,
      "cc_type": @secrets.card.brand}
