describe 'ProductsCtrl', ->
  ctrl = null
  scope = null
  event = null
  Products = null
  Cart = {}

  beforeEach ->
    module('Darkswarm')
    Products = 
      all: ->
      update: ->
      products: ["testy mctest"]
    OrderCycle =
      order_cycle: {}
        
    inject ($controller) ->
      scope = {}
      ctrl = $controller 'ProductsCtrl', {$scope: scope, Products: Products, OrderCycle: OrderCycle, Cart: Cart}

  it 'fetches products from Products', ->
    expect(scope.Products.products).toEqual ['testy mctest']

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
