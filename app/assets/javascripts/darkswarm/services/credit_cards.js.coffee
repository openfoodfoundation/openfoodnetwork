Darkswarm.factory 'CreditCards', (savedCreditCards)->
  new class CreditCard
    saved: savedCreditCards

    add: (card) ->
      @saved.push card
