describe "LineItems service", ->
  LineItems = LineItemResource = lineItems = $httpBackend = $rootScope = $timeout = null

  beforeEach ->
    module 'admin.lineItems'

    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

    inject ($q, _$httpBackend_, _LineItems_, _LineItemResource_) ->
      LineItems = _LineItems_
      LineItemResource = _LineItemResource_
      $httpBackend = _$httpBackend_

  describe "#index", ->
    result = response = line_item = null

    beforeEach ->
      line_item = { id: 5, name: 'LineItem 1'}
      response = { line_items: [line_item] }
      $httpBackend.expectGET('/admin/bulk_line_items.json').respond 200, response
      result = LineItems.index()
      $httpBackend.flush()

    it "stores returned data in @byID, with ids as keys", ->
      # LineItemResource returns instances of Resource rather than raw objects
      expect(LineItems.byID).toDeepEqual { 5: response['line_items'][0] }

    it "stores returned data in @pristineByID, with ids as keys", ->
      expect(LineItems.pristineByID).toDeepEqual { 5: response['line_items'][0] }

    it "stores returned data in @all, as an array", ->
      expect(LineItems.all).toDeepEqual [line_item]

    it "returns an array of line items", ->
      expect(result).toDeepEqual [line_item]

  describe "#save", ->
    describe "success", ->
      lineItem = null
      resolved = false

      beforeEach ->
        lineItem = new LineItemResource({ id: 15, order: { number: '12345678'} })
        $httpBackend.expectPUT('/admin/bulk_line_items/15.json').respond 200, { id: 15, name: 'LineItem 1'}
        LineItems.save(lineItem).then( -> resolved = true)
        $httpBackend.flush()

      it "updates the pristine copy of the lineItem", ->
        # Resource results have extra properties ($then, $promise) that cause them to not
        # be exactly equal to the response object provided to the expectPUT clause above.
        expect(LineItems.pristineByID[15]).toEqual lineItem

      it "resolves the promise", ->
        expect(resolved).toBe(true);


    describe "failure", ->
      lineItem = null
      rejected = false

      beforeEach ->
        lineItem = new LineItemResource( { id: 15, order: { number: '12345678'} } )
        $httpBackend.expectPUT('/admin/bulk_line_items/15.json').respond 422, { error: 'obj' }
        LineItems.save(lineItem).catch( -> rejected = true)
        $httpBackend.flush()

      it "does not update the pristine copy of the lineItem", ->
        expect(LineItems.pristineByID[15]).toBeUndefined()

      it "rejects the promise", ->
        expect(rejected).toBe(true);

  describe "#isSaved", ->
    describe "when attributes of the object have been altered", ->
      beforeEach ->
        spyOn(LineItems, "diff").and.returnValue ["attr1", "attr2"]

      it "returns false", ->
        expect(LineItems.isSaved({})).toBe false

    describe "when attributes of the object have not been altered", ->
      beforeEach ->
        spyOn(LineItems, "diff").and.returnValue []

      it "returns false", ->
        expect(LineItems.isSaved({})).toBe true


  describe "diff", ->
    beforeEach ->
      LineItems.pristineByID = { 23: { id: 23, price: 15, quantity: 3, something: 3 } }

    it "returns a list of properties that have been altered and are in the list of updateable attrs", ->
      expect(LineItems.diff({ id: 23, price: 12, quantity: 3 })).toEqual ["price"]
      expect(LineItems.diff({ id: 23, price: 15, something: 1 })).toEqual []


  describe "resetAttribute", ->
    lineItem = { id: 23, price: 15 }

    beforeEach ->
      LineItems.pristineByID = { 23: { id: 23, price: 12, quantity: 3 } }

    it "resets the specified value according to the pristine record", ->
      LineItems.resetAttribute(lineItem, "price")
      expect(lineItem.price).toEqual 12

  describe "#delete", ->
    describe "success", ->
      callback = jasmine.createSpy("callback")
      lineItem = null
      resolved = rejected = false

      beforeEach ->
        lineItem = new LineItemResource({ id: 15, order: { number: '12345678'} })
        LineItems.pristineByID[15] = lineItem
        LineItems.byID[15] = lineItem
        LineItems.all = [lineItem]
        $httpBackend.expectDELETE('/admin/bulk_line_items/15.json').respond 200, { id: 15, name: 'LineItem 1'}
        LineItems.delete(lineItem, callback).then( -> resolved = true).catch( -> rejected = true)
        $httpBackend.flush()

      it "updates the pristine copy of the lineItem", ->
        expect(LineItems.pristineByID[15]).toBeUndefined()
        expect(LineItems.byID[15]).toBeUndefined()
        expect(LineItems.all).toEqual([])

      it "runs the callback", ->
        expect(callback).toHaveBeenCalled()

      it "resolves the promise", ->
        expect(resolved).toBe(true)
        expect(rejected).toBe(false)


    describe "failure", ->
      callback = jasmine.createSpy("callback")
      lineItem = null
      resolved = rejected = false

      beforeEach ->
        lineItem = new LineItemResource({ id: 15, order: { number: '12345678'} })
        LineItems.pristineByID[15] = lineItem
        LineItems.byID[15] = lineItem
        $httpBackend.expectDELETE('/admin/bulk_line_items/15.json').respond 422, { error: 'obj' }
        LineItems.delete(lineItem, callback).then( -> resolved = true).catch( -> rejected = true)
        $httpBackend.flush()

      it "does not update the pristine copy of the lineItem", ->
        expect(LineItems.pristineByID[15]).toBeDefined()
        expect(LineItems.byID[15]).toBeDefined()

      it "does not run the callback", ->
        expect(callback).not.toHaveBeenCalled()

      it "rejects the promise", ->
        expect(resolved).toBe(false)
        expect(rejected).toBe(true)
