angular.module('Darkswarm').factory 'CreditCards', ($http, $filter, savedCreditCards, Messages, Customers)->
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
        Customers.clearAllAllowCharges()
      , (response) ->
        Messages.flash(response.data.flash)

    confirmSetDefault: (card, event) =>
      if confirm t("js.default_card_voids_auth")
        @setDefault(card)
      else
        event.preventDefault()
        return false
