describe "OrderCycles service", ->
  OrderCycles = OrderCycleResource = orderCycles = $httpBackend = null

  beforeEach ->
    module 'admin.orderCycles'

    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

    inject ($q, _$httpBackend_, _OrderCycles_, _OrderCycleResource_) ->
      OrderCycles = _OrderCycles_
      OrderCycleResource = _OrderCycleResource_
      $httpBackend = _$httpBackend_

  describe "#index", ->
    result = response = null

    beforeEach ->
      response = [{ id: 5, name: 'OrderCycle 1'}]

    describe "when no params are passed", ->
      beforeEach ->
        $httpBackend.expectGET('/admin/order_cycles.json').respond 200, response
        result = OrderCycles.index()
        $httpBackend.flush()

      it "stores returned data in @byID, with ids as keys", ->
        # OrderCycleResource returns instances of Resource rather than raw objects
        expect(OrderCycles.byID).toDeepEqual { 5: response[0] }

      it "stores returned data in @pristineByID, with ids as keys", ->
        expect(OrderCycles.pristineByID).toDeepEqual { 5: response[0] }

      it "returns an array of orderCycles", ->
        expect(result).toDeepEqual response

    describe "when no params are passed", ->
      beforeEach ->
        params = { someParam: 'someVal'}
        $httpBackend.expectGET('/admin/order_cycles.json?someParam=someVal').respond 200, response
        result = OrderCycles.index(params)
        $httpBackend.flush()

      it "returns an array of orderCycles", ->
        expect(result).toDeepEqual response


  describe "#save", ->
    result = null

    describe "success", ->
      orderCycle = null
      resolved = false

      beforeEach ->
        orderCycle = new OrderCycleResource({ id: 15, name: 'OrderCycle 1' })
        $httpBackend.expectPUT('/admin/order_cycles/15.json').respond 200, { id: 15, name: 'OrderCycle 1'}
        OrderCycles.save(orderCycle).then( -> resolved = true)
        $httpBackend.flush()

      it "updates the pristine copy of the orderCycle", ->
        # Resource results have extra properties ($then, $promise) that cause them to not
        # be exactly equal to the response object provided to the expectPUT clause above.
        expect(OrderCycles.pristineByID[15]).toEqual orderCycle

      it "resolves the promise", ->
        expect(resolved).toBe(true);


    describe "failure", ->
      orderCycle = null
      rejected = false

      beforeEach ->
        orderCycle = new OrderCycleResource( { id: 15, name: 'OrderCycle 1' } )
        $httpBackend.expectPUT('/admin/order_cycles/15.json').respond 422, { error: 'obj' }
        OrderCycles.save(orderCycle).catch( -> rejected = true)
        $httpBackend.flush()

      it "does not update the pristine copy of the orderCycle", ->
        expect(OrderCycles.pristineByID[15]).toBeUndefined()

      it "rejects the promise", ->
        expect(rejected).toBe(true);

  describe "#saved", ->
    describe "when attributes of the object have been altered", ->
      beforeEach ->
        spyOn(OrderCycles, "diff").and.returnValue ["attr1", "attr2"]

      it "returns false", ->
        expect(OrderCycles.saved({})).toBe false

    describe "when attributes of the object have not been altered", ->
      beforeEach ->
        spyOn(OrderCycles, "diff").and.returnValue []

      it "returns false", ->
        expect(OrderCycles.saved({})).toBe true


  describe "diff", ->
    beforeEach ->
      OrderCycles.pristineByID = { 23: { id: 23, name: "orderCycle321", orders_open_at: '123' } }

    it "returns a list of properties that have been altered, if they are in attrsToSave()", ->
      spyOn(OrderCycles, "attrsToSave").and.returnValue(["orders_open_at"])
      expect(OrderCycles.diff({ id: 23, name: "orderCycle123", orders_open_at: '321' })).toEqual ["orders_open_at"]


  describe "resetAttribute", ->
    orderCycle = { id: 23, name: "ent1", is_primary_producer: true }

    beforeEach ->
      OrderCycles.pristineByID = { 23: { id: 23, name: "orderCycle1", is_primary_producer: true } }

    it "resets the specified value according to the pristine record", ->
      OrderCycles.resetAttribute(orderCycle, "name")
      expect(orderCycle.name).toEqual "orderCycle1"
