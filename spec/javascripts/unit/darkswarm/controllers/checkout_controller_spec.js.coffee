describe "CheckoutCtrl", ->
  ctrl = null
  scope = null
  Order = null

  beforeEach ->
    module("Darkswarm")
    angular.module('Darkswarm').value('user', {})
    Order = {
      submit: ->
      navigate: ->
      order:
        id: 1
    } 
    inject ($controller, $rootScope) ->
      scope = $rootScope.$new() 
      ctrl = $controller 'CheckoutCtrl', {$scope: scope, Order: Order}

  it "defaults the user accordion to visible", ->
    expect(scope.accordion.user).toEqual true
  
  it "delegates to the service on submit", ->
    event = {
      preventDefault: ->
    }
    spyOn(Order, "submit")
    scope.purchase(event)
    expect(Order.submit).toHaveBeenCalled()
