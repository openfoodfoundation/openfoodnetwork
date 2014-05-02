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
