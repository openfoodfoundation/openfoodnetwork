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
