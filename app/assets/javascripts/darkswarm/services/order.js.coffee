Darkswarm.factory 'Order', ($resource, Product, order, $http)->
  new class Order
    errors: {}
    constructor: ->
      @order = order
      # Here we default to the first shipping method if none is selected
      @order.shipping_method_id ||= parseInt(Object.keys(@order.shipping_methods)[0])
      @order.ship_address_same_as_billing ?= true

    submit: ->
      $http.put('/shop/checkout', {order: @preprocess()}).success (data, status)->
        console.log "success"
        console.log data
      .error (data, status)->
        console.log "error"
        console.log data
    
    preprocess: ->
      @order

    shippingMethod: ->
      @order.shipping_methods[@order.shipping_method_id]

    requireShipAddress: ->
      @shippingMethod()?.require_ship_address

    shippingPrice: ->
      @shippingMethod()?.price
    
    paymentMethod: ->
      @order.payment_methods[@order.payment_method_id]

    cartTotal: ->
      @shippingPrice() + @order.display_total
    
