angular.module('Darkswarm').factory 'StripeElements', ($rootScope, Messages) ->
  new class StripeElements
    # These are both set from the StripeElements directive
    stripe: null
    card: null

    # Create Token to be used with the Stripe Charges API
    requestToken: (secrets, submit, loading_message = t("processing_payment")) ->
      return unless @stripe? && @card?

      Messages.loading loading_message
      cardData = @makeCardData(secrets)

      @stripe.createToken(@card, cardData).then (response) =>
        if(response.error)
          @reportError(response.error, t("error") + ": #{response.error.message}")
        else
          secrets.token = response.token.id
          secrets.cc_type = @mapTokenApiCardBrand(response.token.card.brand)
          secrets.card = response.token.card
          submit()
      .catch (response) =>
        # Stripe handles errors in the response above. This code may never be
        # reached. But if we get here, we want to know.
        @reportError(response, t("js.stripe_elements.unknown_error_from_stripe"))
        throw response

    # Create Payment Method to be used with the Stripe Payment Intents API
    createPaymentMethod: (secrets, submit, loading_message = t("processing_payment")) ->
      return unless @stripe? && @card?

      Messages.loading loading_message
      cardData = @makeCardData(secrets)

      @stripe.createPaymentMethod({ type: 'card', card: @card }, @card, cardData).then (response) =>
        if(response.error)
          @reportError(response.error, t("error") + ": #{response.error.message}")
        else
          secrets.token = response.paymentMethod.id
          secrets.cc_type = @mapPaymentMethodsApiCardBrand(response.paymentMethod.card.brand)
          secrets.card = response.paymentMethod.card
          submit()
      .catch (response) =>
        # Stripe handles errors in the response above. This code may never be
        # reached. But if we get here, we want to know.
        @reportError(response, t("js.stripe_elements.unknown_error_from_stripe"))
        throw response

    reportError: (error, messageForUser) ->
      Messages.error(messageForUser)
      @triggerAngularDigest()
      console.error(error)
      Bugsnag.notify(new Error(JSON.stringify(error)))

    triggerAngularDigest: ->
      # $evalAsync is improved way of triggering a digest without calling $apply
      $rootScope.$evalAsync()

    # Maps the brand returned by Stripe's tokenAPI to that required by activemerchant
    mapTokenApiCardBrand: (cardBrand) ->
      switch cardBrand
        when 'MasterCard' then return 'master'
        when 'Visa' then return 'visa'
        when 'American Express' then return 'american_express'
        when 'Discover' then return 'discover'
        when 'JCB' then return 'jcb'
        when 'Diners Club' then return 'diners_club'

    # Maps the brand returned by Stripe's paymentMethodsAPI to that required by activemerchant
    mapPaymentMethodsApiCardBrand: (cardBrand) ->
      switch cardBrand
        when 'mastercard' then return 'master'
        when 'amex' then return 'american_express'
        when 'diners' then return 'diners_club'
        else return cardBrand # a few brands are equal, for example, visa

    # It doesn't matter if any of these are nil, all are optional.
    makeCardData: (secrets) ->
      {'name': secrets.name,
      'address1': secrets.address1,
      'city': secrets.city,
      'zipcode': secrets.zipcode}
