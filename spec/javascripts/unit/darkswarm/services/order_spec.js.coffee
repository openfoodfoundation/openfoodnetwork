describe 'Order service', ->
  Order = null
  orderData = null

  beforeEach ->
    orderData = {
      id: 3102
      payment_method_id: null
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
    inject ($injector)->
      Order = $injector.get("Order")

  it "defaults the shipping method to the first", ->
    expect(Order.shipping_method_id).toEqual 7
    expect(Order.shippingMethod()).toEqual { require_ship_address : true, price : 0 }

  it "defaults to 'same as billing' for address", ->
    expect(Order.ship_address_same_as_billing).toEqual true

  it 'Tracks whether a ship address is required', ->
    expect(Order.requireShipAddress()).toEqual true
    Order.shipping_method_id = 25
    expect(Order.requireShipAddress()).toEqual false

  it 'Gets the current shipping price', ->
    expect(Order.shippingPrice()).toEqual 0.0
    Order.shipping_method_id = 25
    expect(Order.shippingPrice()).toEqual 13

  it 'Gets the current payment method', ->
    expect(Order.paymentMethod()).toEqual null
    Order.payment_method_id = 99
    expect(Order.paymentMethod()).toEqual {test: "foo"}

