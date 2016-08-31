describe "Enterprises service", ->
  Enterprises = EnterpriseResource = enterprises = $httpBackend = null

  beforeEach ->
    module 'admin.enterprises'

    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

    inject ($q, _$httpBackend_, _Enterprises_, _EnterpriseResource_) ->
      Enterprises = _Enterprises_
      EnterpriseResource = _EnterpriseResource_
      $httpBackend = _$httpBackend_

  describe "#index", ->
    result = response = null

    beforeEach ->
      response = [{ id: 5, name: 'Enterprise 1'}]

    describe "when no params are passed", ->
      beforeEach ->
        $httpBackend.expectGET('/admin/enterprises.json').respond 200, response
        result = Enterprises.index()
        $httpBackend.flush()

      it "stores returned data in @enterprisesByID, with ids as keys", ->
        # EnterpriseResource returns instances of Resource rather than raw objects
        expect(Enterprises.enterprisesByID).toDeepEqual { 5: response[0] }

      it "stores returned data in @pristineByID, with ids as keys", ->
        expect(Enterprises.pristineByID).toDeepEqual { 5: response[0] }

      it "returns an array of enterprises", ->
        expect(result).toDeepEqual response

    describe "when params are passed", ->
      beforeEach ->
        params = { someParam: 'someVal'}
        $httpBackend.expectGET('/admin/enterprises.json?someParam=someVal').respond 200, response
        result = Enterprises.index(params)
        $httpBackend.flush()

      it "returns an array of enterprises", ->
        expect(result).toDeepEqual response


  describe "#save", ->
    result = null

    describe "success", ->
      enterprise = null
      resolved = false

      beforeEach ->
        enterprise = new EnterpriseResource({ id: 15, permalink: 'enterprise1', name: 'Enterprise 1' })
        $httpBackend.expectPUT('/admin/enterprises/enterprise1.json').respond 200, { id: 15, name: 'Enterprise 1'}
        Enterprises.save(enterprise).then( -> resolved = true)
        $httpBackend.flush()

      it "updates the pristine copy of the enterprise", ->
        # Resource results have extra properties ($then, $promise) that cause them to not
        # be exactly equal to the response object provided to the expectPUT clause above.
        expect(Enterprises.pristineByID[15]).toEqual enterprise

      it "resolves the promise", ->
        expect(resolved).toBe(true);


    describe "failure", ->
      enterprise = null
      rejected = false

      beforeEach ->
        enterprise = new EnterpriseResource( { id: 15, permalink: 'permalink', name: 'Enterprise 1' } )
        $httpBackend.expectPUT('/admin/enterprises/permalink.json').respond 422, { error: 'obj' }
        Enterprises.save(enterprise).catch( -> rejected = true)
        $httpBackend.flush()

      it "does not update the pristine copy of the enterprise", ->
        expect(Enterprises.pristineByID[15]).toBeUndefined()

      it "rejects the promise", ->
        expect(rejected).toBe(true);

  describe "#saved", ->
    describe "when attributes of the object have been altered", ->
      beforeEach ->
        spyOn(Enterprises, "diff").and.returnValue ["attr1", "attr2"]

      it "returns false", ->
        expect(Enterprises.saved({})).toBe false

    describe "when attributes of the object have not been altered", ->
      beforeEach ->
        spyOn(Enterprises, "diff").and.returnValue []

      it "returns false", ->
        expect(Enterprises.saved({})).toBe true


  describe "diff", ->
    beforeEach ->
      Enterprises.pristineByID = { 23: { id: 23, name: "ent1", is_primary_producer: true } }

    it "returns a list of properties that have been altered", ->
      expect(Enterprises.diff({ id: 23, name: "enterprise123", is_primary_producer: true })).toEqual ["name"]


  describe "resetAttribute", ->
    enterprise = { id: 23, name: "ent1", is_primary_producer: true }

    beforeEach ->
      Enterprises.pristineByID = { 23: { id: 23, name: "enterprise1", is_primary_producer: true } }

    it "resets the specified value according to the pristine record", ->
      Enterprises.resetAttribute(enterprise, "name")
      expect(enterprise.name).toEqual "enterprise1"
