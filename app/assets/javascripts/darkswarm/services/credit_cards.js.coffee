Darkswarm.factory 'CreditCards', ($http, $filter, savedCreditCards, RailsFlashLoader)->
  new class CreditCard
    saved: $filter('orderBy')(savedCreditCards,'-is_default')

    add: (card) ->
      @saved.push card

    setDefault: (card) =>
      card.is_default = true
      for othercard in @saved when othercard != card
        othercard.is_default = false
      $http.put("/credit_cards/#{card.id}", is_default: true).then (data) ->
        RailsFlashLoader.loadFlash({success: t('js.default_card_updated')})
      , (response) ->
        RailsFlashLoader.loadFlash({error: response.data.flash.error})
