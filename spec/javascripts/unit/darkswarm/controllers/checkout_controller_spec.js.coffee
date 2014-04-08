describe "CheckoutCtrl", ->
  ctrl = null
  scope = null
  order = null 

  beforeEach ->
    module("Darkswarm")
    order = {} 
    inject ($controller, $rootScope) ->
      scope = $rootScope.$new() 
      ctrl = $controller 'CheckoutCtrl', {$scope: scope, Order: order}

  it "defaults the user accordion to visible", ->
    expect(scope.userpanel).toEqual true
