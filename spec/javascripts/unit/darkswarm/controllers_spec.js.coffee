describe 'All controllers', ->
  describe 'ProductsCtrl', ->
    ctrl = null
    scope = null
    event = null
    Product = null

    beforeEach ->
      module('Shop')
      Product = 
        all: ->
        update: ->
        data: "testy mctest"
      OrderCycle =
        order_cycle: {}
          
      inject ($controller) ->
        scope = {}
        ctrl = $controller 'ProductsCtrl', {$scope: scope, Product: Product, OrderCycle: OrderCycle}

    it 'fetches products from Product', ->
      expect(scope.data).toEqual 'testy mctest'

    describe "determining the price to display for a product", ->
      it "displays the product price when the product does not have variants", ->
        product = {variants: [], price: 12.34}
        expect(scope.productPrice(product)).toEqual 12.34

      it "displays the minimum variant price when the product has variants", ->
        product =
          price: 11
          variants: [{price: 22}, {price: 33}]
        expect(scope.productPrice(product)).toEqual 22
  
  describe 'OrderCycleCtrl', ->
    ctrl = null
    scope = null
    event = null
    product_ctrl = null
    OrderCycle = null

    beforeEach ->
      module 'Shop'
      scope = {}
      inject ($controller) ->
        scope = {}
        ctrl = $controller 'OrderCycleCtrl', {$scope: scope}

  describe "CheckoutCtrl", ->
    ctrl = null
    scope = null
    order = null 

    beforeEach ->
      module("Checkout")
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

