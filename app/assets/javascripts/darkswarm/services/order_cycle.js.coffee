Shop.factory 'OrderCycle', ($resource, Product) ->
  class OrderCycle
    @order_cycle = {
      order_cycle_id: null
    }

    @set_order_cycle: (id)->
      @order_cycle.order_cycle_id = id
      new $resource("/shop/order_cycle").save {order_cycle_id: id}, ->
        Product.update() 
        
