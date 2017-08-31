Darkswarm.factory 'StripeElements', ($rootScope, Loading, RailsFlashLoader) ->
  new class StripeElements
    # TODO: add locale here for translations of error messages etc. from Stripe

    # These are both set from the StripeElements directive
    stripe: null
    card: null

    # New Stripe Elements method
    requestToken: (secrets, submit, loading_message = t("processing_payment")) ->
      return unless @stripe? && @card?

      Loading.message = loading_message
      cardData = @makeCardData(secrets)

      @stripe.createToken(@card, cardData).then (response) =>
        if(response.error)
          Loading.clear()
          RailsFlashLoader.loadFlash({error: t("error") + ": #{response.error.message}"})
        else
          secrets.token = response.token.id
          secrets.cc_type = @mapCC(response.token.card.brand)
          secrets.card = response.token.card
          submit()

    mapCC: (ccType) ->
      if ccType == 'MasterCard'
        return 'mastercard'
      else if ccType == 'Visa'
        return 'visa'
      else if ccType == 'American Express'
        return 'amex'
      else if ccType == 'Discover'
        return 'discover'
      else if ccType == 'Diners Club'
        return 'dinersclub'
      else if ccType == 'JCB'
        return 'jcb'
      return

    # It doesn't matter if any of these are nil, all are optional.
    makeCardData: (secrets) ->
      {'name': secrets.name,
      'address1': secrets.address1,
      'city': secrets.city,
      'zipcode': secrets.zipcode}
