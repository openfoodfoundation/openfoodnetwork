describe 'Order service', ->
  Order = null
  orderData = null
  $httpBackend = null

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
      spyOn(Order, "navigate") # Stubbing out writes to window.location

  it "defaults the shipping method to the first", ->
    expect(Order.order.shipping_method_id).toEqual 7
    expect(Order.shippingMethod()).toEqual { require_ship_address : true, price : 0 }

  # This is now handled via localStorage defaults
  xit "defaults to 'same as billing' for address", ->
    expect(Order.order.ship_address_same_as_billing).toEqual true

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
    $httpBackend.expectPUT("/shop/checkout", {order: Order.preprocess()}).respond 200, {path: "test"}
    Order.submit()
    $httpBackend.flush()

  it "Munges the order attributes to add _attributes as Rails needs", ->
    expect(Order.preprocess().bill_address_attributes).not.toBe(undefined)
    expect(Order.preprocess().bill_address).toBe(undefined)
    expect(Order.preprocess().ship_address_attributes).not.toBe(undefined)
    expect(Order.preprocess().ship_address).toBe(undefined)

  it "Munges the order attributes to clone ship address from bill address", ->
    Order.order.ship_address_same_as_billing = false
    expect(Order.preprocess().ship_address_attributes).toEqual(orderData.ship_address)
    Order.order.ship_address_same_as_billing = true
    expect(Order.preprocess().ship_address_attributes).toEqual(orderData.bill_address)
