describe 'Products service', ->
  $httpBackend = null
  Products = null
  OrderCycle = {}
  Shopfront = null
  RailsFlashLoader = null
  Variants = null
  Cart = null
  shopfront = null
  currentOrder = null
  currentHub = null
  product = null
  productWithImage = null
  properties = null
  taxons = null
  GmapsGeo = {}
  endpoint = "/api/v0/order_cycles/1/products.json?distributor=1"

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
      image: {
        large_url: 'foo.png'
      }
    currentOrder =
      line_items: []
    currentHub =
      id: 1
    properties =
      { id: 1, name: "some property" }
    taxons =
      { id: 2, name: "some taxon" }
    shopfront =
      producers:
        id: 9,
        name: "Test"
    OrderCycle =
      order_cycle:
        order_cycle_id: 1
    RailsFlashLoader =
      loadFlash: (arg) ->

    module 'Darkswarm'
    module ($provide)->
      $provide.value "shopfront", shopfront
      $provide.value "currentOrder", currentOrder
      $provide.value "currentHub", currentHub
      $provide.value "taxons", taxons
      $provide.value "properties", properties
      $provide.value "GmapsGeo", GmapsGeo
      $provide.value "OrderCycle", OrderCycle
      $provide.value "railsFlash", null
      null

    inject ($injector, _$httpBackend_, _RailsFlashLoader_)->
      Products = $injector.get("Products")
      Shopfront = $injector.get("Shopfront")
      Properties = $injector.get("Properties")
      RailsFlashLoader = _RailsFlashLoader_
      Variants = $injector.get("Variants")
      Cart = $injector.get("Cart")
      $httpBackend = _$httpBackend_

  it "Fetches products from the backend on init", ->
    $httpBackend.expectGET(endpoint).respond([product])
    $httpBackend.flush()
    expect(Products.products[0].test).toEqual "cats"

  it "dereferences suppliers", ->
    Shopfront.producers_by_id =
      {id: 9, name: "test"}
    $httpBackend.expectGET(endpoint).respond([{supplier : {id: 9}, master: {}}])
    $httpBackend.flush()
    expect(Products.products[0].supplier).toBe Shopfront.producers_by_id["9"]

  it "dereferences taxons", ->
    product.taxons = [2]
    $httpBackend.expectGET(endpoint).respond([product])
    $httpBackend.flush()
    expect(Products.products[0].taxons[1]).toBe taxons[0]

  it "dereferences properties", ->
    product.properties_with_values = [1]
    $httpBackend.expectGET(endpoint).respond([product])
    $httpBackend.flush()
    expect(Products.products[0].properties[1]).toBe properties[0]

  it "registers variants with Variants service", ->
    product.variants = [{id: 1}]
    $httpBackend.expectGET(endpoint).respond([product])
    $httpBackend.flush()
    expect(Products.products[0].variants[0]).toBe Variants.variants[1]

  it "stores variant names", ->
    product.variants = [{id: 1, name_to_display: "one"}, {id: 2, name_to_display: "two"}]
    $httpBackend.expectGET(endpoint).respond([product])
    $httpBackend.flush()
    expect(Products.products[0].variant_names).toEqual "one two "

  it "sets primaryImageOrMissing when no images are provided", ->
    $httpBackend.expectGET(endpoint).respond([product])
    $httpBackend.flush()
    expect(Products.products[0].primaryImage).toBeUndefined()
    expect(Products.products[0].primaryImageOrMissing).toEqual "/noimage/small.png"

  it "sets largeImage", ->
    $httpBackend.expectGET(endpoint).respond([productWithImage])
    $httpBackend.flush()
    expect(Products.products[0].largeImage).toEqual("foo.png")

  describe "determining the price to display for a product", ->
    it "displays the product price when the product does not have variants", ->
      $httpBackend.expectGET(endpoint).respond([product])
      $httpBackend.flush()
      expect(Products.products[0].price).toEqual 11.00

    it "displays the minimum variant price when the product has variants", ->
      product.variants = [{price: 22}, {price: 33}]
      $httpBackend.expectGET(endpoint).respond([product])
      $httpBackend.flush()
      expect(Products.products[0].price).toEqual 22
