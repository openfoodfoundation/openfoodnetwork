describe 'Customers', ->
  describe "index", ->
    $httpBackend = null
    Customers = null
    customerList = ['somecustomer']

    beforeEach ->
      module 'Darkswarm'
      module ($provide) ->
        $provide.value 'RailsFlashLoader', null
        null

      inject (_$httpBackend_, _Customers_)->
        Customers = _Customers_
        $httpBackend = _$httpBackend_

    it "asks for customers and returns @all, promises to populate via @load", ->
      spyOn(Customers,'load').and.callThrough()
      $httpBackend.expectGET('/api/v0/customers.json').respond 200, customerList
      result = Customers.index()
      $httpBackend.flush()
      expect(Customers.load).toHaveBeenCalled()
      expect(result).toEqual customerList
      expect(Customers.all).toEqual customerList
