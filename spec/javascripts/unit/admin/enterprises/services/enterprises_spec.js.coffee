describe "Enterprises service", ->
  Enterprises = EnterpriseResource = enterprises = $httpBackend = null

  beforeEach ->
    module 'admin.enterprises'

    inject ($q, _$httpBackend_, _Enterprises_, _EnterpriseResource_) ->
      Enterprises = _Enterprises_
      EnterpriseResource = _EnterpriseResource_
      $httpBackend = _$httpBackend_


  describe "#index", ->
    result = null

    beforeEach ->
      $httpBackend.expectGET('/admin/enterprises.json').respond 200, [{ id: 5, name: 'Enterprise 1'}]
      expect(Enterprises.loaded).toBe false
      result = Enterprises.index()
      $httpBackend.flush()

    it "stores returned data in @enterprises, with ids as keys", ->
      # This is super weird and freaking annoying. I think resource results have extra
      # properties ($then, $promise) that cause them to not be equal to the reponse object
      # provided to the expectGET clause above.
      expect(Enterprises.enterprises).toEqual [ new EnterpriseResource({ id: 5, name: 'Enterprise 1'}) ]

    it "returns @enterprises", ->
      expect(result).toEqual Enterprises.enterprises

    it "sets @loaded to true", ->
      expect(Enterprises.loaded).toBe true


  describe "#save", ->
    result = null

    describe "success", ->
      enterprise = null
      resolved = false

      beforeEach ->
        enterprise = new EnterpriseResource( { id: 15, permalink: 'enterprise1', name: 'Enterprise 1' } )
        $httpBackend.expectPUT('/admin/enterprises/enterprise1.json').respond 200, { id: 15, name: 'Enterprise 1'}
        Enterprises.save(enterprise).then( -> resolved = true)
        $httpBackend.flush()

      it "updates the pristine copy of the enterprise", ->
        # Resource results have extra properties ($then, $promise) that cause them to not
        # be exactly equal to the response object provided to the expectPUT clause above.
        expect(Enterprises.pristine_by_id[15]).toEqual enterprise

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
        expect(Enterprises.pristine_by_id[15]).toBeUndefined()

      it "rejects the promise", ->
        expect(rejected).toBe(true);

  describe "#saved", ->
    describe "when attributes of the object have been altered", ->
      beforeEach ->
        spyOn(Enterprises, "diff").andReturn ["attr1", "attr2"]

      it "returns false", ->
        expect(Enterprises.saved({})).toBe false

    describe "when attributes of the object have not been altered", ->
      beforeEach ->
        spyOn(Enterprises, "diff").andReturn []

      it "returns false", ->
        expect(Enterprises.saved({})).toBe true


  describe "diff", ->
    beforeEach ->
      Enterprises.pristine_by_id = { 23: { id: 23, name: "ent1", is_primary_producer: true } }

    it "returns a list of properties that have been altered", ->
      expect(Enterprises.diff({ id: 23, name: "enterprise123", is_primary_producer: true })).toEqual ["name"]


  describe "resetAttribute", ->
    enterprise = { id: 23, name: "ent1", is_primary_producer: true }

    beforeEach ->
      Enterprises.pristine_by_id = { 23: { id: 23, name: "enterprise1", is_primary_producer: true } }

    it "resets the specified value according to the pristine record", ->
      Enterprises.resetAttribute(enterprise, "name")
      expect(enterprise.name).toEqual "enterprise1"
