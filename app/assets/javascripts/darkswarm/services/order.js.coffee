Darkswarm.factory 'Order', ($resource, Product, order)->

  ## I am being clever here
  ## order is a JSON object generated in shop/checkout/order.rabl 
  ## We're extending this to add methods while retaining the data!
  
  new class Order
    constructor: ->
      @[name] = method for name, method of order # Clone all data from the order JSON object

      # Our shipping_methods comes through as a hash like so: {id: requires_shipping_address}
      # Here we default to the first shipping method if none is selected
      @shipping_method_id ||= Object.keys(@shipping_methods)[0] 
      @ship_address_same_as_billing = true if @ship_address_same_as_billing == null
      @shippingMethodChanged()

    shippingMethod: ->
      @shipping_methods[@shipping_method_id]

    shippingMethodChanged: =>
      @require_ship_address = @shippingMethod().require_ship_address if @shippingMethod()

    shippingPrice: ->
      @shippingMethod().price
    
    paymentMethod: ->
      @payment_methods[@payment_method_id]


    cartTotal: ->
      @shippingPrice() + @display_total
    
