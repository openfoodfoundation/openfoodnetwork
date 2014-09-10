  # describe "fetching products", ->
  #   it "makes a standard call to dataFetcher when no filters exist", ->
  #     $httpBackend.expectGET("/api/products/bulk_products?page=1;per_page=20;").respond "list of products"
  #     $scope.fetchProducts()

  #   it "calls makes more calls to dataFetcher if more pages exist", ->
  #     $httpBackend.expectGET("/api/products/bulk_products?page=1;per_page=20;").respond { products: [], pages: 2 }
  #     $httpBackend.expectGET("/api/products/bulk_products?page=2;per_page=20;").respond { products: ["list of products"] }
  #     $scope.fetchProducts()
  #     $httpBackend.flush()

  #   it "applies filters when they are present", ->
  #     filter = {property: $scope.filterableColumns[1], predicate:$scope.filterTypes[0], value:"Product1"}
  #     $scope.currentFilters.push filter # Don't use addFilter as that is not what we are testing
  #     expect($scope.currentFilters).toEqual [filter]
  #     $httpBackend.expectGET("/api/products/bulk_products?page=1;per_page=20;q[name_eq]=Product1;").respond "list of products"
  #     $scope.fetchProducts()
  #     $httpBackend.flush()


  # describe "preparing products", ->
  #   beforeEach ->
  #     spyOn $scope, "loadVariantUnit"

  #   it "initialises display properties for the product", ->
  #     product = {id: 123}
  #     $scope.displayProperties = {}
  #     $scope.unpackProduct product
  #     expect($scope.displayProperties[123]).toEqual {showVariants: false}

  #   it "calls loadVariantUnit for the product", ->
  #     product = {id: 123}
  #     $scope.displayProperties = {}
  #     $scope.unpackProduct product
  #     expect($scope.loadVariantUnit.calls.length).toEqual 1


  # describe "loading variant unit", ->
  #   describe "setting product variant_unit_with_scale field", ->
  #     it "sets by combining variant_unit and variant_unit_scale", ->
  #       product =
  #         variant_unit: "volume"
  #         variant_unit_scale: .001
  #       $scope.loadVariantUnit product
  #       expect(product.variant_unit_with_scale).toEqual "volume_0.001"

  #     it "sets to null when variant_unit is null", ->
  #       product = {variant_unit: null, variant_unit_scale: 1000}
  #       $scope.loadVariantUnit product
  #       expect(product.variant_unit_with_scale).toBeNull()

  #     it "sets to variant_unit when variant_unit_scale is null", ->
  #       product = {variant_unit: 'items', variant_unit_scale: null, variant_unit_name: 'foo'}
  #       $scope.loadVariantUnit product
  #       expect(product.variant_unit_with_scale).toEqual "items"

  #     it "sets to variant_unit when variant_unit is 'items'", ->
  #       product = {variant_unit: 'items', variant_unit_scale: 1000, variant_unit_name: 'foo'}
  #       $scope.loadVariantUnit product
  #       expect(product.variant_unit_with_scale).toEqual "items"

  #   it "loads data for variants (incl. master)", ->
  #     spyOn $scope, "loadVariantUnitValues"
  #     spyOn $scope, "loadVariantUnitValue"

  #     product =
  #       variant_unit_scale: 1.0
  #       master: {id: 1, unit_value: 1, unit_description: '(one)'}
  #       variants: [{id: 2, unit_value: 2, unit_description: '(two)'}]
  #     $scope.loadVariantUnit product

  #     expect($scope.loadVariantUnitValues).toHaveBeenCalledWith product
  #     expect($scope.loadVariantUnitValue).toHaveBeenCalledWith product, product.master

  #   it "loads data for variants (excl. master)", ->
  #     spyOn $scope, "loadVariantUnitValue"

  #     product =
  #       variant_unit_scale: 1.0
  #       master: {id: 1, unit_value: 1, unit_description: '(one)'}
  #       variants: [{id: 2, unit_value: 2, unit_description: '(two)'}]
  #     $scope.loadVariantUnitValues product

  #     expect($scope.loadVariantUnitValue).toHaveBeenCalledWith product, product.variants[0]
  #     expect($scope.loadVariantUnitValue).not.toHaveBeenCalledWith product, product.master

  #   describe "setting variant unit_value_with_description", ->
  #     it "sets by combining unit_value and unit_description", ->
  #       product =
  #         variant_unit_scale: 1.0
  #         variants: [{id: 1, unit_value: 1, unit_description: '(bottle)'}]
  #       $scope.loadVariantUnitValues product, product.variants[0]
  #       expect(product.variants[0]).toEqual
  #         id: 1
  #         unit_value: 1
  #         unit_description: '(bottle)'
  #         unit_value_with_description: '1 (bottle)'

  #     it "uses unit_value when description is missing", ->
  #       product =
  #         variant_unit_scale: 1.0
  #         variants: [{id: 1, unit_value: 1}]
  #       $scope.loadVariantUnitValues product, product.variants[0]
  #       expect(product.variants[0].unit_value_with_description).toEqual '1'

  #     it "uses unit_description when value is missing", ->
  #       product =
  #         variant_unit_scale: 1.0
  #         variants: [{id: 1, unit_description: 'Small'}]
  #       $scope.loadVariantUnitValues product, product.variants[0]
  #       expect(product.variants[0].unit_value_with_description).toEqual 'Small'

  #     it "converts values from base value to chosen unit", ->
  #       product =
  #         variant_unit_scale: 1000.0
  #         variants: [{id: 1, unit_value: 2500}]
  #       $scope.loadVariantUnitValues product, product.variants[0]
  #       expect(product.variants[0].unit_value_with_description).toEqual '2.5'

  #     it "displays a unit_value of zero", ->
  #       product =
  #         variant_unit_scale: 1.0
  #         variants: [{id: 1, unit_value: 0}]
  #       $scope.loadVariantUnitValues product, product.variants[0]
  #       expect(product.variants[0].unit_value_with_description).toEqual '0'


  # describe "calculating the scaled unit value for a variant", ->
  #   it "returns the scaled value when variant has a unit_value", ->
  #     product = {variant_unit_scale: 0.001}
  #     variant = {unit_value: 5}
  #     expect($scope.variantUnitValue(product, variant)).toEqual 5000

  #   it "returns the unscaled value when the product has no scale", ->
  #     product = {}
  #     variant = {unit_value: 5}
  #     expect($scope.variantUnitValue(product, variant)).toEqual 5

  #   it "returns zero when the value is zero", ->
  #     product = {}
  #     variant = {unit_value: 0}
  #     expect($scope.variantUnitValue(product, variant)).toEqual 0

  #   it "returns null when the variant has no unit_value", ->
  #     product = {}
  #     variant = {}
  #     expect($scope.variantUnitValue(product, variant)).toEqual null


