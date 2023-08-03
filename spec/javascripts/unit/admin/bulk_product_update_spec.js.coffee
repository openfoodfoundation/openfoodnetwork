describe "filtering products for submission to database", ->
  it "accepts an object or an array and only returns an array", ->
    expect(filterSubmitProducts([])).toEqual []
    expect(filterSubmitProducts({})).toEqual []
    expect(filterSubmitProducts(1:
      id: 1
      name: "lala"
    )).toEqual [
      id: 1
      name: "lala"
    ]
    expect(filterSubmitProducts([
      id: 1
      name: "lala"
    ])).toEqual [
      id: 1
      name: "lala"
    ]
    expect(filterSubmitProducts(1)).toEqual []
    expect(filterSubmitProducts("2")).toEqual []
    expect(filterSubmitProducts(null)).toEqual []

  it "only returns products which have an id property", ->
    expect(filterSubmitProducts([
      {
        id: 1
        name: "p1"
      }
      {
        notanid: 2
        name: "p2"
      }
    ])).toEqual [
      id: 1
      name: "p1"
    ]

  it "does not return a product object for products which have no propeties other than an id", ->
    expect(filterSubmitProducts([
      {
        id: 1
        someunwantedproperty: "something"
      }
      {
        id: 2
        name: "p2"
      }
    ])).toEqual [
      id: 2
      name: "p2"
    ]

  it "does not return an on_hand count when a product has variants", ->
    testProduct =
      id: 1
      on_hand: 5
      variants: [
        id: 1
        on_hand: 5
        price: 12.0
      ]

    expect(filterSubmitProducts([testProduct])).toEqual [
      id: 1
      variants_attributes: [
        id: 1
        on_hand: 5
        price: 12.0
      ]
    ]

  it "returns variants as variants_attributes", ->
    testProduct =
      id: 1
      variants: [
        id: 1
        on_hand: 5
        price: 12.0
        unit_value: 250
        unit_description: "(bottle)"
      ]

    expect(filterSubmitProducts([testProduct])).toEqual [
      id: 1
      variants_attributes: [
        id: 1
        on_hand: 5
        price: 12.0
        unit_value: 250
        unit_description: "(bottle)"
      ]
    ]

  it "ignores variants without an id, and those for which deleted_at is not null", ->
    testProduct =
      id: 1
      variants: [
        {
          id: 1
          on_hand: 3
          price: 5.0
        }
        {
          on_hand: 1
          price: 15.0
        }
        {
          id: 2
          on_hand: 2
          deleted_at: new Date()
          price: 20.0
        }
      ]

    expect(filterSubmitProducts([testProduct])).toEqual [
      id: 1
      variants_attributes: [
        id: 1
        on_hand: 3
        price: 5.0
      ]
    ]

  it "returns variants with a negative id without that id", ->
    testProduct =
      id: 1
      variants: [
        id: -1
        on_hand: 5
        price: 12.0
        unit_value: 250
        unit_description: "(bottle)"
      ]

    expect(filterSubmitProducts([testProduct])).toEqual [
      id: 1
      variants_attributes: [
        on_hand: 5
        price: 12.0
        unit_value: 250
        unit_description: "(bottle)"
      ]
    ]

  it "does not return variants_attributes property if variants is an empty array", ->
    testProduct =
      id: 1
      price: 10
      variants: []

    expect(filterSubmitProducts([testProduct])).toEqual [
      id: 1
      price: 10
    ]

  it "returns variant_unit_with_scale as variant_unit and variant_unit_scale", ->
    testProduct =
      id: 1
      variant_unit: 'weight'
      variant_unit_scale: 1
      variant_unit_with_scale: 'weight_1'

    expect(filterSubmitProducts([testProduct])).toEqual [
      id: 1
      variant_unit: 'weight'
      variant_unit_scale: 1
    ]

  it "returns stock properties of a product if no variant is provided", ->
    testProduct =
      id: 1
      name: "TestProduct"
      on_hand: 0
      on_demand: false

    expect(filterSubmitProducts([testProduct])).toEqual [
      id: 1
      name: "TestProduct"
      on_hand: 0
      on_demand: false
    ]

  it "only returns the properties of products which ought to be updated", ->
    testProduct =
      id: 1
      name: "TestProduct"
      description: ""
      deleted_at: null
      meta_keywords: null
      shipping_category_id: null
      created_at: null
      updated_at: null
      on_hand: 0
      on_demand: false
      producer_id: 5
      group_buy: null
      group_buy_unit_size: null
      master:
        id: 2
        unit_value: 250
        unit_description: "foo"
      variants: [
        id: 1
        on_hand: 2
        price: 10.0
        unit_value: 250
        tax_category_id: null
        unit_description: "(bottle)"
        display_as: "bottle"
        display_name: "nothing"
      ]
      variant_unit: 'volume'
      variant_unit_scale: 1
      variant_unit_name: 'loaf'
      variant_unit_with_scale: 'volume_1'

    expect(filterSubmitProducts([testProduct])).toEqual [
      id: 1
      name: "TestProduct"
      supplier_id: 5
      variant_unit: 'volume'
      variant_unit_scale: 1
      variant_unit_name: 'loaf'
      master_attributes:
        id: 2
        unit_value: 250
        unit_description: "foo"
      variants_attributes: [
        id: 1
        on_hand: 2
        price: 10.0
        unit_value: 250
        tax_category_id: null
        unit_description: "(bottle)"
        display_as: "bottle"
        display_name: "nothing"
      ]
    ]

describe "AdminProductEditCtrl", ->
  $ctrl = $scope = $timeout = $httpBackend = BulkProducts = DirtyProducts = DisplayProperties = ProductFiltersUrl = windowStub = null

  beforeEach ->
    module "ofn.admin"
    module ($provide)->
      $provide.value "producers", []
      $provide.value "taxons", []
      $provide.value "tax_categories", []
      $provide.value 'SpreeApiKey', 'API_KEY'
      $provide.value 'columns', []
      null
    module "admin.products"
    module ($provide)->
      $provide.value "availableUnits", "g,kg,T,mL,L,kL"
      null

  beforeEach inject((_$controller_, _$timeout_, $rootScope, _$httpBackend_, _BulkProducts_, _DirtyProducts_, _DisplayProperties_, _ProductFiltersUrl_) ->
    $scope = $rootScope.$new()
    $ctrl = _$controller_
    $timeout = _$timeout_
    $httpBackend = _$httpBackend_
    BulkProducts = _BulkProducts_
    DirtyProducts = _DirtyProducts_
    DisplayProperties = _DisplayProperties_
    ProductFiltersUrl = _ProductFiltersUrl_

    # Stub the window object so we don't get redirected when href is updated
    windowStub = {navigator: {userAgent: 'foo'}, location: {href: ''}}

    $ctrl "AdminProductEditCtrl", {$scope: $scope, $timeout: $timeout, $window: windowStub}
  )

  describe "loading data upon initialisation", ->
    beforeEach ->
      spyOn($scope, "fetchProducts").and.returnValue "nothing"

    it "gets a list of producers and then resets products with a list of data", ->
      $scope.initialise()
      expect($scope.fetchProducts.calls.count()).toBe 1

    it "gets a list of products applying filters from the url", inject ($location) ->
      query = 'lala'
      producerFilter = 2
      categoryFilter = 5
      sorting = 'name desc'
      importDateFilter = '2020-06-08'
      $location.search({query: query, producerFilter: producerFilter, categoryFilter: categoryFilter, sorting: sorting, importDateFilter: importDateFilter})

      $scope.initialise()

      expect($scope.q.query).toBe query
      expect($scope.q.producerFilter).toBe producerFilter
      expect($scope.q.categoryFilter).toBe categoryFilter
      expect($scope.q.sorting).toBe sorting
      expect($scope.q.importDateFilter).toBe importDateFilter

  describe "fetching products", ->
    $q = null
    deferred = null

    beforeEach inject((_$q_) ->
      $q = _$q_
    )

    beforeEach ->
      deferred = $q.defer()
      deferred.resolve()
      spyOn $scope, "resetProducts"
      spyOn(BulkProducts, "fetch").and.returnValue deferred.promise

    it "calls resetProducts after data has been received", ->
      $scope.fetchProducts()
      $scope.$digest()
      expect($scope.resetProducts).toHaveBeenCalled()

    it "updates url with filter after data has been received", inject ($location, $window) ->
      query = 'lala'
      producerFilter = 2
      categoryFilter = 5
      sorting = 'name desc'
      importDateFilter = '2020-06-08'

      $scope.q.query = query
      $scope.q.producerFilter = producerFilter
      $scope.q.categoryFilter = categoryFilter
      $scope.q.sorting = sorting
      $scope.q.importDateFilter = importDateFilter

      $scope.fetchProducts()
      $scope.$digest()

      encodedSorting = $window.encodeURIComponent(sorting)
      encodedDate = $window.encodeURIComponent(importDateFilter)
      expect($location.url()).toBe(
        "?producerFilter=#{producerFilter}&categoryFilter=#{categoryFilter}&query=#{query}&sorting=#{encodedSorting}&importDateFilter=#{encodedDate}"
      )

  describe "resetting products", ->
    beforeEach ->
      spyOn DirtyProducts, "clear"
      $scope.products = {}
      $scope.resetProducts [
        {
          id: 1
          name: "P1"
        }
        {
          id: 3
          name: "P2"
        }
      ]

    it "resets dirtyProducts", ->
      expect(DirtyProducts.clear).toHaveBeenCalled()

  describe "sorting products", ->
    it "sorts products", ->
      spyOn $scope, "fetchProducts"

      $scope.sortOptions.toggle('name')
      $scope.$apply()

      expect($scope.sorting).toEqual 'name desc'
      expect($scope.fetchProducts).toHaveBeenCalled()

  describe "updating the product on hand count", ->
    it "updates when product is not available on demand", ->
      spyOn($scope, "onHand").and.returnValue 123
      product = {on_demand: false}
      $scope.updateOnHand(product)
      expect(product.on_hand).toEqual 123

    it "updates when product's variants are not available on demand", ->
      spyOn($scope, "onHand").and.returnValue 123
      product = {on_demand: false, variants: [{on_demand: false}]}
      $scope.updateOnHand(product)
      expect(product.on_hand).toEqual 123

    it "does nothing when the product is available on demand", ->
      product = {on_demand: true}
      $scope.updateOnHand(product)
      expect(product.on_hand).toBeUndefined()

    it "does nothing when one of the variants is available on demand", ->
      product =
        on_demand: false
        variants: [
          {on_demand: false, on_hand: 10}
          {on_demand: true, on_hand: Infinity}
        ]
      $scope.updateOnHand(product)
      expect(product.on_hand).toBeUndefined()


  describe "getting on_hand counts when products have variants", ->
    p1 = undefined
    p2 = undefined
    p3 = undefined
    beforeEach ->
      p1 = variants:
        1:
          id: 1
          on_hand: 1

        2:
          id: 2
          on_hand: 2

        3:
          id: 3
          on_hand: 3

      p2 = variants:
        4:
          id: 4
          not_on_hand: 1

        5:
          id: 5
          on_hand: 2

        6:
          id: 6
          on_hand: 3

      p3 =
        not_variants:
          7:
            id: 7
            on_hand: 1

          8:
            id: 8
            on_hand: 2

        variants:
          9:
            id: 9
            on_hand: 3

    it "sums variant on_hand properties", ->
      expect($scope.onHand(p1)).toEqual 6

    it "ignores items in variants without an on_hand property (adds 0)", ->
      expect($scope.onHand(p2)).toEqual 5

    it "ignores on_hand properties of objects in arrays which are not named 'variants' (adds 0)", ->
      expect($scope.onHand(p3)).toEqual 3

    it "returns 'error' if not given an object with a variants property that is an object", ->
      expect($scope.onHand([])).toEqual "error"
      expect($scope.onHand(not_variants: [])).toEqual "error"


  describe "determining whether a product has variants that are available on demand", ->
    it "returns true when at least one variant does", ->
      product =
        variants: [
          {on_demand: false}
          {on_demand: true}
        ]
      expect($scope.hasOnDemandVariants(product)).toBe(true)

    it "returns false otherwise", ->
      product =
        variants: [
          {on_demand: false}
          {on_demand: false}
        ]
      expect($scope.hasOnDemandVariants(product)).toBe(false)


  describe "determining whether a product has variants", ->
    it "returns true when it does", ->
      product =
        variants: [{id: 1}, {id: 2}]
      expect($scope.hasVariants(product)).toBe(true)

    it "returns false when it does not", ->
      product =
        variants: []
      expect($scope.hasVariants(product)).toBe(false)


  describe "determining whether a product has a unit", ->
    it "returns true when it does", ->
      product =
        variant_unit_with_scale: 'weight_1000'
      expect($scope.hasUnit(product)).toBe(true)

    it "returns false when its unit is undefined", ->
      product = {}
      expect($scope.hasUnit(product)).toBe(false)


  describe "determining whether a variant has been saved", ->
    it "returns true when it has a positive id", ->
      variant = {id: 1}
      expect($scope.variantSaved(variant)).toBe(true)

    it "returns false when it has no id", ->
      variant = {}
      expect($scope.variantSaved(variant)).toBe(false)

    it "returns false when it has a negative id", ->
      variant = {id: -1}
      expect($scope.variantSaved(variant)).toBe(false)


  describe "submitting products to be updated", ->
    describe "packing products", ->
      beforeEach ->
        window.bigDecimal = jasmine.createSpyObj "bigDecimal", ["multiply"]
        window.bigDecimal.multiply.and.callFake (a, b, c) -> (a * b).toFixed(c)

      it "extracts variant_unit_with_scale into variant_unit and variant_unit_scale", ->
        testProduct =
          id: 1
          variant_unit: 'weight'
          variant_unit_scale: 1
          variant_unit_with_scale: 'volume_1000'

        $scope.packProduct(testProduct)

        expect(testProduct).toEqual
          id: 1
          variant_unit: 'volume'
          variant_unit_scale: 1000
          variant_unit_with_scale: 'volume_1000'

      it "extracts a null value into null variant_unit and variant_unit_scale", ->
        testProduct =
          id: 1
          variant_unit: 'weight'
          variant_unit_scale: 1
          variant_unit_with_scale: null

        $scope.packProduct(testProduct)

        expect(testProduct).toEqual
          id: 1
          variant_unit: null
          variant_unit_scale: null
          variant_unit_with_scale: null

      it "extracts when variant_unit_with_scale is 'items'", ->
        testProduct =
          id: 1
          variant_unit: 'weight'
          variant_unit_scale: 1
          variant_unit_with_scale: 'items'

        $scope.packProduct(testProduct)

        expect(testProduct).toEqual
          id: 1
          variant_unit: 'items'
          variant_unit_scale: null
          variant_unit_with_scale: 'items'

      it "packs the master variant", ->
        spyOn $scope, "packVariant"
        testVariant = {id: 1}
        testProduct =
          id: 1
          master: testVariant

        $scope.packProduct(testProduct)

        expect($scope.packVariant).toHaveBeenCalledWith(testProduct, testVariant)

      it "packs each variant", ->
        spyOn $scope, "packVariant"
        testVariant = {id: 1}
        testProduct =
          id: 1
          variants: {1: testVariant}

        $scope.packProduct(testProduct)

        expect($scope.packVariant).toHaveBeenCalledWith(testProduct, testVariant)

    describe "packing variants", ->
      beforeEach ->
        window.bigDecimal = jasmine.createSpyObj "bigDecimal", ["multiply"]
        window.bigDecimal.multiply.and.callFake (a, b, c) -> (a * b).toFixed(c)

      it "extracts unit_value and unit_description from unit_value_with_description", ->
        testProduct = {id: 123, variant_unit_scale: 1.0}
        testVariant = {unit_value_with_description: "250.5 (bottle)"}
        BulkProducts.products = [testProduct]
        $scope.products = [testProduct]
        $scope.packVariant(testProduct, testVariant)
        expect(testVariant).toEqual
          unit_value: 250.5
          unit_description: "(bottle)"
          unit_value_with_description: "250.5 (bottle)"

      it "extracts into unit_value when only a number is provided", ->
        testProduct = {id: 123, variant_unit_scale: 1.0}
        testVariant = {unit_value_with_description: "250.5"}
        BulkProducts.products = [testProduct]
        $scope.packVariant(testProduct, testVariant)
        expect(testVariant).toEqual
          unit_value: 250.5
          unit_description: ''
          unit_value_with_description: "250.5"

      it "extracts into unit_description when only a string is provided", ->
        testProduct = {id: 123}
        testVariant = {unit_value_with_description: "Medium"}
        BulkProducts.products = [testProduct]
        $scope.packVariant(testProduct, testVariant)
        expect(testVariant).toEqual
          unit_value: null
          unit_description: 'Medium'
          unit_value_with_description: "Medium"

      it "extracts into unit_description when a string starting with a number is provided", ->
        testProduct = {id: 123}
        testVariant = {unit_value_with_description: "1kg"}
        BulkProducts.products = [testProduct]
        $scope.packVariant(testProduct, testVariant)
        expect(testVariant).toEqual
          unit_value: null
          unit_description: '1kg'
          unit_value_with_description: "1kg"

      it "sets blank values when no value provided", ->
        testProduct = {id: 123}
        testVariant = {unit_value_with_description: ""}
        BulkProducts.products = [testProduct]
        $scope.packVariant(testProduct, testVariant)
        expect(testVariant).toEqual
          unit_value: null
          unit_description: ''
          unit_value_with_description: ""

      it "sets nothing when the field is undefined", ->
        testProduct = {id: 123}
        testVariant = {}
        BulkProducts.products = [testProduct]
        $scope.packVariant(testProduct, testVariant)
        expect(testVariant).toEqual {}

      it "sets zero when the field is zero", ->
        testProduct = {id: 123, variant_unit_scale: 1.0}
        testVariant = {unit_value_with_description: "0"}
        BulkProducts.products = [testProduct]
        $scope.packVariant(testProduct, testVariant)
        expect(testVariant).toEqual
          unit_value: 0
          unit_description: ''
          unit_value_with_description: "0"

      it "converts value from chosen unit to base unit", ->
        testProduct = {id: 123, variant_unit_scale: 1000}
        testVariant = {unit_value_with_description: "250.5"}
        BulkProducts.products = [testProduct]
        $scope.packVariant(testProduct, testVariant)
        expect(testVariant).toEqual
          unit_value: 250500
          unit_description: ''
          unit_value_with_description: "250.5"

      it "does not convert value when using a non-scaled unit", ->
        testProduct = {id: 123}
        testVariant = {unit_value_with_description: "12"}
        BulkProducts.products = [testProduct]
        $scope.packVariant(testProduct, testVariant)
        expect(testVariant).toEqual
          unit_value: 12
          unit_description: ''
          unit_value_with_description: "12"

      it "converts unit_value into a float when a comma separated number is provided", ->
        testProduct = {id: 123, variant_unit_scale: 1.0}
        testVariant = {unit_value_with_description: "250,5"}
        BulkProducts.products = [testProduct]
        $scope.packVariant(testProduct, testVariant)
        expect(testVariant).toEqual
          unit_value: 250.5
          unit_description: ''
          unit_value_with_description: "250,5"

      it "rounds off the unit_value upto 2 decimal places", ->
        testProduct = {id: 123, variant_unit_scale: 1.0}
        testVariant = {unit_value_with_description: "1234.567"}
        BulkProducts.products = [testProduct]
        $scope.packVariant(testProduct, testVariant)
        expect(testVariant).toEqual
          unit_value: 1234.57
          unit_description: ''
          unit_value_with_description: "1234.567"


    describe "filtering products", ->
      beforeEach ->
        spyOn $scope, "packProduct"
        spyOn(window, "filterSubmitProducts").and.returnValue [
          {
            id: 1
            value: 3
          }
          {
            id: 2
            value: 4
          }
        ]
        spyOn $scope, "updateProducts"
        DirtyProducts.addProductProperty 1, "propName", "something"
        DirtyProducts.addProductProperty 2, "propName", "something"
        $scope.products =
          1:
            id: 1
          2:
            id: 2

        $scope.submitProducts()

      it "packs all products and all dirty products", ->
        expect($scope.packProduct.calls.count()).toBe 4

      it "filters returned dirty products", ->
        expect(filterSubmitProducts).toHaveBeenCalledWith
          1:
            id: 1
            propName: "something"
          2:
            id: 2
            propName: "something"


      it "sends dirty and filtered objects to submitProducts()", ->
        expect($scope.updateProducts).toHaveBeenCalledWith [
          {
            id: 1
            value: 3
          }
          {
            id: 2
            value: 4
          }
        ]


    describe "updating products", ->
      it "submits products to be updated with a http post request to /admin/products/bulk_update", ->
        $httpBackend.expectPOST("/admin/products/bulk_update").respond "list of products"
        $scope.updateProducts "list of products"
        $httpBackend.flush()

      it "runs displaySuccess() when post returns success", ->
        spyOn $scope, "displaySuccess"
        spyOn BulkProducts, "updateVariantLists"
        spyOn DirtyProducts, "clear"

        $scope.bulk_product_form = jasmine.createSpyObj('bulk_product_form', ['$setPristine'])

        $scope.products = [
          {
            id: 1
            name: "P1"
          }
          {
            id: 2
            name: "P2"
          }
        ]
        $httpBackend.expectPOST("/admin/products/bulk_update").respond 200, [
          {
            id: 1
            name: "P1"
          }
          {
            id: 2
            name: "P2"
          }
        ]
        $scope.updateProducts "list of dirty products"
        $httpBackend.flush()
        $timeout.flush()
        expect($scope.displaySuccess).toHaveBeenCalled()
        expect($scope.bulk_product_form.$setPristine).toHaveBeenCalled
        expect(DirtyProducts.clear).toHaveBeenCalled()
        expect(BulkProducts.updateVariantLists).toHaveBeenCalled()

      it "runs displayFailure() when post returns an error", ->
        spyOn $scope, "displayFailure"
        $scope.products = "updated list of products"
        $httpBackend.expectPOST("/admin/products/bulk_update").respond 500, "updated list of products"
        $scope.updateProducts "updated list of products"
        $httpBackend.flush()
        expect($scope.displayFailure).toHaveBeenCalled()

      describe "displaying the error information when post returns 400", ->
        beforeEach ->
          spyOn $scope, "displayFailure"
          $scope.products = "updated list of products"

        it "displays errors in an array", ->
          $httpBackend.expectPOST("/admin/products/bulk_update").respond 400, { "errors": ["an error"] }
          $scope.updateProducts "updated list of products"
          $httpBackend.flush()
          expect($scope.displayFailure).toHaveBeenCalledWith("Saving failed with the following error(s):\nan error\n")

        it "displays errors in a hash", ->
          $httpBackend.expectPOST("/admin/products/bulk_update").respond 400, { "errors": { "base": ["a basic error"] } }
          $scope.updateProducts "updated list of products"
          $httpBackend.flush()
          expect($scope.displayFailure).toHaveBeenCalledWith("Saving failed with the following error(s):\na basic error\n")


  describe "adding variants", ->
    beforeEach ->
      spyOn DisplayProperties, 'setShowVariants'

    it "adds first and subsequent variants", ->
      product = {id: 123, variants: []}
      $scope.addVariant(product)
      $scope.addVariant(product)
      expect(product).toEqual
        id: 123
        variants: [
          {id: -1, price: null, unit_value: null, tax_category_id: null, unit_description: null, on_demand: false, on_hand: null, display_as: null, display_name: null}
          {id: -2, price: null, unit_value: null, tax_category_id: null, unit_description: null, on_demand: false, on_hand: null, display_as: null, display_name: null}
        ]

    it "shows the variant(s)", ->
      product = {id: 123, variants: []}
      $scope.addVariant(product)
      expect(DisplayProperties.setShowVariants).toHaveBeenCalledWith 123, true


  describe "deleting products", ->
    it "deletes products with a http delete request to /api/products/id", ->
      spyOn(window, "confirm").and.returnValue true
      $scope.products = [
        {
          id: 9
        }
        {
          id: 13
        }
      ]
      $scope.dirtyProducts = {}
      $httpBackend.expectDELETE("/api/v0/products/13").respond 200, "data"
      $scope.deleteProduct $scope.products[1]
      expect(window.confirm).toHaveBeenCalledWith "Are you sure?"
      $httpBackend.flush()

    it "removes the specified product from both $scope.products and $scope.dirtyProducts (if it exists there)", ->
      spyOn(window, "confirm").and.returnValue true
      $scope.products = [
        {
          id: 9
        }
        {
          id: 13
        }
      ]
      DirtyProducts.addProductProperty 9, "someProperty", "something"
      DirtyProducts.addProductProperty 13, "name", "P1"

      $httpBackend.expectDELETE("/api/v0/products/13").respond 200, "data"
      $scope.deleteProduct $scope.products[1]
      $httpBackend.flush()
      expect($scope.products).toEqual [
        id: 9
      ]
      expect(DirtyProducts.all()).toEqual 9:
        id: 9
        someProperty: "something"



  describe "deleting variants", ->
    describe "when the variant is the only one left on the product", ->
      it "alerts the user", ->
        spyOn(window, "alert")
        $scope.products = [
          {id: 1, variants: [{id: 1}]}
        ]
        $scope.deleteVariant $scope.products[0], $scope.products[0].variants[0]
        expect(window.alert).toHaveBeenCalledWith "The last variant cannot be deleted!"

    describe "when the variant has not been saved", ->
      it "removes the variant from products and dirtyProducts", ->
        spyOn(window, "confirm").and.returnValue true
        $scope.products = [
          {id: 1, variants: [{id: -1},{id: -2}]}
        ]
        DirtyProducts.addVariantProperty 1, -1, "something", "something"
        DirtyProducts.addProductProperty 1, "something", "something"
        $scope.deleteVariant $scope.products[0], $scope.products[0].variants[0]
        expect($scope.products).toEqual([
          {id: 1, variants: [{id: -2}]}
        ])
        expect(DirtyProducts.all()).toEqual
          1: { id: 1, something: 'something'}


    describe "when the variant has been saved", ->
      it "deletes variants with a http delete request to /api/products/(id)/variants/(variant_id)", ->
        spyOn(window, "confirm").and.returnValue true
        $scope.products = [
          {
            id: 9
            variants: [{
              id: 3
              price: 12
            },
            {
              id: 4
              price: 15
            }
            ]
          }
          {
            id: 13
          }
        ]
        $scope.dirtyProducts = {}
        $httpBackend.expectDELETE("/api/v0/products/9/variants/3").respond 200, "data"
        $scope.deleteVariant $scope.products[0], $scope.products[0].variants[0]
        $httpBackend.flush()

      it "removes the specified variant from both the variants object and $scope.dirtyProducts (if it exists there)", ->
        spyOn(window, "confirm").and.returnValue true
        $scope.products = [
          {
            id: 9
            variants: [
              {
                id: 3
                price: 12.0
              }
              {
                id: 4
                price: 6.0
              }
            ]
          }
          {
            id: 13
          }
        ]
        DirtyProducts.addVariantProperty 9, 3, "price", 12.0
        DirtyProducts.addVariantProperty 9, 4, "price", 6.0
        DirtyProducts.addProductProperty 13, "name", "P1"

        $httpBackend.expectDELETE("/api/v0/products/9/variants/3").respond 200, "data"
        $scope.deleteVariant $scope.products[0], $scope.products[0].variants[0]
        $httpBackend.flush()
        expect($scope.products[0].variants).toEqual [
          id: 4
          price: 6.0
        ]
        expect(DirtyProducts.all()).toEqual
          9:
            id: 9
            variants:
              4:
                id: 4
                price: 6.0

          13:
            id: 13
            name: "P1"

  describe "editWarn", ->
    testProduct = testVariant = null

    beforeEach ->
      testProduct =
        id: 1
        name: "TestProduct"
        description: ""
        deleted_at: null
        meta_keywords: null
        shipping_category_id: null
        created_at: null
        updated_at: null
        on_hand: 0
        on_demand: false
        producer_id: 5
        group_buy: null
        group_buy_unit_size: null
        master:
          id: 2
          unit_value: 250
          unit_description: "foo"

    describe 'product has variant', ->
      it 'should load the edit product variant page', ->
        testVariant =
          id: 2
          name: "TestVariant"

        $scope.editWarn(testProduct, testVariant)

        expect(windowStub.location.href).toBe(
          "/admin/products/#{testProduct.id}/variants/#{testVariant.id}/edit"
        )

    describe 'product has no variant', ->
      it 'should display unsaved changes confirmation if there are any DirtyProduct', inject ($window, DirtyProducts) ->
        spyOn($window, 'confirm')
        spyOn(DirtyProducts, 'count').and.returnValue 2

        $scope.editWarn(testProduct, null)
        expect($window.confirm).toHaveBeenCalled()

      it 'should load the edit product page', inject ->
        $scope.editWarn(testProduct, null)

        expect(windowStub.location.href).toBe(
          "/admin/products/#{testProduct.id}/edit"
        )

      it 'should load edit product page including the selected filters', inject ($httpParamSerializer) ->
        query = 'lala'
        category = 3
        $scope.q.query = query
        $scope.q.categoryFilter = category

        # use $httpParamSerializer as it will sort parameters alphabetically
        expectedFilter = $httpParamSerializer({ query: query, categoryFilter: category })

        $scope.editWarn(testProduct, null)

        expect(windowStub.location.href).toBe(
          "/admin/products/#{testProduct.id}/edit?#{expectedFilter}"
        )

  describe "filtering products", ->
    describe "clearing filters", ->
      it "resets filter variables", ->
        $scope.q.query = "lala"
        $scope.q.producerFilter = "5"
        $scope.q.categoryFilter = "6"
        $scope.resetSelectFilters()
        expect($scope.q.query).toBe ""
        expect($scope.q.producerFilter).toBeUndefined
        expect($scope.q.categoryFilter).toBeUndefined


describe "converting arrays of objects with ids to an object with ids as keys", ->
  it "returns an object", ->
    array = []
    expect(toObjectWithIDKeys(array)).toEqual {}

  it "adds each object in the array provided with an id to the returned object with the id as its key", ->
    array = [
      {
        id: 1
      }
      {
        id: 3
      }
    ]
    expect(toObjectWithIDKeys(array)).toEqual
      1:
        id: 1

      3:
        id: 3


  it "ignores items which are not objects and those which do not possess ids", ->
    array = [
      {
        id: 1
      }
      "not an object"
      {
        notanid: 3
      }
    ]
    expect(toObjectWithIDKeys(array)).toEqual 1:
      id: 1


  it "sends arrays with the key 'variants' to itself", ->
    spyOn(window, "toObjectWithIDKeys").and.callThrough()
    array = [
      {
        id: 1
        variants: [id: 17]
      }
      {
        id: 2
        variants:
          12:
            id: 12
      }
    ]
    products = toObjectWithIDKeys(array)
    expect(products["1"].variants).toEqual 17:
      id: 17

    expect(toObjectWithIDKeys).toHaveBeenCalledWith [id: 17]
    expect(toObjectWithIDKeys).not.toHaveBeenCalledWith {12: {id: 12}}
