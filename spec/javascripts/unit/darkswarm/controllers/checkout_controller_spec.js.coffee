describe "CheckoutCtrl", ->
  ctrl = null
  scope = null
  order = null

  beforeEach ->
    module("Darkswarm")
    order = {
      submit: ->
      navigate: ->
    } 
    inject ($controller, $rootScope) ->
      scope = $rootScope.$new() 
      ctrl = $controller 'CheckoutCtrl', {$scope: scope, Order: order}

  it "defaults the user accordion to visible", ->
    expect(scope.accordion.user).toEqual true
  
  it "delegates to the service on submit", ->
    event = {
      preventDefault: ->
    }
    spyOn(order, "submit")
    scope.purchase(event)
    expect(order.submit).toHaveBeenCalled()
