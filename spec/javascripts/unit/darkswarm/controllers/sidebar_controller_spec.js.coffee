describe "SidebarCtrl", ->
  ctrl = null
  scope = null
  location = null

  beforeEach ->
    module("Darkswarm")
    location =
      path: ->
        "/login"
    inject ($controller, $rootScope) ->
      scope = $rootScope
      ctrl = $controller 'SidebarCtrl', {$scope: scope, $location: location}
    scope.$apply()

  it 'is active when a location is set', ->
    expect(scope.active()).toEqual true

  it 'is inactive no location is set', ->
    location.path = ->
      null 
    expect(scope.active()).toEqual false
