describe 'Checkout service', ->
  Checkout = null
  orderData = null
  $httpBackend = null
  Navigation = null
  flash = null
  scope = null
  FlashLoaderMock =
    loadFlash: (arg)->
  paymentMethods = [{
      id: 99
      test: "foo"
      method_type: "gateway"
    }, {
      id: 123
      test: "bar"
      method_type: "check"
    },
    {
      id: 666
      test: "qux"
      method_type: "stripe"
    }]
  shippingMethods = [
    {
      id: 7
      require_ship_address: true
      price: 0.0
    }, {
      id: 25
      require_ship_address: false
      price: 13
    }]

  beforeEach ->
    orderData =
      id: 3102
      shipping_method_id: null
      payment_method_id: null
      email: "test@test.com"
      bill_address:
        test: "foo"
        firstname: "Robert"
        lastname: "Harrington"
      ship_address: {test: "bar"}
      user_id: 901

    module 'Darkswarm'
    module ($provide)->
      $provide.value "RailsFlashLoader", FlashLoaderMock
      $provide.value "currentOrder", orderData
      $provide.value "shippingMethods", shippingMethods
      $provide.value "paymentMethods", paymentMethods
      $provide.value "StripeInstancePublishableKey", "instance_publishable_key"
      null

    inject ($injector, _$httpBackend_, $rootScope)->
      $httpBackend = _$httpBackend_
      Checkout = $injector.get("Checkout")
      scope = $rootScope.$new()
      scope.Checkout = Checkout
      Navigation = $injector.get("Navigation")
      flash = $injector.get("flash")
      spyOn(Navigation, "go") # Stubbing out writes to window.location

  it "defaults to no shipping method", ->
    expect(Checkout.order.shipping_method_id).toEqual null
    expect(Checkout.shippingMethod()).toEqual undefined

  it "has a shipping price of zero with no shipping method", ->
    expect(Checkout.shippingPrice()).toEqual 0.0

  describe "with shipping method", ->
    beforeEach ->
      Checkout.order.shipping_method_id = 7

    it 'Tracks whether a ship address is required', ->
      expect(Checkout.requireShipAddress()).toEqual true
      Checkout.order.shipping_method_id = 25
      expect(Checkout.requireShipAddress()).toEqual false

    it 'Gets the current shipping price', ->
      expect(Checkout.shippingPrice()).toEqual 0.0
      Checkout.order.shipping_method_id = 25
      expect(Checkout.shippingPrice()).toEqual 13

  it 'Gets the current payment method', ->
    expect(Checkout.paymentMethod()).toBeUndefined()
    Checkout.order.payment_method_id = 99
    expect(Checkout.paymentMethod()).toEqual paymentMethods[0]

  describe "submitting", ->
    it "Posts the Checkout to the server", ->
      $httpBackend.expectPUT("/checkout", {order: Checkout.preprocess()}).respond 200, {path: "test"}
      Checkout.submit()
      $httpBackend.flush()

    describe "when there is an error", ->
      it "redirects when a redirect is given", ->
        $httpBackend.expectPUT("/checkout").respond 400, {path: 'path'}
        Checkout.submit()
        $httpBackend.flush()
        expect(Navigation.go).toHaveBeenCalledWith 'path'

      it "sends flash messages to the flash service", ->
        spyOn(FlashLoaderMock, "loadFlash") # Stubbing out writes to window.location
        $httpBackend.expectPUT("/checkout").respond 400, {flash: {error: "frogs"}}
        Checkout.submit()

        $httpBackend.flush()
        expect(FlashLoaderMock.loadFlash).toHaveBeenCalledWith {error: "frogs"}

      it "puts errors into the scope", ->
        $httpBackend.expectPUT("/checkout").respond 400, {errors: {error: "frogs"}}
        Checkout.submit()
        $httpBackend.flush()
        expect(Checkout.errors).toEqual {error: "frogs"}

    describe "when using the Stripe Connect gateway", ->
      beforeEach inject ($injector, StripeJS) ->
        Checkout.order.payment_method_id = 666

      it "requests a Stripe token before submitting", inject (StripeJS) ->
        spyOn(StripeJS, "requestToken")
        Checkout.purchase()
        expect(StripeJS.requestToken).toHaveBeenCalled()

  describe "data preprocessing", ->
    beforeEach ->
      Checkout.order.payment_method_id = 99

      Checkout.secrets =
        card_number: "1234567890123456"
        card_month: "10"
        card_year: "2015"
        card_verification_value: "123"

    it "munges the order attributes to add _attributes as Rails needs", ->
      expect(Checkout.preprocess().bill_address_attributes).not.toBe(undefined)
      expect(Checkout.preprocess().bill_address).toBe(undefined)
      expect(Checkout.preprocess().ship_address_attributes).not.toBe(undefined)
      expect(Checkout.preprocess().ship_address).toBe(undefined)

    it "munges the order attributes to clone ship address from bill address", ->
      Checkout.ship_address_same_as_billing = false
      expect(Checkout.preprocess().ship_address_attributes).toEqual(orderData.ship_address)
      Checkout.ship_address_same_as_billing = true
      expect(Checkout.preprocess().ship_address_attributes).toEqual(orderData.bill_address)

    it "munges the default as billing address and shipping address", ->
      expect(Checkout.preprocess().default_bill_address).toEqual(false)
      expect(Checkout.preprocess().default_ship_address).toEqual(false)

      Checkout.default_bill_address = true
      Checkout.default_ship_address = true

      expect(Checkout.preprocess().default_bill_address).toEqual(true)
      expect(Checkout.preprocess().default_ship_address).toEqual(true)

    it "creates attributes for card fields", ->
      source_attributes = Checkout.preprocess().payments_attributes[0].source_attributes
      expect(source_attributes).toBeDefined()
      expect(source_attributes.number).toBe Checkout.secrets.card_number
      expect(source_attributes.month).toBe Checkout.secrets.card_month
      expect(source_attributes.year).toBe Checkout.secrets.card_year
      expect(source_attributes.verification_value).toBe Checkout.secrets.card_verification_value
      expect(source_attributes.first_name).toBe Checkout.order.bill_address.firstname
      expect(source_attributes.last_name).toBe Checkout.order.bill_address.lastname

    it "does not create attributes for card fields when no card is supplied", ->
      Checkout.order.payment_method_id = 123
      source_attributes = Checkout.preprocess().payments_attributes[0].source_attributes
      expect(source_attributes).not.toBeDefined()

    describe "when the payment method is the Stripe Connect gateway", ->
      beforeEach ->
        Checkout.order.payment_method_id = 666
        Checkout.secrets =
          token: "stripe_token"
          cc_type: "mastercard"
          card:
            last4: "1234"
            exp_year: "2099"
            exp_month: "10"

      it "creates source attributes for the submitted card", ->
        source_attributes = Checkout.preprocess().payments_attributes[0].source_attributes
        expect(source_attributes).toBeDefined()
        expect(source_attributes.gateway_payment_profile_id).toBe "stripe_token"
        expect(source_attributes.cc_type).toBe "mastercard"
        expect(source_attributes.last_digits).toBe "1234"
        expect(source_attributes.year).toBe "2099"
        expect(source_attributes.month).toBe "10"
