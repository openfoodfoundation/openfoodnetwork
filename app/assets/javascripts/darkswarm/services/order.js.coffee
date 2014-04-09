Darkswarm.factory 'Order', ($resource, Product, order, $http)->
  new class Order
    errors: {}
    constructor: ->
      @order = order
      # Here we default to the first shipping method if none is selected
      @order.shipping_method_id ||= parseInt(Object.keys(@order.shipping_methods)[0])
      @order.ship_address_same_as_billing ?= true

    submit: ->
      $http.put('/shop/checkout', {order: @preprocess()}).success (data, status)=>
        console.log data
        # Navigate to order confirmation
      .error (errors, status)=>
        console.log "error"
        @errors = errors
    
    # Rails wants our Spree::Address data to be provided with _attributes
    preprocess: ->
      munged_order = {}
      for name, value of @order # Clone all data from the order JSON object
        if name == "bill_address"
          munged_order["bill_address_attributes"] = value
        else if name == "ship_address"
          munged_order["ship_address_attributes"] = value
        else
          munged_order[name] = value
      munged_order

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
    
