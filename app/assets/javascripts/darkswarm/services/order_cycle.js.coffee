Shop.factory 'OrderCycle', ($resource) ->
  class OrderCycle
    @set_order_cycle: (id)->
      new $resource("/shop/order_cycle").$save () ->
        console.log "pushed"
      # Push id to endpoint
