describe 'Product service', ->
  $httpBackend = null
  Product = null

  beforeEach ->
    module 'Darkswarm'
    inject ($injector, _$httpBackend_)->
      Product = $injector.get("Product")
      $httpBackend = _$httpBackend_

  it "Fetches products from the backend on init", ->
    $httpBackend.expectGET("/shop/products").respond([{test : "cats"}])
    $httpBackend.flush()
    expect(Product.data.products[0].test).toEqual "cats" 
