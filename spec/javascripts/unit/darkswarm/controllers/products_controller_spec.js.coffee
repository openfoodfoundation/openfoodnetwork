describe 'All controllers', ->
  describe 'ProductsCtrl', ->
    ctrl = null
    scope = null
    event = null
    Product = null

    beforeEach ->
      module('Darkswarm')
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
      module 'Darkswarm'
      scope = {}
      inject ($controller) ->
        scope = {}
        ctrl = $controller 'OrderCycleCtrl', {$scope: scope}
