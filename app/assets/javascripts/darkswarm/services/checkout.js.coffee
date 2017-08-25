Darkswarm.factory 'Checkout', ($injector, CurrentOrder, ShippingMethods, StripeJS, PaymentMethods, $http, Navigation, CurrentHub, RailsFlashLoader, Loading)->
  new class Checkout
    errors: {}
    secrets: {}
    order: CurrentOrder.order

    purchase: ->
      if @paymentMethod()?.method_type == 'stripe' && !@secrets.selected_card
        StripeJS.requestToken(@secrets, @submit)
      else
        @submit()

    submit: =>
      Loading.message = t 'submitting_order'
      $http.put('/checkout.json', {order: @preprocess()}).success (data, status)=>
        Navigation.go data.path
      .error (response, status)=>
        if response.path
          Navigation.go response.path
        else
          Loading.clear()
          @errors = response.errors
          RailsFlashLoader.loadFlash(response.flash)

    # Rails wants our Spree::Address data to be provided with _attributes
    preprocess: ->
      munged_order =
        default_bill_address: !!@default_bill_address
        default_ship_address: !!@default_ship_address

      for name, value of @order # Clone all data from the order JSON object
        switch name
          when "bill_address"
            munged_order["bill_address_attributes"] = value
          when "ship_address"
            munged_order["ship_address_attributes"] = value
          when "payment_method_id"
            munged_order["payments_attributes"] = [{payment_method_id: value}]
          when "shipping_method_id", "payment_method_id", "email", "special_instructions"
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

      if @paymentMethod()?.method_type == 'stripe'
        if @secrets.selected_card
          angular.extend munged_order, {
            existing_card: @secrets.selected_card
          }
        else
          angular.extend munged_order.payments_attributes[0], {
            source_attributes:
              gateway_payment_profile_id: @secrets.token
              cc_type: @secrets.cc_type
              last_digits: @secrets.card.last4
              month: @secrets.card.exp_month
              year: @secrets.card.exp_year
              first_name: @order.bill_address.firstname
              last_name: @order.bill_address.lastname
              save_requested_by_customer: @secrets.save_requested_by_customer
          }
      munged_order

    shippingMethod: ->
      ShippingMethods.shipping_methods_by_id[@order.shipping_method_id] if @order.shipping_method_id

    requireShipAddress: ->
      @shippingMethod()?.require_ship_address

    shippingPrice: ->
      @shippingMethod()?.price || 0.0

    paymentPrice: ->
      @paymentMethod()?.price || 0.0

    paymentMethod: ->
      PaymentMethods.payment_methods_by_id[@order.payment_method_id]

    cartTotal: ->
      @order.display_total + @shippingPrice() + @paymentPrice()
