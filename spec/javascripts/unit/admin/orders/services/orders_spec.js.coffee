describe "Orders service", ->
  Orders = OrderResource = orders = $httpBackend = null

  beforeEach ->
    module 'admin.orders'

    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

    inject ($q, _$httpBackend_, _Orders_, _OrderResource_) ->
      Orders = _Orders_
      OrderResource = _OrderResource_
      $httpBackend = _$httpBackend_

  describe "#index", ->
    result = response = null

    beforeEach ->
      response = { orders: [{ id: 5, name: 'Order 1'}], pagination: {page: 1, pages: 1, results: 1} }
      $httpBackend.expectGET('/api/v0/orders.json').respond 200, response
      result = Orders.index()
      $httpBackend.flush()

    it "stores returned data in @byID, with ids as keys", ->
      # OrderResource returns instances of Resource rather than raw objects
      expect(Orders.byID).toDeepEqual { 5: response.orders[0] }

    it "stores returned data in @pristineByID, with ids as keys", ->
      expect(Orders.pristineByID).toDeepEqual { 5: response.orders[0] }

    it "returns an array of orders", ->
      expect(result).toDeepEqual response.orders


  describe "#save", ->
    result = null

    describe "success", ->
      order = null
      resolved = false

      beforeEach ->
        order = new OrderResource({ id: 15, number: "R12345", name: 'Order 1' })
        $httpBackend.expectPUT('/admin/orders/R12345.json').respond 200, { id: 15, name: 'Order 1'}
        Orders.save(order).then( -> resolved = true)
        $httpBackend.flush()

      it "updates the pristine copy of the order", ->
        # Resource results have extra properties ($then, $promise) that cause them to not
        # be exactly equal to the response object provided to the expectPUT clause above.
        expect(Orders.pristineByID[15]).toEqual order

      it "resolves the promise", ->
        expect(resolved).toBe(true);


    describe "failure", ->
      order = null
      rejected = false

      beforeEach ->
        order = new OrderResource( { id: 15, number: 'R12345', name: 'Order 1' } )
        $httpBackend.expectPUT('/admin/orders/R12345.json').respond 422, { error: 'obj' }
        Orders.save(order).catch( -> rejected = true)
        $httpBackend.flush()

      it "does not update the pristine copy of the order", ->
        expect(Orders.pristineByID[15]).toBeUndefined()

      it "rejects the promise", ->
        expect(rejected).toBe(true);

  describe "#saved", ->
    describe "when attributes of the object have been altered", ->
      beforeEach ->
        spyOn(Orders, "diff").and.returnValue ["attr1", "attr2"]

      it "returns false", ->
        expect(Orders.saved({})).toBe false

    describe "when attributes of the object have not been altered", ->
      beforeEach ->
        spyOn(Orders, "diff").and.returnValue []

      it "returns false", ->
        expect(Orders.saved({})).toBe true


  describe "diff", ->
    beforeEach ->
      Orders.pristineByID = { 23: { id: 23, name: "ent1", is_primary_producer: true } }

    it "returns a list of properties that have been altered", ->
      expect(Orders.diff({ id: 23, name: "order123", is_primary_producer: true })).toEqual ["name"]


  describe "resetAttribute", ->
    order = { id: 23, name: "ent1", is_primary_producer: true }

    beforeEach ->
      Orders.pristineByID = { 23: { id: 23, name: "order1", is_primary_producer: true } }

    it "resets the specified value according to the pristine record", ->
      Orders.resetAttribute(order, "name")
      expect(order.name).toEqual "order1"
