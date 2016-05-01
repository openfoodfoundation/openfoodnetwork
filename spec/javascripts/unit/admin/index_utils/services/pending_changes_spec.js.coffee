describe "Pending Changes", ->
  resourcesMock = pendingChanges = null

  beforeEach ->

    resourcesMock =
      update: jasmine.createSpy('update').and.callFake (change) ->
        $promise:
          then: (successFn, errorFn) ->
            return successFn({propertyName: "new_value"}) if change.success
            errorFn("error")

    module 'admin.indexUtils', ($provide) ->
      $provide.value 'resources', resourcesMock
      return

    inject (_pendingChanges_) ->
      pendingChanges = _pendingChanges_


  describe "adding a new change", ->
    it "adds a new object with key of id if it does not already exist", ->
      expect(pendingChanges.pendingChanges).toEqual {}
      expect(pendingChanges.pendingChanges["1"]).not.toBeDefined()
      pendingChanges.add 1, "propertyName", { a: 1 }
      expect(pendingChanges.pendingChanges["1"]).toBeDefined()

    it "adds a new object with key of the altered attribute name if it does not already exist", ->
      pendingChanges.add 1, "propertyName", { a: 1 }
      expect(pendingChanges.pendingChanges["1"]).toBeDefined()
      expect(pendingChanges.pendingChanges["1"]["propertyName"]).toEqual { a: 1 }

    it "replaces the existing object when adding a change to an attribute which already exists", ->
      pendingChanges.add 1, "propertyName", { a: 1 }
      expect(pendingChanges.pendingChanges["1"]).toBeDefined()
      expect(pendingChanges.pendingChanges["1"]["propertyName"]).toEqual { a: 1 }
      pendingChanges.add 1, "propertyName", { b: 2 }
      expect(pendingChanges.pendingChanges["1"]["propertyName"]).toEqual { b: 2 }

   it "adds an attribute to key to a line item object when one already exists", ->
      pendingChanges.add 1, "propertyName1", { a: 1 }
      pendingChanges.add 1, "propertyName2", { b: 2 }
      expect(pendingChanges.pendingChanges["1"]).toEqual { propertyName1: { a: 1}, propertyName2: { b: 2 } }

  describe "removing all existing changes", ->
    it "resets pendingChanges object", ->
      pendingChanges.pendingChanges = { 1: { "propertyName1": { a: 1 }, "propertyName2": { b: 2 } } }
      expect(pendingChanges.pendingChanges["1"]["propertyName1"]).toBeDefined()
      expect(pendingChanges.pendingChanges["1"]["propertyName2"]).toBeDefined()
      pendingChanges.removeAll()
      expect(pendingChanges.pendingChanges["1"]).not.toBeDefined()
      expect(pendingChanges.pendingChanges).toEqual {}

  describe "removing an existing change", ->
    it "deletes a change if it exists", ->
      pendingChanges.pendingChanges = { 1: { "propertyName1": { a: 1 }, "propertyName2": { b: 2 } } }
      expect(pendingChanges.pendingChanges["1"]["propertyName1"]).toBeDefined()
      pendingChanges.remove 1, "propertyName1"
      expect(pendingChanges.pendingChanges["1"]).toBeDefined()
      expect(pendingChanges.pendingChanges["1"]["propertyName1"]).not.toBeDefined()

    it "deletes a line item object if it is empty", ->
      pendingChanges.pendingChanges = { 1: { "propertyName1": { a: 1 } } }
      expect(pendingChanges.pendingChanges["1"]["propertyName1"]).toBeDefined()
      pendingChanges.remove 1, "propertyName1"
      expect(pendingChanges.pendingChanges["1"]).not.toBeDefined()

    it "does nothing if key with specified attribute does not exist", ->
      pendingChanges.pendingChanges = { 1: { "propertyName1": { a: 1 } } }
      expect(pendingChanges.pendingChanges["1"]["propertyName1"]).toBeDefined()
      pendingChanges.remove 1, "propertyName2"
      expect(pendingChanges.pendingChanges["1"]["propertyName1"]).toEqual { a: 1 }

    it "does nothing if key with specified id does not exist", ->
      pendingChanges.pendingChanges = { 1: { "propertyName1": { a: 1 } } }
      expect(pendingChanges.pendingChanges["1"]["propertyName1"]).toBeDefined()
      pendingChanges.remove 2, "propertyName1"
      expect(pendingChanges.pendingChanges["1"]).toEqual { "propertyName1": { a: 1 } }

  describe "submitting an individual change to the server", ->
    change = null
    beforeEach ->
      object = {id: 1}
      scope = { reset: jasmine.createSpy('reset'), success: jasmine.createSpy('success'), error: jasmine.createSpy('error') };
      attr = "propertyName"
      change = { object: object, scope: scope, attr: attr }


    it "sends the correct object to dataSubmitter", ->
      pendingChanges.submit change
      expect(resourcesMock.update.calls.count()).toBe 1
      expect(resourcesMock.update).toHaveBeenCalledWith change

    describe "successful request", ->
      beforeEach ->
        change.success = true

      it "calls remove with id and attribute name", ->
        spyOn(pendingChanges, "remove").and.callFake(->)
        pendingChanges.submit change
        expect(pendingChanges.remove.calls.count()).toBe 1
        expect(pendingChanges.remove).toHaveBeenCalledWith 1, "propertyName"

      it "calls reset on the relevant scope", ->
        pendingChanges.submit change
        expect(change.scope.reset).toHaveBeenCalledWith "new_value"

      it "calls success on the relevant scope", ->
        pendingChanges.submit change
        expect(change.scope.success).toHaveBeenCalled()

    describe "unsuccessful request", ->
      beforeEach ->
        change.success = false

      it "does not call remove", ->
        spyOn(pendingChanges, "remove").and.callFake(->)
        pendingChanges.submit change
        expect(pendingChanges.remove).not.toHaveBeenCalled()

      it "does not call reset on the relevant scope", ->
        pendingChanges.submit change
        expect(change.scope.reset).not.toHaveBeenCalled()

      it "calls error on the relevant scope", ->
        pendingChanges.submit change
        expect(change.scope.error).toHaveBeenCalled()

  describe "cycling through all changes to submit to server", ->
    it "sends the correct object to dataSubmitter", ->
      spyOn(pendingChanges, "submit").and.callFake(->)
      pendingChanges.pendingChanges =
        1: { "prop1": { attr: "prop1", value: 1 }, "prop2": { attr: "prop2", value: 2 } }
        2: { "prop1": { attr: "prop1", value: 2 }, "prop2": { attr: "prop2", value: 4 } }
        7: { "prop2": { attr: "prop2", value: 5 } }
      pendingChanges.submitAll()
      expect(pendingChanges.submit.calls.count()).toBe 5
      expect(pendingChanges.submit).toHaveBeenCalledWith { attr: "prop1", value: 1 }
      expect(pendingChanges.submit).toHaveBeenCalledWith { attr: "prop2", value: 2 }
      expect(pendingChanges.submit).toHaveBeenCalledWith { attr: "prop1", value: 2 }
      expect(pendingChanges.submit).toHaveBeenCalledWith { attr: "prop2", value: 4 }
      expect(pendingChanges.submit).toHaveBeenCalledWith { attr: "prop2", value: 5 }

    it "returns an array of promises representing all sumbit requests", ->
      spyOn(pendingChanges, "submit").and.callFake (change) -> change.value
      pendingChanges.pendingChanges =
        1: { "prop1": { attr: "prop1", value: 1 } }
        2: { "prop1": { attr: "prop1", value: 2 }, "prop2": { attr: "prop1", value: 4 } }
      expect(pendingChanges.submitAll()).toEqual [ 1, 2, 4 ]
