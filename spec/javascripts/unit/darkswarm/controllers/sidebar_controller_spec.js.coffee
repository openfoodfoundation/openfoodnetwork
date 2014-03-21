describe "SidebarCtrl", ->
  ctrl = null
  scope = null
  location = null

  beforeEach ->
    module("Darkswarm")
    location =
      path: ->
        "/test"
    inject ($controller, $rootScope) ->
      scope = $rootScope
      ctrl = $controller 'SidebarCtrl', {$scope: scope, $location: location}
    scope.$apply()

  it 'tracks the active sidebar from the $location', ->
    expect(scope.active_sidebar).toEqual "/test"

  it 'is active when a location is set', ->
    expect(scope.active()).toEqual "active"

  it 'is inactive no location is set', ->
    scope.active_sidebar = null
    expect(scope.active()).toEqual null
