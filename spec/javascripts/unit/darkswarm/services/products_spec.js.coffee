describe 'Products service', ->
  $httpBackend = null
  Products = null
  Enterprises = null
  Variants = null
  Cart = null
  CurrentHubMock = {}
  currentOrder = null
  product = null
  productWithImage = null
  properties = null
  taxons = null
  Geo = {}

  beforeEach ->
    product =
      test: "cats"
      supplier:
        id: 9
      price: 11
      master: {}
      variants: []
    productWithImage =
      supplier:
        id: 9
      master: {}
      variants: []
      images: [
        large_url: 'foo.png'
      ]
    currentOrder =
      line_items: []
    properties =
      { id: 1, name: "some property" }
    taxons =
      { id: 2, name: "some taxon" }

    module 'Darkswarm'
    module ($provide)->
      $provide.value "CurrentHub", CurrentHubMock
      $provide.value "currentOrder", currentOrder
      $provide.value "taxons", taxons
      $provide.value "properties", properties
      $provide.value "Geo", Geo
      null

    inject ($injector, _$httpBackend_)->
      Products = $injector.get("Products")
      Enterprises = $injector.get("Enterprises")
      Properties = $injector.get("Properties")
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
    $httpBackend.expectGET("/shop/products").respond([{supplier : {id: 9}, master: {}}])
    $httpBackend.flush()
    expect(Products.products[0].supplier).toBe Enterprises.enterprises_by_id["9"]

  it "dereferences taxons", ->
    product.taxons = [2]
    $httpBackend.expectGET("/shop/products").respond([product])
    $httpBackend.flush()
    expect(Products.products[0].taxons[1]).toBe taxons[0]

  it "dereferences properties", ->
    product.properties_with_values = [1]
    $httpBackend.expectGET("/shop/products").respond([product])
    $httpBackend.flush()
    expect(Products.products[0].properties[1]).toBe properties[0]

  it "registers variants with Variants service", ->
    product.variants = [{id: 1}]
    $httpBackend.expectGET("/shop/products").respond([product])
    $httpBackend.flush()
    expect(Products.products[0].variants[0]).toBe Variants.variants[1]

  it "sets primaryImageOrMissing when no images are provided", ->
    $httpBackend.expectGET("/shop/products").respond([product])
    $httpBackend.flush()
    expect(Products.products[0].primaryImage).toBeUndefined()
    expect(Products.products[0].primaryImageOrMissing).toEqual "/assets/noimage/small.png"

  it "sets largeImage", ->
    $httpBackend.expectGET("/shop/products").respond([productWithImage])
    $httpBackend.flush()
    expect(Products.products[0].largeImage).toEqual("foo.png")

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
