describe "OverrideVariantsCtrl", ->
  ctrl = null
  scope = null
  hubs = [{id: 1, name: 'Hub'}]
  producers = [{id: 2, name: 'Producer'}]
  products = [{id: 1, name: 'Product'}]

  beforeEach ->
    module 'ofn.admin'
    module ($provide) ->
      $provide.value 'SpreeApiKey', 'API_KEY'
      null
    scope = {}

    inject ($controller, Indexer) ->
      ctrl = $controller 'AdminOverrideVariantsCtrl', {$scope: scope, Indexer: Indexer, hubs: hubs, producers: producers, products: products}

  it "initialises the hub list and the chosen hub", ->
    expect(scope.hubs).toEqual hubs
    expect(scope.hub).toBeNull

  it "adds products", ->
    expect(scope.products).toEqual []
    scope.addProducts ['a', 'b']
    expect(scope.products).toEqual ['a', 'b']
    scope.addProducts ['c', 'd']
    expect(scope.products).toEqual ['a', 'b', 'c', 'd']

  describe "selecting a hub", ->
    it "sets the chosen hub", ->
      scope.hub_id = 1
      scope.selectHub()
      expect(scope.hub).toEqual hubs[0]

    it "does nothing when no selection has been made", ->
      scope.hub_id = ''
      scope.selectHub
      expect(scope.hub).toBeNull