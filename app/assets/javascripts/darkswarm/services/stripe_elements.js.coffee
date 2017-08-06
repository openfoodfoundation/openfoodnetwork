Darkswarm.factory 'StripeElements', ($rootScope, Loading, RailsFlashLoader, stripeObject) ->
  new class StripeElements
    # This is the global Stripe object created by Stripe.js [v3+], included in the _stripe partial
    stripe = stripeObject
    elements = stripe.elements()
    card = elements.create('card', hidePostalCode = false)

    mountElements: ->
      card.mount('#card-element')
      # Elements validates user input as it is typed. To help your customers
      # catch mistakes, you should listen to change events on the card Element
      # and display any errors:
      card.addEventListener 'change', (event) ->
        displayError = document.getElementById('card-errors')
        if event.error
          displayError.textContent = event.error.message
        else
          displayError.textContent = ''
        return

    # New Stripe Elements method
    requestToken: (secrets, submit, loading_message = t("processing_payment")) ->
      Loading.message = loading_message

      stripe.createToken(card).then (response) =>
        if(response.error)
          $rootScope.$apply ->
            Loading.clear()
            RailsFlashLoader.loadFlash({error: t("error") + ": #{response.error.message}"})
        else
          console.log(response)
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
