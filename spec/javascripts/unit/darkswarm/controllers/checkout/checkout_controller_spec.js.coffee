describe "CheckoutCtrl", ->
  ctrl = null
  scope = null
  Order = null
  CurrentUser = null

  beforeEach ->
    module("Darkswarm")
    angular.module('Darkswarm').value('user', {})
    Order = 
      submit: ->
      navigate: ->
      order:
        id: 1
     
  describe "with user", ->
    beforeEach ->
      inject ($controller, $rootScope) ->
        scope = $rootScope.$new() 
        ctrl = $controller 'CheckoutCtrl', {$scope: scope, Order: Order, CurrentUser: {}}
  
    it "delegates to the service on submit", ->
      event = 
        preventDefault: ->
      spyOn(Order, "submit")
      scope.purchase(event)
      expect(Order.submit).toHaveBeenCalled()

    it "is enabled", ->
      expect(scope.enabled).toEqual true

  describe "without user", ->
    beforeEach ->
      inject ($controller, $rootScope) ->
        scope = $rootScope.$new() 
        ctrl = $controller 'CheckoutCtrl', {$scope: scope, Order: Order, CurrentUser: undefined}

    it "is disabled", ->
      expect(scope.enabled).toEqual false
