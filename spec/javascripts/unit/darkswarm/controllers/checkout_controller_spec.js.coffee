describe "CheckoutCtrl", ->
  ctrl = null
  scope = null
  order = null 

  beforeEach ->
    module("Darkswarm")
    order = 
      id: 3102
      shipping_method_id: "7"
      ship_address_same_as_billing: true
      payment_method_id: null
      shipping_methods:
        7:
          require_ship_address: true
          price: 0.0

        25:
          require_ship_address: false
          price: 13
    inject ($controller) ->
      scope = {}
      ctrl = $controller 'CheckoutCtrl', {$scope: scope, order: order}


  it 'Gets the ship address automatically', ->
    expect(scope.require_ship_address).toEqual true

  it 'Gets the current shipping price', ->
    expect(scope.shippingPrice()).toEqual 0.0
    scope.order.shipping_method_id = 25
    expect(scope.shippingPrice()).toEqual 13


