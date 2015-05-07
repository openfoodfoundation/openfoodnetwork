describe "Customers service", ->
  Customers = CustomerResource = customers = $httpBackend = null

  beforeEach ->
    module 'admin.customers'

    inject ($q, _$httpBackend_, _Customers_, _CustomerResource_) ->
      Customers = _Customers_
      CustomerResource = _CustomerResource_
      $httpBackend = _$httpBackend_
      $httpBackend.expectGET('/admin/customers.json?enterprise_id=2').respond 200, [{ id: 5, email: 'someone@email.com'}]

  describe "#index", ->
    result = null

    beforeEach ->
      expect(Customers.loaded).toBe false
      result = Customers.index(enterprise_id: 2)
      $httpBackend.flush()

    it "stores returned data in @customers, with ids as keys", ->
      # This is super weird and freaking annoying. I think resource results have extra
      # properties ($then, $promise) that cause them to not be equal to the reponse object
      # provided to the expectGET clause above.
      expect(Customers.customers).toEqual { 5: new CustomerResource({ id: 5, email: 'someone@email.com'}) }

    it "returns @customers", ->
      expect(result).toEqual Customers.customers

    it "sets @loaded to true", ->
      expect(Customers.loaded).toBe true
