describe 'Shop controllers', ->
  describe 'ProductsCtrl', ->
    ctrl = null
    scope = null
    event = null
    Product = null

    beforeEach ->
      module('Shop')
      scope = {}
      Product = 
        all: ->
          'testy mctest'
      inject ($controller) ->
        ctrl = $controller 'ProductsCtrl', {$scope: scope, Product : Product} 

    it 'Fetches products from Product', ->
      expect(scope.products).toEqual 'testy mctest'
  
  describe 'OrderCycleCtrl', ->
    ctrl = null
    scope = null
    event = null
    OrderCycle = null

    beforeEach ->
      module 'Shop'
      scope = {}
      inject ($controller) ->
        ctrl = $controller 'OrderCycleCtrl'
