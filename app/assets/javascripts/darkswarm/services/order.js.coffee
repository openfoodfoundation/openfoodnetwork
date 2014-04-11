Darkswarm.factory 'Order', ($resource, Product, order, $http, CheckoutFormState)->
  new class Order
    errors: {}

    constructor: ->
      @order = order
      # Default to first shipping method if none selected
      #@order.shipping_method_id ||= parseInt(Object.keys(@order.shipping_methods)[0])

    navigate: (path)->
      window.location.pathname = path

    submit: ->
      $http.put('/shop/checkout', {order: @preprocess()}).success (data, status)=>
        @navigate(data.path)
      .error (errors, status)=>
        @errors = errors

    # Rails wants our Spree::Address data to be provided with _attributes
    preprocess: ->
      munged_order = {}
      for name, value of @order # Clone all data from the order JSON object
        switch name
          when "bill_address"
            munged_order["bill_address_attributes"] = value
          when "ship_address"
            munged_order["ship_address_attributes"] = value
          when "payment_method_id"
            munged_order["payments_attributes"] = [{payment_method_id: value}]
          when "form_state" # don't keep this shit
          else
            munged_order[name] = value

      if CheckoutFormState.ship_address_same_as_billing
        munged_order.ship_address_attributes = munged_order.bill_address_attributes
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
