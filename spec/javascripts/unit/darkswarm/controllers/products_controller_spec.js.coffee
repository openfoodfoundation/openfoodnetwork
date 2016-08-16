describe 'ProductsCtrl', ->
  ctrl = null
  scope = null
  event = null
  Products = null
  Cart = {}
  Taxons = null
  Properties = null

  beforeEach ->
    module('Darkswarm')
    Products =
      all: ->
      update: ->
      products: ["testy mctest"]
      loading: false
    OrderCycle =
      order_cycle: {}
    Taxons:
      taxons: []
    Properties: {}

    inject ($rootScope, $controller) ->
      scope = $rootScope
      ctrl = $controller 'ProductsCtrl', {$scope: scope, Products: Products, OrderCycle: OrderCycle, Cart: Cart, Taxons: Taxons, Properties: Properties}

  it 'fetches products from Products', ->
    expect(scope.Products.products).toEqual ['testy mctest']

  it "increments the limit up to the number of products", ->
    scope.limit = 0
    scope.incrementLimit()
    expect(scope.limit).toEqual 10
    scope.incrementLimit()
    expect(scope.limit).toEqual 10

  it "blocks keypresses on code 13", ->
    event =
      keyCode: 13
      preventDefault: ->
    spyOn(event, 'preventDefault')
    scope.searchKeypress(event)
    expect(event.preventDefault).toHaveBeenCalled()
