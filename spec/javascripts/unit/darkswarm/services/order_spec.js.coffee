describe 'Order service', ->
  Order = null
  orderData = null
  $httpBackend = null
  CheckoutFormState = null
  Navigation = null
  flash = null

  beforeEach ->
    orderData = {
      id: 3102
      payment_method_id: null
      bill_address: {test: "foo"}
      ship_address: {test: "bar"}
      shipping_methods:
        7:
          require_ship_address: true
          price: 0.0

        25:
          require_ship_address: false
          price: 13
      payment_methods: 
        99:
          test: "foo"
    }
    angular.module('Darkswarm').value('order', orderData)
    module 'Darkswarm'

    inject ($injector, _$httpBackend_)->
      $httpBackend = _$httpBackend_
      Order = $injector.get("Order")
      Navigation = $injector.get("Navigation")
      flash = $injector.get("flash")
      CheckoutFormState = $injector.get("CheckoutFormState")
      spyOn(Navigation, "go") # Stubbing out writes to window.location

  it "defaults to no shipping method", ->
    expect(Order.order.shipping_method_id).toEqual null
    expect(Order.shippingMethod()).toEqual undefined


  describe "with shipping method", ->
    beforeEach ->
      Order.order.shipping_method_id = 7

    it 'Tracks whether a ship address is required', ->
      expect(Order.requireShipAddress()).toEqual true
      Order.order.shipping_method_id = 25
      expect(Order.requireShipAddress()).toEqual false

    it 'Gets the current shipping price', ->
      expect(Order.shippingPrice()).toEqual 0.0
      Order.order.shipping_method_id = 25
      expect(Order.shippingPrice()).toEqual 13

  it 'Gets the current payment method', ->
    expect(Order.paymentMethod()).toEqual null
    Order.order.payment_method_id = 99
    expect(Order.paymentMethod()).toEqual {test: "foo"}

  it "Posts the Order to the server", ->
    $httpBackend.expectPUT("/checkout", {order: Order.preprocess()}).respond 200, {path: "test"}
    Order.submit()
    $httpBackend.flush()

  it "sends flash messages to the flash service", ->
    $httpBackend.expectPUT("/checkout").respond 400, {flash: {error: "frogs"}}
    Order.submit()
    $httpBackend.flush()
    expect(flash.error).toEqual "frogs"

  it "puts errors into the scope", ->
    $httpBackend.expectPUT("/checkout").respond 400, {errors: {error: "frogs"}}
    Order.submit()
    $httpBackend.flush()
    expect(Order.errors).toEqual {error: "frogs"}

  it "Munges the order attributes to add _attributes as Rails needs", ->
    expect(Order.preprocess().bill_address_attributes).not.toBe(undefined)
    expect(Order.preprocess().bill_address).toBe(undefined)
    expect(Order.preprocess().ship_address_attributes).not.toBe(undefined)
    expect(Order.preprocess().ship_address).toBe(undefined)

  it "Munges the order attributes to clone ship address from bill address", ->
    CheckoutFormState.ship_address_same_as_billing = false
    expect(Order.preprocess().ship_address_attributes).toEqual(orderData.ship_address)
    CheckoutFormState.ship_address_same_as_billing = true
    expect(Order.preprocess().ship_address_attributes).toEqual(orderData.bill_address)
