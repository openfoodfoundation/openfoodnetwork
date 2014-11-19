describe "OverrideVariantsCtrl", ->
  ctrl = null
  scope = null
  hubs = [{id: 1, name: 'Hub'}]

  beforeEach ->
    module 'ofn.admin'
    scope = {}

    inject ($controller)->
      ctrl = $controller 'AdminOverrideVariantsCtrl', {$scope: scope, hubs: hubs}

  it "initialises the hub list and the chosen hub", ->
    expect(scope.hubs).toEqual hubs
    expect(scope.hub).toBeNull

  describe "selecting a hub", ->
    it "sets the chosen hub", ->
      scope.hub_id = 1
      scope.selectHub()
      expect(scope.hub).toEqual hubs[0]

    it "does nothing when no selection has been made", ->
      scope.hub_id = ''
      scope.selectHub
      expect(scope.hub).toBeNull