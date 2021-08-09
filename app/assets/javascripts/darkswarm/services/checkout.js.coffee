angular.module('Darkswarm').factory 'Checkout', ($injector, CurrentOrder, ShippingMethods, StripeElements, PaymentMethods, $http, Navigation, CurrentHub, Messages)->
  new class Checkout
    errors: {}
    secrets: {}
    order: CurrentOrder.order

    purchase: ->
      if @paymentMethod()?.method_type == 'stripe' && !@secrets.selected_card
        StripeElements.requestToken(@secrets, @submit)
      else if @paymentMethod()?.method_type == 'stripe_sca' && !@secrets.selected_card
        StripeElements.createPaymentMethod(@secrets, @submit)
      else
        @submit()

    submit: =>
      Messages.loading(t 'submitting_order')
      $http.put('/checkout.json', {order: @preprocess()})
      .then (response) =>
        Navigation.go response.data.path
      .catch (response) =>
        try
          @handle_checkout_error_response(response)
        catch error
          try
            @loadFlash(error: t("checkout.failed")) # inform the user about the unexpected error
          finally
            Bugsnag.notify(error)
            throw error

    handle_checkout_error_response: (response) =>
      throw response unless response.data?

      if response.data.path?
        Navigation.go response.data.path
      else
        throw response unless response.data.flash?

        @errors = response.data.errors
        @loadFlash(response.data.flash)

    loadFlash: (flash) =>
      Messages.flash(flash)

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

      if @paymentMethod()?.method_type == 'stripe' || @paymentMethod()?.method_type == 'stripe_sca'
        if @secrets.selected_card
          angular.extend munged_order, {
            existing_card_id: @secrets.selected_card
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

      if @terms_and_conditions_accepted()
        munged_order["terms_and_conditions_accepted"] = true

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

    terms_and_conditions_accepted: ->
      terms_and_conditions_checkbox = angular.element("#accept_terms")[0]
      terms_and_conditions_checkbox? && terms_and_conditions_checkbox.checked
