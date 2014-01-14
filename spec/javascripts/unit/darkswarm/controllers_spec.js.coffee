describe 'All controllers', ->
  describe 'ProductsCtrl', ->
    ctrl = null
    scope = null
    event = null
    rootScope = null
    Product = null

    beforeEach ->
      module('Shop')
      Product = 
        all: ->
        update: ->
        data: "testy mctest"
          
      inject ($controller, $rootScope) ->
        rootScope = $rootScope
        scope = $rootScope.$new()
        ctrl = $controller 'ProductsCtrl', {$scope: scope, Product : Product} 

    it 'Fetches products from Product', ->
      expect(scope.data).toEqual 'testy mctest'

  
  describe 'OrderCycleCtrl', ->
    ctrl = null
    scope = null
    event = null
    rootScope = null
    product_ctrl = null
    OrderCycle = null

    beforeEach ->
      module 'Shop'
      scope = {}
      inject ($controller, $rootScope) ->
        rootScope = $rootScope
        scope = $rootScope.$new()
        ctrl = $controller 'OrderCycleCtrl', {$scope: scope}

