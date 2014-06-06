Darkswarm.factory 'Order', ($resource, order, $http, Navigation, storage, CurrentHub, RailsFlashLoader)->
  new class Order
    errors: {}
    secrets: {}
    order: order
    ship_address_same_as_billing: true

    #Whitelist of fields from Order.order to bind into localStorage
    fieldsToBind: ["bill_address", "email", "payment_method_id", "shipping_method_id", "ship_address"]

    # Bind all the fields from fieldsToBind, + anything on the Order class
    bindFieldsToLocalStorage: (scope)=>
      prefix = "order_#{@order.id}#{@order.user_id}#{CurrentHub.id}"
      for field in @fieldsToBind
        storage.bind scope, "Order.order.#{field}", 
          storeName: "#{prefix}_#{field}"
      
      storage.bind scope, "Order.ship_address_same_as_billing", 
        storeName: "#{prefix}_sameasbilling"
        defaultValue: true

    submit: ->
      $http.put('/checkout', {order: @preprocess()}).success (data, status)=>
        Navigation.go data.path
      .error (response, status)=>
        @errors = response.errors
        RailsFlashLoader.loadFlash(response.flash)
        
        
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

      if @ship_address_same_as_billing
        munged_order.ship_address_attributes = munged_order.bill_address_attributes

      if @paymentMethod()?.method_type == 'gateway'
        angular.extend munged_order.payments_attributes[0], {
          source_attributes:
            number: @secrets.card_number
            month: @secrets.card_month
            year: @secrets.card_year
            verification_value: @secrets.card_verification_value
            first_name: @order.bill_address.firstname
            last_name: @order.bill_address.lastname
        }

      munged_order

    shippingMethod: ->
      @order.shipping_methods[@order.shipping_method_id] if @order.shipping_method_id

    requireShipAddress: ->
      @shippingMethod()?.require_ship_address

    shippingPrice: ->
      @shippingMethod()?.price || 0.0
    
    paymentMethod: ->
      @order.payment_methods[@order.payment_method_id]

    cartTotal: ->
      @shippingPrice() + @order.display_total
