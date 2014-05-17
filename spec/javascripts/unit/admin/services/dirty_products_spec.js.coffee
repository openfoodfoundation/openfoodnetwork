describe "Maintaining a live record of dirty products and properties", ->
  DirtyProducts = null
  
  beforeEach ->
    module "ofn.admin"

  beforeEach inject (_DirtyProducts_) ->
    DirtyProducts = _DirtyProducts_

  describe "adding a new change", ->
    it "adds a new object with key of id if it does not already exist", ->
      expect(DirtyProducts.all()).toEqual {}
      expect(DirtyProducts.all()["1"]).not.toBeDefined()
      DirtyProducts.addProductProperty 1, "propertyName", { a: 1 }
      expect(DirtyProducts.all()["1"]).toBeDefined()

    it "adds an id attribute to newly created objects in dirtyProducts", ->
      expect(DirtyProducts.all()).toEqual {}
      DirtyProducts.addProductProperty 1, "propertyName", "val1"
      expect(DirtyProducts.all()["1"]).toBeDefined()
      expect(DirtyProducts.all()["1"]["id"]).toBeDefined()
      expect(DirtyProducts.all()["1"]["id"]).toBe 1

    it "adds a new object with key of the altered attribute name if it does not already exist", ->
      DirtyProducts.addProductProperty 1, "propertyName", { a: 1 }
      expect(DirtyProducts.all()["1"]).toBeDefined()
      expect(DirtyProducts.all()["1"]["propertyName"]).toEqual { a: 1 }

    it "replaces the existing object when adding a change to an attribute which already exists", ->
      DirtyProducts.addProductProperty 1, "propertyName", "val1"
      expect(DirtyProducts.all()["1"]).toBeDefined()
      expect(DirtyProducts.all()["1"]["propertyName"]).toBe "val1"
      DirtyProducts.addProductProperty 1, "propertyName", "val2"
      expect(DirtyProducts.all()["1"]["propertyName"]).toBe "val2"

   it "adds an attribute to key to a line item object when one already exists", ->
      DirtyProducts.addProductProperty 1, "propertyName1", "val1"
      DirtyProducts.addProductProperty 1, "propertyName2", "val2"
      expect(DirtyProducts.all()["1"]).toBeDefined()
      expect(DirtyProducts.all()["1"].hasOwnProperty "propertyName1").toBe true
      expect(DirtyProducts.all()["1"]["propertyName1"]).toBe "val1"
      expect(DirtyProducts.all()["1"].hasOwnProperty "propertyName2").toBe true
      expect(DirtyProducts.all()["1"]["propertyName2"]).toBe "val2"

  describe "clearing all existing changes", ->
    it "resets pendingChanges object", ->
      DirtyProducts.addProductProperty 1, "PropertyName1", "val1"
      DirtyProducts.addProductProperty 1, "PropertyName2", "val2"
      expect(DirtyProducts.all()["1"]["PropertyName1"]).toBeDefined()
      expect(DirtyProducts.all()["1"]["PropertyName2"]).toBeDefined()
      DirtyProducts.clear()
      expect(DirtyProducts.all()["1"]).not.toBeDefined()
      expect(DirtyProducts.all()).toEqual {}

  describe "removing an existing dirty product", ->
    it "deletes a change if it exists", ->
      DirtyProducts.addProductProperty 1, "PropertyName1", "val1"
      DirtyProducts.addProductProperty 2, "PropertyName2", "val2"
      expect(DirtyProducts.all()["1"]["PropertyName1"]).toBeDefined()
      DirtyProducts.deleteProduct 1
      expect(DirtyProducts.all()["1"]).not.toBeDefined()
      expect(DirtyProducts.all()["2"]).toBeDefined()
      
    it "does nothing if id key does not exist", ->
      DirtyProducts.addProductProperty 1, "PropertyName1", "val1"
      expect(DirtyProducts.all()["1"]["PropertyName1"]).toBeDefined()
      DirtyProducts.deleteProduct 3
      expect(DirtyProducts.all()["1"]["PropertyName1"]).toEqual "val1"

  describe "removing an attribute of an existing dirty product", ->
    it "removes the attribute", ->
      DirtyProducts.addProductProperty 1, "PropertyName1", "val1"
      DirtyProducts.addProductProperty 1, "PropertyName2", "val2"
      DirtyProducts.removeProductProperty 1, "PropertyName1"
      expect(DirtyProducts.all()["1"]["PropertyName1"]).not.toBeDefined()
      expect(DirtyProducts.all()["1"]["PropertyName2"]).toBeDefined()
    
    it "calls deleteProduct on the productID if no other properties are defined on it", ->
      spyOn(DirtyProducts, "deleteProduct")
      DirtyProducts.addProductProperty 1, "PropertyName1", "val1"
      DirtyProducts.removeProductProperty 1, "PropertyName1"
      expect(DirtyProducts.deleteProduct).toHaveBeenCalledWith 1

  describe "removing an existing dirty variant", ->
    it "removes the variant from the variants object", ->
      DirtyProducts.addVariantProperty 1, 3, "PropertyName1", "val1"
      DirtyProducts.addProductProperty 1, "PropertyName2", "val2"
      DirtyProducts.deleteVariant 1, 3
      expect(DirtyProducts.all()["1"]["variants"]).not.toBeDefined()

    it "calls removeProductProperty on the products if the variants list becomes empty", ->
      spyOn(DirtyProducts, "removeProductProperty")
      DirtyProducts.addVariantProperty 1, 3, "PropertyName1", "val1"
      DirtyProducts.addProductProperty 1, "PropertyName2", "val2"
      DirtyProducts.deleteVariant 1, 3
      expect(DirtyProducts.removeProductProperty).toHaveBeenCalledWith 1, "variants"

  describe "removing an attribute of an existing dirty variant", ->
    it "removes the attribute from the variant object", ->
      DirtyProducts.addVariantProperty 1, 3, "PropertyName1", "val1"
      DirtyProducts.addVariantProperty 1, 3, "PropertyName2", "val2"
      DirtyProducts.removeVariantProperty 1, 3, "PropertyName1"
      expect(DirtyProducts.all()["1"]["variants"]["3"]["PropertyName1"]).not.toBeDefined()
      expect(DirtyProducts.all()["1"]["variants"]["3"]["PropertyName2"]).toBeDefined()
    
    it "calls deleteVariant on the variantID if no other properties are defined on it", ->
      spyOn(DirtyProducts, "deleteVariant")
      DirtyProducts.addVariantProperty 1, 3, "PropertyName1", "val1"
      DirtyProducts.addProductProperty 1, "PropertyName1", "val2"
      DirtyProducts.removeVariantProperty 1, 3, "PropertyName1"
      expect(DirtyProducts.deleteVariant).toHaveBeenCalledWith 1, 3