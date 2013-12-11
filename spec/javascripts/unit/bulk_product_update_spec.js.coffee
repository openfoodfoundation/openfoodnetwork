describe "filtering products", ->
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
  
  # TODO Not an exhaustive test, is there a better way to do this?
  it "only returns the properties of products which ought to be updated", ->
    testProduct =
      id: 1
      name: "TestProduct"
      description: ""
      available_on: new Date()
      deleted_at: null
      permalink: null
      meta_description: null
      meta_keywords: null
      tax_category_id: null
      shipping_category_id: null
      created_at: null
      updated_at: null
      count_on_hand: 0
      supplier_id: 5
      supplier:
        id: 5
        name: "Supplier 1"

      group_buy: null
      group_buy_unit_size: null
      on_demand: false
      variants: [
        id: 1
        on_hand: 2
        price: 10.0
        unit_value: 250
        unit_description: "(bottle)"
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
      available_on: new Date()
      variants_attributes: [
        id: 1
        on_hand: 2
        price: 10.0
        unit_value: 250
        unit_description: "(bottle)"
      ]
    ]


describe "Maintaining a live record of dirty products and properties", ->
  describe "adding product properties to the dirtyProducts object", -> # Applies to both products and variants
    it "adds the product and the property to the list if property is dirty", ->
      dirtyProducts = {}
      addDirtyProperty dirtyProducts, 1, "name", "Product 1"
      expect(dirtyProducts).toEqual 1:
        id: 1
        name: "Product 1"


    it "adds the relevant property to a product that is already in the list but which does not yet possess it if the property is dirty", ->
      dirtyProducts = 1:
        id: 1
        notaname: "something"

      addDirtyProperty dirtyProducts, 1, "name", "Product 3"
      expect(dirtyProducts).toEqual 1:
        id: 1
        notaname: "something"
        name: "Product 3"


    it "changes the relevant property of a product that is already in the list if the property is dirty", ->
      dirtyProducts = 1:
        id: 1
        name: "Product 1"

      addDirtyProperty dirtyProducts, 1, "name", "Product 2"
      expect(dirtyProducts).toEqual 1:
        id: 1
        name: "Product 2"



  describe "removing properties of products which are clean", ->
    it "removes the relevant property from a product if the property is clean and the product has that property", ->
      dirtyProducts = 1:
        id: 1
        someProperty: "something"
        name: "Product 1"

      removeCleanProperty dirtyProducts, 1, "name", "Product 1"
      expect(dirtyProducts).toEqual 1:
        id: 1
        someProperty: "something"


    it "removes the product from dirtyProducts if the property is clean and by removing an existing property on an id is left", ->
      dirtyProducts = 1:
        id: 1
        name: "Product 1"

      removeCleanProperty dirtyProducts, 1, "name", "Product 1"
      expect(dirtyProducts).toEqual {}



describe "AdminBulkProductsCtrl", ->
  ctrl = scope = timeout = httpBackend = null

  beforeEach ->
    module "bulk_product_update"
  beforeEach inject(($controller, $timeout, $rootScope, $httpBackend) ->
    scope = $rootScope.$new()
    ctrl = $controller
    timeout = $timeout
    httpBackend = $httpBackend

    ctrl "AdminBulkProductsCtrl", {$scope: scope, $timeout: timeout}
  )

  describe "loading data upon initialisation", ->
    it "gets a list of suppliers and then resets products with a list of data", ->
      httpBackend.expectGET("/api/users/authorise_api?token=api_key").respond success: "Use of API Authorised"
      httpBackend.expectGET("/api/enterprises/managed?template=bulk_index&q[is_primary_producer_eq]=true").respond "list of suppliers"
      httpBackend.expectGET("/api/products/managed?template=bulk_index;page=1;per_page=500").respond "list of products"
      spyOn scope, "resetProducts"
      scope.initialise "api_key"
      httpBackend.flush()
      expect(scope.suppliers).toEqual "list of suppliers"
      expect(scope.resetProducts).toHaveBeenCalledWith "list of products"
      expect(scope.spree_api_key_ok).toEqual true


  describe "resetting products", ->
    beforeEach ->
      spyOn scope, "unpackProduct"
      scope.products = {}
      scope.resetProducts [
        {
          id: 1
          name: "P1"
        }
        {
          id: 3
          name: "P2"
        }
      ]

    it "sets products to the value of 'data'", ->
      expect(scope.products).toEqual [
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
      expect(scope.dirtyProducts).toEqual {}

    it "calls unpackProduct once for each product", ->
      expect(scope.unpackProduct.calls.length).toEqual 2


  describe "preparing products", ->
    beforeEach ->
      spyOn scope, "matchSupplier"
      spyOn scope, "loadVariantUnit"

    it "initialises display properties for the product", ->
      product = {id: 123}
      scope.displayProperties = {}
      scope.unpackProduct product
      expect(scope.displayProperties[123]).toEqual {showVariants: false}

    it "calls matchSupplier for the product", ->
      product = {id: 123}
      scope.displayProperties = {}
      scope.unpackProduct product
      expect(scope.matchSupplier.calls.length).toEqual 1

    it "calls loadVariantUnit for the product", ->
      product = {id: 123}
      scope.displayProperties = {}
      scope.unpackProduct product
      expect(scope.loadVariantUnit.calls.length).toEqual 1


  describe "matching supplier", ->
    it "changes the supplier of the product to the one which matches it from the suppliers list", ->
      s1_s =
        id: 1
        name: "S1"

      s2_s =
        id: 2
        name: "S2"

      s1_p =
        id: 1
        name: "S1"

      expect(s1_s is s1_p).not.toEqual true
      scope.suppliers = [
        s1_s
        s2_s
      ]
      product =
        id: 10
        supplier: s1_p

      scope.matchSupplier product
      expect(product.supplier).toEqual s1_s


  describe "loading variant unit", ->
    describe "setting product variant_unit_with_scale field", ->
      it "sets by combining variant_unit and variant_unit_scale", ->
        product =
          variant_unit: "volume"
          variant_unit_scale: .001
        scope.loadVariantUnit product
        expect(product.variant_unit_with_scale).toEqual "volume_0.001"

      it "sets to null when variant_unit is null", ->
        product = {variant_unit: null, variant_unit_scale: 1000}
        scope.loadVariantUnit product
        expect(product.variant_unit_with_scale).toBeNull()

      it "sets to variant_unit when variant_unit_scale is null", ->
        product = {variant_unit: 'items', variant_unit_scale: null, variant_unit_name: 'foo'}
        scope.loadVariantUnit product
        expect(product.variant_unit_with_scale).toEqual "items"

      it "sets to variant_unit when variant_unit is 'items'", ->
        product = {variant_unit: 'items', variant_unit_scale: 1000, variant_unit_name: 'foo'}
        scope.loadVariantUnit product
        expect(product.variant_unit_with_scale).toEqual "items"

    describe "setting variant unit_value_with_description", ->
      it "sets by combining unit_value and unit_description", ->
        product =
          variants: [{id: 1, unit_value: 1, unit_description: '(bottle)'}]
        scope.loadVariantUnit product
        expect(product.variants[0]).toEqual
          id: 1
          unit_value: 1
          unit_description: '(bottle)'
          unit_value_with_description: '1 (bottle)'

      it "uses unit_value when description is missing", ->
        product =
          variants: [{id: 1, unit_value: 1}]
        scope.loadVariantUnit product
        expect(product.variants[0].unit_value_with_description).toEqual '1'

      it "uses unit_description when value is missing", ->
        product =
          variants: [{id: 1, unit_description: 'Small'}]
        scope.loadVariantUnit product
        expect(product.variants[0].unit_value_with_description).toEqual 'Small'


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
      expect(scope.onHand(p1)).toEqual 6

    it "ignores items in variants without an on_hand property (adds 0)", ->
      expect(scope.onHand(p2)).toEqual 5

    it "ignores on_hand properties of objects in arrays which are not named 'variants' (adds 0)", ->
      expect(scope.onHand(p3)).toEqual 3

    it "returns 'error' if not given an object with a variants property that is an object", ->
      expect(scope.onHand([])).toEqual "error"
      expect(scope.onHand(not_variants: [])).toEqual "error"


  describe "submitting products to be updated", ->
    describe "packing products", ->
      it "extracts variant_unit_with_scale into variant_unit and variant_unit_scale", ->
        testProduct =
          id: 1
          variant_unit: 'weight'
          variant_unit_scale: 1
          variant_unit_with_scale: 'volume_1000'

        scope.packProduct(testProduct)

        expect(testProduct).toEqual
          id: 1
          variant_unit: 'volume'
          variant_unit_scale: 1000
          variant_unit_with_scale: 'volume_1000'

      it "extracts when variant_unit_with_scale is 'items'", ->
        testProduct =
          id: 1
          variant_unit: 'weight'
          variant_unit_scale: 1
          variant_unit_with_scale: 'items'

        scope.packProduct(testProduct)

        expect(testProduct).toEqual
          id: 1
          variant_unit: 'items'
          variant_unit_scale: null
          variant_unit_with_scale: 'items'

      it "packs each variant", ->
        spyOn scope, "packVariant"
        testVariant = {id: 1}
        testProduct =
          id: 1
          variants: {1: testVariant}

        scope.packProduct(testProduct)

        expect(scope.packVariant).toHaveBeenCalledWith(testVariant)

    describe "packing variants", ->
      it "extracts unit_value and unit_description from unit_value_with_description", ->
        testVariant = {unit_value_with_description: "250.5 (bottle)"}
        scope.packVariant(testVariant)
        expect(testVariant).toEqual
          unit_value: 250.5
          unit_description: "(bottle)"
          unit_value_with_description: "250.5 (bottle)"

      it "extracts into unit_value when only a number is provided", ->
        testVariant = {unit_value_with_description: "250.5"}
        scope.packVariant(testVariant)
        expect(testVariant).toEqual
          unit_value: 250.5
          unit_description: ''
          unit_value_with_description: "250.5"

      it "extracts into unit_description when only a string is provided", ->
        testVariant = {unit_value_with_description: "Medium"}
        scope.packVariant(testVariant)
        expect(testVariant).toEqual
          unit_value: null
          unit_description: 'Medium'
          unit_value_with_description: "Medium"

      it "sets blank values when no value provided", ->
        testVariant = {unit_value_with_description: ""}
        scope.packVariant(testVariant)
        expect(testVariant).toEqual
          unit_value: null
          unit_description: ''
          unit_value_with_description: ""


    describe "filtering products", ->
      beforeEach ->
        spyOn scope, "packProduct"
        spyOn(window, "filterSubmitProducts").andReturn [
          {
            id: 1
            value: 3
          }
          {
            id: 2
            value: 4
          }
        ]
        spyOn scope, "updateProducts"
        scope.dirtyProducts =
          1:
            id: 1
          2:
            id: 2
        scope.products =
          1:
            id: 1
          2:
            id: 2

        scope.submitProducts()

      it "packs all products and all dirty products", ->
        expect(scope.packProduct.calls.length).toEqual 4

      it "filters returned dirty products", ->
        expect(filterSubmitProducts).toHaveBeenCalledWith
          1:
            id: 1
          2:
            id: 2


      it "sends dirty and filtered objects to submitProducts()", ->
        expect(scope.updateProducts).toHaveBeenCalledWith [
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
        httpBackend.expectPOST("/admin/products/bulk_update").respond "list of products"
        scope.updateProducts "list of products"
        httpBackend.flush()

      it "runs displaySuccess() when post returns success", ->
        spyOn scope, "displaySuccess"
        scope.products = [
          {
            id: 1
            name: "P1"
          }
          {
            id: 2
            name: "P2"
          }
        ]
        httpBackend.expectPOST("/admin/products/bulk_update").respond 200, [
          {
            id: 1
            name: "P1"
          }
          {
            id: 2
            name: "P2"
          }
        ]
        scope.updateProducts "list of dirty products"
        httpBackend.flush()
        expect(scope.displaySuccess).toHaveBeenCalled()

      it "runs displayFailure() when post return data does not match $scope.products", ->
        spyOn scope, "displayFailure"
        scope.products = "current list of products"
        httpBackend.expectPOST("/admin/products/bulk_update").respond 200, "returned list of products"
        scope.updateProducts "updated list of products"
        httpBackend.flush()
        expect(scope.displayFailure).toHaveBeenCalled()

      it "runs displayFailure() when post returns error", ->
        spyOn scope, "displayFailure"
        scope.products = "updated list of products"
        httpBackend.expectPOST("/admin/products/bulk_update").respond 404, "updated list of products"
        scope.updateProducts "updated list of products"
        httpBackend.flush()
        expect(scope.displayFailure).toHaveBeenCalled()


  describe "fetching products without derived attributes", ->
    it "returns products without the variant_unit_with_scale field", ->
      scope.products = [{id: 123, variant_unit_with_scale: 'weight_1000'}]
      expect(scope.productsWithoutDerivedAttributes()).toEqual([{id: 123}])

    it "returns an empty array when products are undefined", ->
      expect(scope.productsWithoutDerivedAttributes()).toEqual([])

    it "does not alter original products", ->
      scope.products = [{id: 123, variant_unit_with_scale: 'weight_1000'}]
      scope.productsWithoutDerivedAttributes()
      expect(scope.products).toEqual [{id: 123, variant_unit_with_scale: 'weight_1000'}]

    describe "updating variants", ->
      it "returns variants without the unit_value_with_description field", ->
        scope.products = [{id: 123, variants: [{id: 234, unit_value_with_description: 'foo'}]}]
        expect(scope.productsWithoutDerivedAttributes()).toEqual [
          {
            id: 123
            variants: [{id: 234}]
          }
        ]


  describe "deleting products", ->
    it "deletes products with a http delete request to /api/products/id", ->
      spyOn(window, "confirm").andReturn true
      scope.products = [
        {
          id: 9
          permalink_live: "apples"
        }
        {
          id: 13
          permalink_live: "oranges"
        }
      ]
      scope.dirtyProducts = {}
      httpBackend.expectDELETE("/api/products/13").respond 200, "data"
      scope.deleteProduct scope.products[1]
      httpBackend.flush()

    it "removes the specified product from both scope.products and scope.dirtyProducts (if it exists there)", ->
      spyOn(window, "confirm").andReturn true
      scope.products = [
        {
          id: 9
          permalink_live: "apples"
        }
        {
          id: 13
          permalink_live: "oranges"
        }
      ]
      scope.dirtyProducts =
        9:
          id: 9
          someProperty: "something"

        13:
          id: 13
          name: "P1"

      httpBackend.expectDELETE("/api/products/13").respond 200, "data"
      scope.deleteProduct scope.products[1]
      httpBackend.flush()
      expect(scope.products).toEqual [
        id: 9
        permalink_live: "apples"
      ]
      expect(scope.dirtyProducts).toEqual 9:
        id: 9
        someProperty: "something"



  describe "deleting variants", ->
    it "deletes variants with a http delete request to /api/products/product_id/variants/(variant_id)", ->
      spyOn(window, "confirm").andReturn true
      scope.products = [
        {
          id: 9
          permalink_live: "apples"
          variants: [
            id: 3
            price: 12
          ]
        }
        {
          id: 13
          permalink_live: "oranges"
        }
      ]
      scope.dirtyProducts = {}
      httpBackend.expectDELETE("/api/products/9/variants/3").respond 200, "data"
      scope.deleteVariant scope.products[0], scope.products[0].variants[0]
      httpBackend.flush()

    it "removes the specified variant from both the variants object and scope.dirtyProducts (if it exists there)", ->
      spyOn(window, "confirm").andReturn true
      scope.products = [
        {
          id: 9
          permalink_live: "apples"
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
          permalink_live: "oranges"
        }
      ]
      scope.dirtyProducts =
        9:
          id: 9
          variants:
            3:
              id: 3
              price: 12.0

            4:
              id: 4
              price: 6.0

        13:
          id: 13
          name: "P1"

      httpBackend.expectDELETE("/api/products/9/variants/3").respond 200, "data"
      scope.deleteVariant scope.products[0], scope.products[0].variants[0]
      httpBackend.flush()
      expect(scope.products[0].variants).toEqual [
        id: 4
        price: 6.0
      ]
      expect(scope.dirtyProducts).toEqual
        9:
          id: 9
          variants:
            4:
              id: 4
              price: 6.0

        13:
          id: 13
          name: "P1"



  describe "cloning products", ->
    it "clones products using a http get request to /admin/products/(permalink)/clone.json", ->
      scope.products = [
        id: 13
        permalink_live: "oranges"
      ]
      httpBackend.expectGET("/admin/products/oranges/clone.json").respond 200,
        product:
          id: 17
          name: "new_product"

      httpBackend.expectGET("/api/products/17?template=bulk_show").respond 200, [
        id: 17
        name: "new_product"
      ]
      scope.cloneProduct scope.products[0]
      httpBackend.flush()

    it "adds the newly created product to scope.products and matches supplier", ->
      spyOn(scope, "unpackProduct").andCallThrough()
      scope.products = [
        id: 13
        permalink_live: "oranges"
      ]
      httpBackend.expectGET("/admin/products/oranges/clone.json").respond 200,
        product:
          id: 17
          name: "new_product"
          supplier:
            id: 6

          variants: [
            id: 3
            name: "V1"
          ]

      httpBackend.expectGET("/api/products/17?template=bulk_show").respond 200,
        id: 17
        name: "new_product"
        supplier:
          id: 6

        variants: [
          id: 3
          name: "V1"
        ]

      scope.cloneProduct scope.products[0]
      httpBackend.flush()
      expect(scope.unpackProduct).toHaveBeenCalledWith
        id: 17
        name: "new_product"
        variant_unit_with_scale: null
        supplier:
          id: 6

        variants: [
          id: 3
          name: "V1"
          unit_value_with_description: ""
        ]

      expect(scope.products).toEqual [
        {
          id: 13
          permalink_live: "oranges"
        }
        {
          id: 17
          name: "new_product"
          variant_unit_with_scale: null
          supplier:
            id: 6

          variants: [
            id: 3
            name: "V1"
            unit_value_with_description: ""
          ]
        }
      ]



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
    spyOn(window, "toObjectWithIDKeys").andCallThrough()
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
