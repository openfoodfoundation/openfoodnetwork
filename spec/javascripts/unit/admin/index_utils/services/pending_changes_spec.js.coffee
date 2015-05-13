describe "Pending Changes", ->
  dataSubmitter = pendingChanges = null

  beforeEach ->
    dataSubmitter = jasmine.createSpy('dataSubmitter').andReturn {
      then: (thenFn) ->
        thenFn({propertyName: "new_value"})
    }
    module 'admin.indexUtils', ($provide) ->
      $provide.value 'dataSubmitter', dataSubmitter
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
      scope = { reset: jasmine.createSpy('reset') };
      attr = "propertyName"
      change = { object: object, scope: scope, attr: attr }

    it "sends the correct object to dataSubmitter", ->
      pendingChanges.submit change
      expect(dataSubmitter.calls.length).toEqual 1
      expect(dataSubmitter).toHaveBeenCalledWith change

    it "calls remove with id and attribute name", ->
      spyOn(pendingChanges, "remove").andCallFake(->)
      pendingChanges.submit change
      expect(pendingChanges.remove.calls.length).toEqual 1
      expect(pendingChanges.remove).toHaveBeenCalledWith 1, "propertyName"

    it "calls reset on the relevant scope", ->
      pendingChanges.submit change
      expect(change.scope.reset).toHaveBeenCalledWith "new_value"

  describe "cycling through all changes to submit to server", ->
    it "sends the correct object to dataSubmitter", ->
      spyOn(pendingChanges, "submit").andCallFake(->)
      pendingChanges.pendingChanges =
        1: { "prop1": { attr: "prop1", value: 1 }, "prop2": { attr: "prop2", value: 2 } }
        2: { "prop1": { attr: "prop1", value: 2 }, "prop2": { attr: "prop2", value: 4 } }
        7: { "prop2": { attr: "prop2", value: 5 } }
      pendingChanges.submitAll()
      expect(pendingChanges.submit.calls.length).toEqual 5
      expect(pendingChanges.submit).toHaveBeenCalledWith { attr: "prop1", value: 1 }
      expect(pendingChanges.submit).toHaveBeenCalledWith { attr: "prop2", value: 2 }
      expect(pendingChanges.submit).toHaveBeenCalledWith { attr: "prop1", value: 2 }
      expect(pendingChanges.submit).toHaveBeenCalledWith { attr: "prop2", value: 4 }
      expect(pendingChanges.submit).toHaveBeenCalledWith { attr: "prop2", value: 5 }

    it "returns an array of promises representing all sumbit requests", ->
      spyOn(pendingChanges, "submit").andCallFake (change) -> change.value
      pendingChanges.pendingChanges =
        1: { "prop1": { attr: "prop1", value: 1 } }
        2: { "prop1": { attr: "prop1", value: 2 }, "prop2": { attr: "prop1", value: 4 } }
      expect(pendingChanges.submitAll()).toEqual [ 1, 2, 4 ]
