describe "SubscriptionLineItemsCtrl", ->
  scope = null
  http = null
  subscription = { id: 1 }
  subscriptionLineItem = { id: 2, variant_id: 44 }

  beforeEach ->
    module('admin.subscriptions')

    inject ($controller, $rootScope, $httpBackend) ->
      scope = $rootScope
      http = $httpBackend
      scope.subscription = subscription
      subscription.subscription_line_items = [subscriptionLineItem]
      $controller 'SubscriptionLineItemsController', {$scope: scope}

  describe "match", ->
    describe "when newItem.variant_id matches an existing sli", ->
      beforeEach ->
        scope.newItem.variant_id = 44

      it "returns the matching sli ", ->
        expect(scope.match()).toEqual subscriptionLineItem

    describe "when newItem.variant_id dosn't match an existing sli", ->
      beforeEach ->
        scope.newItem.variant_id = 43

      it "returns null", ->
        expect(scope.match()).toEqual null

  describe "addSubscriptionLineItem", ->
    beforeEach ->
      scope.subscription_form = jasmine.createSpyObj('subscription_form', ['$setDirty'])
      subscription.buildItem = jasmine.createSpy('buildItem')

    describe "when an item with a matching variant_id is found", ->
      match = null

      beforeEach ->
        match = { }
        scope.newItem.someProperty = "lalala"
        spyOn(scope, "match").and.returnValue(match)

      describe "when the matching item isn't marked for destruction", ->
        InfoDialog = null

        beforeEach inject (_InfoDialog_) ->
          InfoDialog = _InfoDialog_
          spyOn(InfoDialog, "open")

        it "shows a message to the user", ->
          scope.addSubscriptionLineItem()
          expect(InfoDialog.open).toHaveBeenCalled()

      describe "when the matching item is marked for destruction", ->
        beforeEach -> match._destroy = true

        it "remove the delete flag from the match and merges properties from scope.newItem", ->
          scope.addSubscriptionLineItem()
          expect(match._destroy).toBeUndefined()
          expect(match.someProperty).toEqual "lalala"

    describe "when no match is found", ->
      beforeEach ->
        spyOn(scope, "match").and.returnValue(null)

      it "sets the form to $dirty and called buildItem on scope.subscription", ->
        scope.addSubscriptionLineItem()
        expect(scope.subscription_form.$setDirty).toHaveBeenCalled()
        expect(subscription.buildItem).toHaveBeenCalledWith(scope.newItem)
