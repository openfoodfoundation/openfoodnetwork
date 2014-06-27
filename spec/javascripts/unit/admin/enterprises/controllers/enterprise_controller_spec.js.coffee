describe "enterpriseCtrl", ->
  ctrl = null
  scope = null
  Enterprise = null

  beforeEach ->
    module('admin.enterprises')
    Enterprise = 
      enterprise: "test enterprise"
        
    inject ($controller) ->
      scope = {}
      ctrl = $controller 'enterpriseCtrl', {$scope: scope, Enterprise: Enterprise}

  it "stores enterprise", ->
    expect(scope.enterprise).toBe Enterprise.enterprise