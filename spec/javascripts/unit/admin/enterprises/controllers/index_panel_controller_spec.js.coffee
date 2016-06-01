describe "indexPanelCtrl", ->
  ctrl = null
  scope = null
  Enterprises = null

  beforeEach ->
    module('admin.enterprises')
    inject ($controller, $rootScope, _Enterprises_) ->
      scope = $rootScope.$new()
      $rootScope.object = { some: "object" }
      Enterprises = _Enterprises_
      ctrl = $controller 'indexPanelCtrl', {$scope: scope, Enterprises: Enterprises}

  describe "initialisation", ->
    it "pulls object from the parent scope and points the 'enterprise' on the current scope to it", inject ($rootScope) ->
      expect(scope.enterprise).toBe $rootScope.object

  describe "saving changes on an enterprise", ->
    describe "when changes have been made", ->
      deferred = null

      beforeEach inject ($q) ->
        spyOn(scope, "saved").and.returnValue false
        spyOn(scope, "$emit")
        deferred = $q.defer()
        spyOn(Enterprises, "save").and.returnValue(deferred.promise)
        scope.save()

      it "sets scope.saving to true", ->
        expect(scope.saving).toBe true

      describe "when the save is successful", ->
        beforeEach inject ($rootScope) ->
          deferred.resolve()
          $rootScope.$digest()

        it "sets scope.saving to false", ->
          expect(scope.saving).toBe false

        it "emits an 'enterprise:updated' event", ->
          expect(scope.$emit).toHaveBeenCalledWith("enterprise:updated", scope.enterprise)

      describe "when the save is unsuccessful", ->
        beforeEach inject ($rootScope) ->
          deferred.reject({ status: 404 })
          $rootScope.$digest()

        it "sets scope.saving to false", ->
          expect(scope.saving).toBe false

        it "does not emit an 'enterprise:updated' event", ->
          expect(scope.$emit).not.toHaveBeenCalled()
