describe "BulkProducts service", ->
  BulkProducts = $httpBackend = null

  beforeEach ->
    module "ofn.admin"
    window.bigDecimal = jasmine.createSpyObj "bigDecimal", ["round"]
    window.bigDecimal.round.and.callFake (a, b) -> a.toFixed(b)

  beforeEach inject (_BulkProducts_, _$httpBackend_) ->
    BulkProducts = _BulkProducts_
    $httpBackend = _$httpBackend_

  describe "cloning products", ->
    it "clones products using a http post request to /api/products/(id)/clone", ->
      BulkProducts.products = [
        id: 13
      ]
      $httpBackend.expectPOST("/api/v0/products/13/clone").respond 201,
        id: 17
      $httpBackend.expectGET("/api/v0/products/17?template=bulk_show").respond 200, [
        id: 17
      ]
      BulkProducts.cloneProduct BulkProducts.products[0]
      $httpBackend.flush()

    it "adds the product", ->
      originalProduct =
        id: 16
      clonedProduct =
        id: 17

      spyOn(BulkProducts, "insertProductAfter")
      spyOn(BulkProducts, "unpackProduct")
      BulkProducts.products = [originalProduct]
      $httpBackend.expectPOST("/api/v0/products/16/clone").respond 201, clonedProduct
      $httpBackend.expectGET("/api/v0/products/17?template=bulk_show").respond 200, clonedProduct
      BulkProducts.cloneProduct BulkProducts.products[0]
      $httpBackend.flush()
      expect(BulkProducts.unpackProduct).toHaveBeenCalledWith clonedProduct
      BulkProducts.unpackProduct(clonedProduct)
      expect(BulkProducts.insertProductAfter).toHaveBeenCalledWith originalProduct, clonedProduct


  describe "preparing products", ->
    beforeEach ->
      spyOn BulkProducts, "loadVariantUnit"

    it "calls loadVariantUnit for the product", ->
      product = {id: 123}
      BulkProducts.unpackProduct product
      expect(BulkProducts.loadVariantUnit).toHaveBeenCalled()


  describe "loading variant unit", ->
    describe "setting product variant_unit_with_scale field", ->
      it "sets by combining variant_unit and variant_unit_scale", ->
        product =
          variant_unit: "volume"
          variant_unit_scale: .001
        BulkProducts.loadVariantUnit product
        expect(product.variant_unit_with_scale).toEqual "volume_0.001"

      it "sets to null when variant_unit is null", ->
        product = {variant_unit: null, variant_unit_scale: 1000}
        BulkProducts.loadVariantUnit product
        expect(product.variant_unit_with_scale).toBeNull()

      it "sets to variant_unit when variant_unit_scale is null", ->
        product = {variant_unit: 'items', variant_unit_scale: null, variant_unit_name: 'foo'}
        BulkProducts.loadVariantUnit product
        expect(product.variant_unit_with_scale).toEqual "items"

      it "sets to variant_unit when variant_unit is 'items'", ->
        product = {variant_unit: 'items', variant_unit_scale: 1000, variant_unit_name: 'foo'}
        BulkProducts.loadVariantUnit product
        expect(product.variant_unit_with_scale).toEqual "items"

    it "loads data for variants (incl. master)", ->
      spyOn BulkProducts, "loadVariantUnitValues"
      spyOn BulkProducts, "loadVariantUnitValue"

      product =
        variant_unit_scale: 1.0
        master: {id: 1, unit_value: 1, unit_description: '(one)'}
        variants: [{id: 2, unit_value: 2, unit_description: '(two)'}]
      BulkProducts.loadVariantUnit product

      expect(BulkProducts.loadVariantUnitValues).toHaveBeenCalledWith product
      expect(BulkProducts.loadVariantUnitValue).toHaveBeenCalledWith product, product.master

    it "loads data for variants (excl. master)", ->
      spyOn BulkProducts, "loadVariantUnitValue"

      product =
        variant_unit_scale: 1.0
        master: {id: 1, unit_value: 1, unit_description: '(one)'}
        variants: [{id: 2, unit_value: 2, unit_description: '(two)'}]
      BulkProducts.loadVariantUnitValues product

      expect(BulkProducts.loadVariantUnitValue).toHaveBeenCalledWith product, product.variants[0]
      expect(BulkProducts.loadVariantUnitValue).not.toHaveBeenCalledWith product, product.master

    describe "setting variant unit_value_with_description", ->
      it "sets by combining unit_value and unit_description", ->
        product =
          variant_unit_scale: 1.0
          variants: [{id: 1, unit_value: 1, unit_description: '(bottle)'}]
        BulkProducts.loadVariantUnitValues product, product.variants[0]
        expect(product.variants[0]).toEqual
          id: 1
          unit_value: 1
          unit_description: '(bottle)'
          unit_value_with_description: '1 (bottle)'

      it "uses unit_value when description is missing", ->
        product =
          variant_unit_scale: 1.0
          variants: [{id: 1, unit_value: 1}]
        BulkProducts.loadVariantUnitValues product, product.variants[0]
        expect(product.variants[0].unit_value_with_description).toEqual '1'

      it "uses unit_description when value is missing", ->
        product =
          variant_unit_scale: 1.0
          variants: [{id: 1, unit_description: 'Small'}]
        BulkProducts.loadVariantUnitValues product, product.variants[0]
        expect(product.variants[0].unit_value_with_description).toEqual 'Small'

      it "converts values from base value to chosen unit", ->
        product =
          variant_unit_scale: 1000.0
          variants: [{id: 1, unit_value: 2500}]
        BulkProducts.loadVariantUnitValues product, product.variants[0]
        expect(product.variants[0].unit_value_with_description).toEqual '2.5'

      it "converts values from base value to chosen unit without breaking precision", ->
        product =
          variant_unit_scale: 0.001
          variants: [{id: 1, unit_value: 0.35}]
        BulkProducts.loadVariantUnitValues product, product.variants[0]
        expect(product.variants[0].unit_value_with_description).toEqual '350'

      it "displays a unit_value of zero", ->
        product =
          variant_unit_scale: 1.0
          variants: [{id: 1, unit_value: 0}]
        BulkProducts.loadVariantUnitValues product, product.variants[0]
        expect(product.variants[0].unit_value_with_description).toEqual '0'


  describe "calculating the scaled unit value for a variant", ->
    it "returns the scaled value when variant has a unit_value", ->
      product = {variant_unit_scale: 0.001}
      variant = {unit_value: 5}
      expect(BulkProducts.variantUnitValue(product, variant)).toEqual 5000

    it "returns the scaled value rounded off upto 2 decimal points", ->
      product = {variant_unit_scale: 28.35}
      variant = {unit_value: 1234.5}
      expect(BulkProducts.variantUnitValue(product, variant)).toEqual 43.54

    it "returns the unscaled value when the product has no scale", ->
      product = {}
      variant = {unit_value: 5}
      expect(BulkProducts.variantUnitValue(product, variant)).toEqual 5

    it "returns zero when the value is zero", ->
      product = {}
      variant = {unit_value: 0}
      expect(BulkProducts.variantUnitValue(product, variant)).toEqual 0

    it "returns null when the variant has no unit_value", ->
      product = {}
      variant = {}
      expect(BulkProducts.variantUnitValue(product, variant)).toEqual null


  describe "fetching a product by id", ->
    it "returns the product when it is present", ->
      product = {id: 123}
      BulkProducts.products = [product]
      expect(BulkProducts.find(123)).toEqual product

    it "returns null when the product is not present", ->
      BulkProducts.products = []
      expect(BulkProducts.find(123)).toBeNull()
