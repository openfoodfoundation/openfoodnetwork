Darkswarm.factory 'OrderCycle', ($resource, Product, orderCycleData) ->
  class OrderCycle
    @order_cycle = orderCycleData || null 
    @push_order_cycle: ->
      new $resource("/shop/order_cycle").save {order_cycle_id: @order_cycle.order_cycle_id}, (order_data)->
        OrderCycle.order_cycle.orders_close_at = order_data.orders_close_at
        Product.update()

    @orders_close_at: ->
      if @selected()
        @order_cycle.orders_close_at

    @selected: ->
      @order_cycle != null and !$.isEmptyObject(@order_cycle) and @order_cycle.orders_close_at != undefined
