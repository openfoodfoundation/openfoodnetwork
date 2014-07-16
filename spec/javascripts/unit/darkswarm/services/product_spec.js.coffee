describe 'Product service', ->
  $httpBackend = null
  Product = null
  Enterprises = null
  CurrentHubMock = {} 
  product =
    test: "cats"
    supplier:
      id: 9
    price: 11
    variants: []
  beforeEach ->
    module 'Darkswarm'
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock 
      null
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

  describe "determining the price to display for a product", ->
    it "displays the product price when the product does not have variants", ->
      $httpBackend.expectGET("/shop/products").respond([product])
      $httpBackend.flush()
      expect(Product.products[0].price).toEqual 11.00

    it "displays the minimum variant price when the product has variants", ->
      product.variants = [{price: 22}, {price: 33}]
      $httpBackend.expectGET("/shop/products").respond([product])
      $httpBackend.flush()
      expect(Product.products[0].price).toEqual 22
