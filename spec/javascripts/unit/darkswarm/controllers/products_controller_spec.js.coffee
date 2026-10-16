describe 'ProductsCtrl', ->
  ctrl = null
  scope = null
  event = null
  Products = null
  Cart = {}
  Taxons = null
  Properties = null
  currentHub = null
  OrderCycle = null
  productGridViewFeature = null

  beforeEach ->
    module('Darkswarm')
    Products =
      all: ->
      update: ->
      products: ["testy mctest"]
      loading: false
    OrderCycle =
      order_cycle: {}
    Taxons:
      taxons: []
    Properties: {}
    currentHub =
      id: 1
    productGridViewFeature =
      enabled: false

  buildController = ->
    inject ($rootScope, $controller) ->
      scope = $rootScope
      ctrl = $controller 'ProductsCtrl', {$scope: scope, Products: Products, OrderCycle: OrderCycle, Cart: Cart, Taxons: Taxons, Properties: Properties, currentHub: currentHub, productGridViewFeature: productGridViewFeature}

  describe "with the legacy product list", ->
    beforeEach ->
      buildController()

    it 'fetches products from Products', ->
      expect(scope.Products.products).toEqual ['testy mctest']

    it "blocks keypresses on code 13", ->
      event =
        keyCode: 13
        preventDefault: ->
      spyOn(event, 'preventDefault')
      scope.searchKeypress(event)
      expect(event.preventDefault).toHaveBeenCalled()

    it "updates the products when searching", ->
      spyOn(Products, 'update')
      scope.$digest()
      scope.query = "apple"
      scope.$digest()
      expect(Products.update).toHaveBeenCalled()

  describe "with the product grid view", ->
    frame = null
    searchKey = 'q[name_or_meta_keywords_or_variants_display_as_or_variants_display_name_or_variants_enterprise_name_cont]'

    beforeEach ->
      productGridViewFeature.enabled = true
      OrderCycle.order_cycle.order_cycle_id = 1
      frame = document.createElement("turbo-frame")
      frame.id = "shop-products"
      frame.setAttribute("src", "/order_cycles/1/products")
      document.body.appendChild(frame)
      spyOn(Products, 'update')
      buildController()
      scope.$digest()

    afterEach ->
      frame.remove()

    frameParams = ->
      new URL(frame.getAttribute("src"), "http://localhost").searchParams

    it "reloads the frame with the search", ->
      scope.query = "apple"
      scope.$digest()
      expect(frameParams().get(searchKey)).toEqual "apple"
      expect(Products.update).not.toHaveBeenCalled()

    it "reloads the frame with the taxon and property filters", ->
      scope.activeTaxons.push(1, 2)
      scope.activeProperties.push(3)
      scope.activeProducerProperties.push(4)
      scope.$digest()
      expect(frameParams().getAll('q[variants_primary_taxon_id_in_any][]')).toEqual ["1", "2"]
      expect(frameParams().getAll('q[with_properties][]')).toEqual ["3"]
      expect(frameParams().getAll('q[with_variants_enterprise_properties][]')).toEqual ["4"]

    it "resets the frame when clearing the search", ->
      scope.query = "apple"
      scope.activeTaxons.push(1)
      scope.$digest()
      scope.clearQuery()
      scope.$digest()
      expect(frameParams().get(searchKey)).toBeNull()
      expect(frameParams().getAll('q[variants_primary_taxon_id_in_any][]')).toEqual ["1"]

    it "resets the frame when clearing everything", ->
      scope.query = "apple"
      scope.activeProperties.push(3)
      scope.$digest()
      # FilterSelectorsService empties the active lists in place
      spyOn(scope, 'clearFilters').and.callFake ->
        scope.activeProperties.length = 0
      scope.clearAll()
      scope.$digest()
      expect(frame.getAttribute("src")).toEqual "/order_cycles/1/products"

