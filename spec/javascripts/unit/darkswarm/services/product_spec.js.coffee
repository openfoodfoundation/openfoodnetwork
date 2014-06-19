describe 'Product service', ->
  $httpBackend = null
  Product = null
  Enterprises = null
  product =
    test: "cats"
    supplier:
      id: 9

  beforeEach ->
    module 'Darkswarm'
    inject ($injector, _$httpBackend_)->
      Product = $injector.get("Product")
      Enterprises = $injector.get("Enterprises")
      $httpBackend = _$httpBackend_

  it "Fetches products from the backend on init", ->
    $httpBackend.expectGET("/shop/products").respond([product])
    $httpBackend.flush()
    expect(Product.products[0].test).toEqual "cats" 

  it "dereferences suppliers", ->
    Enterprises.enterprises_by_id = 
      {id: 9, name: "test"}
    $httpBackend.expectGET("/shop/products").respond([{supplier : {id: 9}}])
    $httpBackend.flush()
    expect(Product.products[0].supplier).toBe Enterprises.enterprises_by_id["9"]
