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
      products: ["testy mctest"]
    OrderCycle =
      order_cycle: {}
        
    inject ($controller) ->
      scope = {}
      ctrl = $controller 'ProductsCtrl', {$scope: scope, Product: Product, OrderCycle: OrderCycle}

  it 'fetches products from Product', ->
    expect(scope.Product.products).toEqual ['testy mctest']

  it "increments the limit up to the number of products", ->
    scope.limit = 0
    scope.incrementLimit()
    expect(scope.limit).toEqual 1
    scope.incrementLimit()
    expect(scope.limit).toEqual 1

  it "blocks keypresses on code 13", ->
    event =
      keyCode: 13
      preventDefault: ->
    spyOn(event, 'preventDefault')
    scope.searchKeypress(event)
    expect(event.preventDefault).toHaveBeenCalled()
