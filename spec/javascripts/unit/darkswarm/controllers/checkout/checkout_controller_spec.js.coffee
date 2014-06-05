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
      bindFieldsToLocalStorage: ->
      order:
        id: 1
        email: "public"
      secrets:
        card_number: "this is a secret"
     
  describe "with user", ->
    beforeEach ->
      inject ($controller, $rootScope) ->
        scope = $rootScope.$new() 
        spyOn(Order, "bindFieldsToLocalStorage")
        ctrl = $controller 'CheckoutCtrl', {$scope: scope, Order: Order, CurrentUser: {}}
  
    it "delegates to the service on submit", ->
      event = 
        preventDefault: ->
      spyOn(Order, "submit")
      scope.purchase(event)
      expect(Order.submit).toHaveBeenCalled()

    it "is enabled", ->
      expect(scope.enabled).toEqual true

    it "triggers localStorage binding", ->
      expect(Order.bindFieldsToLocalStorage).toHaveBeenCalled()

  describe "without user", ->
    beforeEach ->
      inject ($controller, $rootScope) ->
        scope = $rootScope.$new() 
        ctrl = $controller 'CheckoutCtrl', {$scope: scope, Order: Order, CurrentUser: undefined}

    it "is disabled", ->
      expect(scope.enabled).toEqual false

    it "does not store secrets in local storage", ->
      keys = (localStorage.key(i) for i in [0..localStorage.length])
      for key in keys
        expect(localStorage.getItem(key)).not.toMatch Order.secrets.card_number
