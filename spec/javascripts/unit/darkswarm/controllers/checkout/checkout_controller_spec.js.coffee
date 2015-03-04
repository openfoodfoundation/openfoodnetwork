describe "CheckoutCtrl", ->
  ctrl = null
  scope = null
  Checkout = null
  CurrentUser = null
  CurrentHubMock =
    hub:
      id: 1
  storage = null

  beforeEach ->
    module("Darkswarm")
    angular.module('Darkswarm').value('user', {})
    angular.module('Darkswarm').value('currentHub', {id: 1})
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock
      null
    Checkout =
      submit: ->
      navigate: ->
      bindFieldsToLocalStorage: ->
      order:
        id: 1
        email: "public"
        user_id: 1
      secrets:
        card_number: "this is a secret"

  describe "with user", ->
    beforeEach ->
      inject ($controller, $rootScope, _storage_) ->
        storage = _storage_
        spyOn(storage, "bind").andCallThrough()
        scope = $rootScope.$new()
        CurrentUser = { id: 1 }
        ctrl = $controller 'CheckoutCtrl', {$scope: scope, Checkout: Checkout, CurrentUser: CurrentUser }

    describe "submitting", ->
      event =
        preventDefault: ->

      beforeEach ->
        spyOn(Checkout, "submit")
        scope.submitted = false

      it "delegates to the service when valid", ->
        scope.purchase(event, {$valid: true})
        expect(Checkout.submit).toHaveBeenCalled()
        expect(scope.submitted).toBe(true)

      it "does nothing when invalid", ->
        scope.purchase(event, {$valid: false})
        expect(Checkout.submit).not.toHaveBeenCalled()
        expect(scope.submitted).toBe(true)

    it "is enabled", ->
      expect(scope.enabled).toEqual true

    describe "Local storage", ->
      it "binds to localStorage when given a scope", ->
        prefix = "order_#{scope.order.id}#{CurrentUser.id or ""}#{CurrentHubMock.hub.id}"
        console.log prefix
        field = scope.fieldsToBind[0]
        expect(storage.bind).toHaveBeenCalledWith(scope, "Checkout.order.#{field}", {storeName: "#{prefix}_#{field}"})
        expect(storage.bind).toHaveBeenCalledWith(scope, "Checkout.ship_address_same_as_billing", {storeName: "#{prefix}_sameasbilling", defaultValue: true})

      it "it can retrieve data from localstorage", ->
        prefix = "order_#{scope.order.id}#{CurrentUser.id or ""}#{CurrentHubMock.hub.id}"
        expect(localStorage.getItem("#{prefix}_email")).toMatch "public"

      it "does not store secrets in local storage", ->
        Checkout.secrets =
          card_number: "superfuckingsecret"
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
      keys = (localStorage.key(i) for i in [0..localStorage.length])
      for key in keys
        expect(localStorage.getItem(key)).not.toMatch Checkout.secrets.card_number
