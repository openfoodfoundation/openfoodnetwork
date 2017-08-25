Darkswarm.factory 'StripeJS', ($rootScope, Loading, RailsFlashLoader) ->
  new class StripeJS
    requestToken: (secrets, submit, loading_message = t("processing_payment")) ->
      Loading.message = loading_message
      params =
        number: secrets.card_number
        cvc: secrets.card_verification_value
        exp_month: secrets.card_month or 0
        exp_year: secrets.card_year or 0

      # This is the global Stripe object created by Stripe.js, included in the _stripe partial
      Stripe.card.createToken params, (status, response) =>
        if response.error
          $rootScope.$apply ->
            Loading.clear()
            RailsFlashLoader.loadFlash({error: t("error") + ": #{response.error.message}"})
        else
          secrets.token = response['id']
          secrets.cc_type = @mapCC(response.card.brand)
          secrets.card = response.card
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
