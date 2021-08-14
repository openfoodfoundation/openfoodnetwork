angular.module('Darkswarm').factory 'CreditCard', ($injector, $rootScope, CreditCards, StripeElements, Navigation, $http, Messages)->
  new class CreditCard
    visible: false
    errors: {}
    secrets: {}

    requestToken: =>
      @setFullName()
      StripeElements.requestToken(@secrets, @submit, t("saving_credit_card"))

    submit: =>
      params = @process_params()
      $http.put('/credit_cards/new_from_token', params )
        .then (response) =>
          Messages.clear()
          @reset()
          CreditCards.add(response.data)
        .catch (response) =>
          if response.data.path
            Navigation.go response.data.path
          else
            @errors = response.data.errors
            Messages.flash(response.data.flash)

    setFullName: ->
      @secrets.name = "#{@secrets.first_name} #{@secrets.last_name}"

    process_params: ->
      {"exp_month": @secrets.card.exp_month,
      "exp_year": @secrets.card.exp_year,
      "last4": @secrets.card.last4,
      "token": @secrets.token,
      "cc_type": @secrets.cc_type}

    show: => @visible = true

    reset: =>
      @visible = false
      delete @secrets[k] for k, v of @secrets
      delete @errors[k] for k, v of @errors
