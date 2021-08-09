angular.module('Darkswarm').factory "StockQuantity", ->
  new class StockQuantity
    available_quantity: (on_hand, finalized_quantity) ->
      on_hand = parseInt(on_hand)
      finalized_quantity = parseInt(finalized_quantity) || 0 # finalized_quantity is optional

      on_hand + finalized_quantity
