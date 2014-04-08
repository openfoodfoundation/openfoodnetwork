Darkswarm.factory 'Order', ($resource, Product, order)->
  new class Order
    constructor: ->
      @[name] = method for name, method of order # Clone all data from the order JSON object

      # Here we default to the first shipping method if none is selected
      @shipping_method_id ||= parseInt(Object.keys(@shipping_methods)[0])
      @ship_address_same_as_billing ?= true

    shippingMethod: ->
      @shipping_methods[@shipping_method_id]

    requireShipAddress: ->
      @shippingMethod()?.require_ship_address

    shippingPrice: ->
      @shippingMethod()?.price
    
    paymentMethod: ->
      @payment_methods[@payment_method_id]

    cartTotal: ->
      @shippingPrice() + @display_total
    
