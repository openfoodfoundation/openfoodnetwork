Darkswarm.factory 'OrderCycle', ($resource, Product, orderCycleData) ->
  class OrderCycle
    @order_cycle = orderCycleData # Object or {} due to RABL 
    @push_order_cycle: ->
      new $resource("/shop/order_cycle").save {order_cycle_id: @order_cycle.order_cycle_id}, (order_data)->
        OrderCycle.order_cycle.orders_close_at = order_data.orders_close_at
        Product.update()

    @orders_close_at: ->
      @order_cycle.orders_close_at if @selected()

    @selected: ->
      !$.isEmptyObject(@order_cycle) and @order_cycle.orders_close_at?
