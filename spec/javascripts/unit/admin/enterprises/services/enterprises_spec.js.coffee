describe "Enterprises service", ->
  Enterprises = EnterpriseResource = enterprises = $httpBackend = null

  beforeEach ->
    module 'admin.enterprises'

    inject ($q, _$httpBackend_, _Enterprises_, _EnterpriseResource_) ->
      Enterprises = _Enterprises_
      EnterpriseResource = _EnterpriseResource_
      $httpBackend = _$httpBackend_
      $httpBackend.expectGET('/admin/enterprises.json').respond 200, [{ id: 5, name: 'Enterprise 1'}]

  describe "#index", ->
    result = null

    beforeEach ->
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
