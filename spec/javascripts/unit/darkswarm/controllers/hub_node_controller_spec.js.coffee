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
      hub:
        id: 99

    inject ($controller, $location)->
      ctrl = $controller 'HubNodeCtrl', {$scope: scope, CurrentHub: CurrentHub, $location : $location}

  it "knows whether the controlled hub is current", ->
    scope.hub = {id: 1} 
    expect(scope.current()).toEqual false
    scope.hub = {id: 99} 
    expect(scope.current()).toEqual true
