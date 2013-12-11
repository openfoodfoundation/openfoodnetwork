Shop.factory 'OrderCycle', ($resource, Product) ->
  class OrderCycle
    @order_cycle = {
      order_cycle_id: null
    }

    @set_order_cycle: ->
      new $resource("/shop/order_cycle").save {order_cycle_id: @order_cycle.order_cycle_id}, ->
        Product.update() 
        
