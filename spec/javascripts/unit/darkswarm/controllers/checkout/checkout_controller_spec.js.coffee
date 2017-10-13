describe "CheckoutCtrl", ->
  ctrl = null
  scope = null
  Checkout = null
  CurrentUser = null
  CurrentHubMock =
    hub:
      id: 1
  localStorageService = null

  beforeEach ->
    module("Darkswarm")
    angular.module('Darkswarm').value('user', {})
    angular.module('Darkswarm').value('currentHub', {id: 1})
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock
      null
    Checkout =
      purchase: ->
      submit: ->
      navigate: ->
      bindFieldsToLocalStorage: ->
      order:
        id: 1
        email: "public"
        user_id: 1
        bill_address: 'bill_address'
        ship_address: 'ship address'
      secrets:
        card_number: "this is a secret"

  describe "with user", ->
    beforeEach ->
      inject ($controller, $rootScope, _localStorageService_) ->
        localStorageService = _localStorageService_
        spyOn(localStorageService, "bind").and.callThrough()
        scope = $rootScope.$new()
        CurrentUser = { id: 1 }
        ctrl = $controller 'CheckoutCtrl', {$scope: scope, Checkout: Checkout, CurrentUser: CurrentUser }

    describe "submitting", ->
      event =
        preventDefault: ->

      beforeEach ->
        spyOn(Checkout, "purchase")
        scope.submitted = false

      it "delegates to the service when valid", ->
        scope.purchase(event, {$valid: true})
        expect(Checkout.purchase).toHaveBeenCalled()
        expect(scope.submitted).toBe(true)

      it "does nothing when invalid", ->
        scope.purchase(event, {$valid: false})
        expect(Checkout.purchase).not.toHaveBeenCalled()
        expect(scope.submitted).toBe(true)

    it "is enabled", ->
      expect(scope.enabled).toEqual true

    describe "Local storage", ->
      it "binds to localStorage when given a scope", inject ($timeout) ->
        prefix = "order_#{scope.order.id}#{CurrentUser.id or ""}#{CurrentHubMock.hub.id}"

        field = scope.fieldsToBind[0]
        expect(localStorageService.bind).toHaveBeenCalledWith(scope, "Checkout.order.#{field}", Checkout.order[field], "#{prefix}_#{field}")
        expect(localStorageService.bind).toHaveBeenCalledWith(scope, "Checkout.ship_address_same_as_billing", true, "#{prefix}_sameasbilling")
        expect(localStorageService.bind).toHaveBeenCalledWith(scope, "Checkout.default_bill_address", false, "#{prefix}_defaultasbilladdress")
        expect(localStorageService.bind).toHaveBeenCalledWith(scope, "Checkout.default_ship_address", false, "#{prefix}_defaultasshipaddress")

      it "it can retrieve data from localstorage", ->
        prefix = "order_#{scope.order.id}#{CurrentUser.id or ""}#{CurrentHubMock.hub.id}"
        scope.$digest()
        expect(localStorage.getItem("ls.#{prefix}_email")).toMatch "public"

      it "does not store secrets in local storage", ->
        Checkout.secrets =
          card_number: "superfuckingsecret"
        scope.$digest()
        keys = (localStorage.key(i) for i in [0..localStorage.length])
        for key in keys
          expect(localStorage.getItem(key)).not.toMatch Checkout.secrets.card_number

  describe "without user", ->
    beforeEach ->
      inject ($controller, $rootScope) ->
        scope = $rootScope.$new()
        ctrl = $controller 'CheckoutCtrl', {$scope: scope, Checkout: Checkout, CurrentUser: {}}

    it "is disabled", ->
      expect(scope.enabled).toEqual false

    it "does not store secrets in local storage", ->
      Checkout.secrets =
        card_number: "superfuckingsecret"
      scope.$digest()
      keys = (localStorage.key(i) for i in [0..localStorage.length])
      for key in keys
        expect(localStorage.getItem(key)).not.toMatch Checkout.secrets.card_number
