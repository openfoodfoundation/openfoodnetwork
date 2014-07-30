describe 'Products service', ->
  $httpBackend = null
  Products = null
  Enterprises = null
  Variants = null
  Cart = null
  CurrentHubMock = {} 
  currentOrder = null
  product = null

  beforeEach ->
    product =  
      test: "cats"
      supplier:
        id: 9
      price: 11
      variants: []
    currentOrder =
      line_items: []

    module 'Darkswarm'
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock 
      $provide.value "currentOrder", currentOrder 
      null

    inject ($injector, _$httpBackend_)->
      Products = $injector.get("Products")
      Enterprises = $injector.get("Enterprises")
      Variants = $injector.get("Variants")
      Cart = $injector.get("Cart")
      $httpBackend = _$httpBackend_

  it "Fetches products from the backend on init", ->
    $httpBackend.expectGET("/shop/products").respond([product])
    $httpBackend.flush()
    expect(Products.products[0].test).toEqual "cats" 

  it "dereferences suppliers", ->
    Enterprises.enterprises_by_id = 
      {id: 9, name: "test"}
    $httpBackend.expectGET("/shop/products").respond([{supplier : {id: 9}}])
    $httpBackend.flush()
    expect(Products.products[0].supplier).toBe Enterprises.enterprises_by_id["9"]

  it "registers variants with Variants service", ->
    product.variants = [{id: 1}]
    $httpBackend.expectGET("/shop/products").respond([product])
    $httpBackend.flush()
    expect(Products.products[0].variants[0]).toBe Variants.variants[1] 

  it "registers variants with the Cart", ->
    product.variants = [{id: 8}]
    $httpBackend.expectGET("/shop/products").respond([product])
    $httpBackend.flush()
    expect(Cart.line_items[0].variant).toBe Products.products[0].variants[0]

  it "sets primaryImageOrMissing when no images are provided", ->
    $httpBackend.expectGET("/shop/products").respond([product])
    $httpBackend.flush()
    expect(Products.products[0].primaryImage).toBeUndefined()
    expect(Products.products[0].primaryImageOrMissing).toEqual "/assets/noimage/small.png"

  describe "determining the price to display for a product", ->
    it "displays the product price when the product does not have variants", ->
      $httpBackend.expectGET("/shop/products").respond([product])
      $httpBackend.flush()
      expect(Products.products[0].price).toEqual 11.00

    it "displays the minimum variant price when the product has variants", ->
      product.variants = [{price: 22}, {price: 33}]
      $httpBackend.expectGET("/shop/products").respond([product])
      $httpBackend.flush()
      expect(Products.products[0].price).toEqual 22
