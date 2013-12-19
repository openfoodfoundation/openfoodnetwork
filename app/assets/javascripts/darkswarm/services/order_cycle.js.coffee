Shop.factory 'OrderCycle', ($resource, Product, orderCycleData) ->
  class OrderCycle
    @order_cycle = orderCycleData || {orders_close_at: ""}
    @push_order_cycle: ->
      new $resource("/shop/order_cycle").save {order_cycle_id: @order_cycle.order_cycle_id}, (order_data)->
        OrderCycle.order_cycle.orders_close_at = order_data.orders_close_at
        Product.update()
