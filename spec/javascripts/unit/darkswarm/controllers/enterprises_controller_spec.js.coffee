describe 'EnterprisesCtrl', ->
  ctrl = null
  scope = null
  event = null
  enterprise_1 = {active: true, name: "Enterprise"}
  hub_1 = {name: "Hub", category: 'producer_hub', matches_name_query: false, distance: null}

  beforeEach ->
    module('Darkswarm')
    Enterprises =
      all: ->
      update: ->
      enterprises: [enterprise_1]
      hubs: [hub_1]
      loading: false
      flagMatching: ->
      calculateDistance: ->

    inject ($rootScope, $controller) ->
      scope = $rootScope
      ctrl = $controller 'EnterprisesCtrl', {$scope: scope, Enterprises: Enterprises}

  it 'fetches products from Enterprises', ->
    expect(scope.Enterprises.enterprises).toEqual [enterprise_1]

  it 'fetches hubs from Enterprises', ->
    expect(scope.Enterprises.hubs).toEqual [hub_1]

  it 'filters enterprises', ->
    expect(scope.filterEnterprises()).toEqual [hub_1]

  it 'hides distance matches by default', ->
    expect(scope.distanceMatchesShown).toBe(false)

  it 'shows distance matches during search', ->
    scope.$digest('query')
    expect(scope.distanceMatchesShown).toBe(true)
