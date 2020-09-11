Darkswarm.factory 'CreditCards', ($http, $filter, savedCreditCards, Messages)->
  new class CreditCard
    saved: $filter('orderBy')(savedCreditCards,'-is_default')

    add: (card) ->
      @saved.push card

    setDefault: (card) =>
      card.is_default = true
      for othercard in @saved when othercard != card
        othercard.is_default = false
      $http.put("/credit_cards/#{card.id}", is_default: true).then (data) ->
        Messages.success(t('js.default_card_updated'))
      , (response) ->
        Messages.flash(response.data.flash)
