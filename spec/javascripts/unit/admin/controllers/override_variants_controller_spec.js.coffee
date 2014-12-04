describe "OverrideVariantsCtrl", ->
  ctrl = null
  scope = null
  hubs = [{id: 1, name: 'Hub'}]
  producers = [{id: 2, name: 'Producer'}]
  products = [{id: 1, name: 'Product'}]
  hubPermissions = {}
  VariantOverrides = null
  variantOverrides = {}

  beforeEach ->
    module 'ofn.admin'
    module ($provide) ->
      $provide.value 'SpreeApiKey', 'API_KEY'
      $provide.value 'variantOverrides', variantOverrides
      null
    scope = {}

    inject ($controller, Indexer, _VariantOverrides_) ->
      VariantOverrides = _VariantOverrides_
      ctrl = $controller 'AdminOverrideVariantsCtrl', {$scope: scope, Indexer: Indexer, hubs: hubs, producers: producers, products: products, hubPermissions: hubPermissions, VariantOverrides: _VariantOverrides_}

  it "initialises the hub list and the chosen hub", ->
    expect(scope.hubs).toEqual hubs
    expect(scope.hub).toBeNull()

  it "adds products", ->
    spyOn(VariantOverrides, "ensureDataFor")
    expect(scope.products).toEqual []
    scope.addProducts ['a', 'b']
    expect(scope.products).toEqual ['a', 'b']
    scope.addProducts ['c', 'd']
    expect(scope.products).toEqual ['a', 'b', 'c', 'd']
    expect(VariantOverrides.ensureDataFor).toHaveBeenCalled()

  describe "selecting a hub", ->
    it "sets the chosen hub", ->
      scope.hub_id = 1
      scope.selectHub()
      expect(scope.hub).toEqual hubs[0]

    it "does nothing when no selection has been made", ->
      scope.hub_id = ''
      scope.selectHub
      expect(scope.hub).toBeNull