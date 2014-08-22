Darkswarm.factory 'Checkout', (CurrentOrder, ShippingMethods, PaymentMethods, $http, Navigation, CurrentHub, RailsFlashLoader, Loading)->
  new class Checkout
    errors: {}
    secrets: {}
    order: CurrentOrder.order
    ship_address_same_as_billing: true

    submit: ->
      Loading.message = "Submitting your order: please wait"
      $http.put('/checkout', {order: @preprocess()}).success (data, status)=>
        Navigation.go data.path
      .error (response, status)=>
        Loading.clear()
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
          when "shipping_method_id", "payment_method_id", "email"
            munged_order[name] = value
          else
            # Ignore everything else

      if @ship_address_same_as_billing
        munged_order.ship_address_attributes = munged_order.bill_address_attributes
        # If the order already has a ship and bill address (as with logged in users with
        # past orders), and we don't remove id here, then this will set the wrong id for
        # ship address, and Rails will error with a 404 for that address.
        delete munged_order.ship_address_attributes.id

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
      ShippingMethods.shipping_methods_by_id[@order.shipping_method_id] if @order.shipping_method_id

    requireShipAddress: ->
      @shippingMethod()?.require_ship_address

    shippingPrice: ->
      @shippingMethod()?.price || 0.0
    
    paymentMethod: ->
      PaymentMethods.payment_methods_by_id[@order.payment_method_id]

    cartTotal: ->
      @shippingPrice() + @order.display_total
