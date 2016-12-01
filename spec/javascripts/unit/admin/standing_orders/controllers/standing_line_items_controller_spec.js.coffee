describe "StandingLineItemsCtrl", ->
  scope = null
  http = null
  standingOrder = { id: 1 }
  standingLineItem = { id: 2, variant_id: 44 }

  beforeEach ->
    module('admin.standingOrders')

    inject ($controller, $rootScope, $httpBackend) ->
      scope = $rootScope
      http = $httpBackend
      scope.standingOrder = standingOrder
      standingOrder.standing_line_items = [standingLineItem]
      $controller 'StandingLineItemsController', {$scope: scope}

  describe "match", ->
    describe "when newItem.variant_id matches an existing sli", ->
      beforeEach ->
        scope.newItem.variant_id = 44

      it "returns the matching sli ", ->
        expect(scope.match()).toEqual standingLineItem

    describe "when newItem.variant_id dosn't match an existing sli", ->
      beforeEach ->
        scope.newItem.variant_id = 43

      it "returns null", ->
        expect(scope.match()).toEqual null

  describe "addStandingLineItem", ->
    beforeEach ->
      scope.standing_order_form = jasmine.createSpyObj('standing_order_form', ['$setDirty'])
      standingOrder.buildItem = jasmine.createSpy('buildItem')

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
          scope.addStandingLineItem()
          expect(InfoDialog.open).toHaveBeenCalled()

      describe "when the matching item is marked for destruction", ->
        beforeEach -> match._destroy = true

        it "remove the delete flag from the match and merges properties from scope.newItem", ->
          scope.addStandingLineItem()
          expect(match._destroy).toBeUndefined()
          expect(match.someProperty).toEqual "lalala"

    describe "when no match is found", ->
      beforeEach ->
        spyOn(scope, "match").and.returnValue(null)

      it "sets the form to $dirty and called buildItem on scope.standingOrder", ->
        scope.addStandingLineItem()
        expect(scope.standing_order_form.$setDirty).toHaveBeenCalled()
        expect(standingOrder.buildItem).toHaveBeenCalledWith(scope.newItem)
