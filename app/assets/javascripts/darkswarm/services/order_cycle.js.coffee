angular.module('Darkswarm').factory 'OrderCycle', ($resource, orderCycleData) ->
  class OrderCycle
    @order_cycle = orderCycleData # Object or {}
    @push_order_cycle: (callback) ->
      new $resource("/shop/order_cycle").save {order_cycle_id: @order_cycle.order_cycle_id}, (order_data)->
        OrderCycle.order_cycle.orders_close_at = order_data.orders_close_at
        callback()

    @orders_close_at: ->
      @order_cycle.orders_close_at if @selected()

    @selected: ->
      !$.isEmptyObject(@order_cycle) and @order_cycle.orders_close_at?
