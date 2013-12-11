Shop.factory 'OrderCycle', ($resource, Product) ->
  new class OrderCycle
    @order_cycle:
      order_cycle_id: null

    set_order_cycle: (id = null)->
      new $resource("/shop/order_cycle").save {order_cycle_id: id}, ->
        Product.update() 
        
