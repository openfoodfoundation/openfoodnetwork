angular.module("admin.payments").factory 'AdminStripeElements', ($rootScope, StatusMessage) ->
  new class AdminStripeElements

    # These are both set from the AdminStripeElements directive
    stripe: null
    card: null

    # New Stripe Elements method
    requestToken: (secrets, submit) ->
      return unless @stripe? && @card?

      cardData = @makeCardData(secrets)

      @stripe.createToken(@card, cardData).then (response) =>
        if(response.error)
          StatusMessage.display 'error', response.error.message
        else
          secrets.token = response.token.id
          secrets.cc_type = @mapCC(response.token.card.brand)
          secrets.card = response.token.card
          submit()

    # Maps the brand returned by Stripe to that required by activemerchant
    mapCC: (ccType) ->
      if ccType == 'MasterCard'
        return 'master'
      else if ccType == 'Visa'
        return 'visa'
      else if ccType == 'American Express'
        return 'american_express'
      else if ccType == 'Discover'
        return 'discover'
      else if ccType == 'JCB'
        return 'jcb'
      else if ccType == 'Diners Club'
        return 'diners_club'
      return

    # It doesn't matter if any of these are nil, all are optional.
    makeCardData: (secrets) ->
      {'name': secrets.name,
      'address1': secrets.address1,
      'city': secrets.city,
      'zipcode': secrets.zipcode}
