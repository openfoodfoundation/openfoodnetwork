describe 'Customer', ->
  describe "update", ->
    $httpBackend = null
    customer = null
    response = { id: 3, code: '1234' }
    RailsFlashLoaderMock = jasmine.createSpyObj('RailsFlashLoader', ['loadFlash'])

    beforeEach ->
      module 'Darkswarm'
      module ($provide) ->
        $provide.value 'RailsFlashLoader', RailsFlashLoaderMock
        null

      inject (_$httpBackend_, Customer)->
        customer = new Customer(id: 3)
        $httpBackend = _$httpBackend_

    it "nests the params inside 'customer'", ->
      $httpBackend
        .expectPUT('/api/customers/3.json', { customer: { id: 3 } })
        .respond 200, response
      customer.update()
      $httpBackend.flush()

    describe "when the request succeeds", ->
      it "shows a success flash", ->
        $httpBackend.expectPUT('/api/customers/3.json').respond 200, response
        customer.update()
        $httpBackend.flush()
        expect(RailsFlashLoaderMock.loadFlash)
          .toHaveBeenCalledWith({success: jasmine.any(String)})

    describe "when the request fails", ->
      it "shows a error flash", ->
        $httpBackend.expectPUT('/api/customers/3.json').respond 400, { error: 'Some error' }
        customer.update()
        $httpBackend.flush()
        expect(RailsFlashLoaderMock.loadFlash)
          .toHaveBeenCalledWith({error: 'Some error'})
