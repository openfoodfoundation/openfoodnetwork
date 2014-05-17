describe "HubNodeCtrl", ->
  ctrl = null
  scope = null
  hub = null
  CurrentHub = null

  beforeEach ->
    module 'Darkswarm'
    scope = 
      hub: {}
    CurrentHub =
      id: 99

    inject ($controller, $location)->
      ctrl = $controller 'HubNodeCtrl', {$scope: scope, CurrentHub: CurrentHub, $location : $location}

  it "knows whether the controlled hub is current", ->
    scope.hub = {id: 1} 
    expect(scope.current()).toEqual false
    scope.hub = {id: 99} 
    expect(scope.current()).toEqual true

  it "knows whether selecting this hub will empty the cart", ->
    CurrentHub.id = undefined
    expect(scope.emptiesCart()).toEqual false

    CurrentHub.id = 99
    scope.hub.id = 99
    expect(scope.emptiesCart()).toEqual false

    scope.hub.id = 1
    expect(scope.emptiesCart()).toEqual true
