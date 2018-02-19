describe "EnterpriseShippingMethods service", ->
  enterprise = null
  ShippingMethods = null
  EnterpriseShippingMethods = null

  beforeEach ->
    enterprise =
      shipping_method_ids: [ 1, 3 ]
    ShippingMethods =
        all: [ { id: 1 }, { id: 2 }, { id: 3 }, { id: 4 } ]

    module 'admin.enterprises'
    module ($provide) ->
      $provide.value 'ShippingMethods', ShippingMethods
      $provide.value 'enterprise', enterprise
      null

    inject (_EnterpriseShippingMethods_) ->
      EnterpriseShippingMethods = _EnterpriseShippingMethods_

  describe "selecting shipping methods", ->
    it "sets the selected property of each shipping method", ->
      expect(ShippingMethods.all[0].selected).toBe true
      expect(ShippingMethods.all[1].selected).toBe false
      expect(ShippingMethods.all[2].selected).toBe true
      expect(ShippingMethods.all[3].selected).toBe false

  describe "determining shipping method colour", ->
    it "returns 'blue' when at least one shipping method is selected", ->
      spyOn(EnterpriseShippingMethods, "selectedCount").and.returnValue 1
      expect(EnterpriseShippingMethods.displayColor()).toBe "blue"

    it "returns 'red' when no shipping methods are selected", ->
      spyOn(EnterpriseShippingMethods, "selectedCount").and.returnValue 0
      expect(EnterpriseShippingMethods.displayColor()).toBe "red"

    it "returns 'red' when no shipping methods exist", ->
      EnterpriseShippingMethods.shippingMethods = []
      spyOn(EnterpriseShippingMethods, "selectedCount").and.returnValue 1
      expect(EnterpriseShippingMethods.displayColor()).toBe "red"

  describe "counting selected shipping methods", ->
    it "counts only shipping methods with selected: true", ->
      expect(EnterpriseShippingMethods.selectedCount()).toBe 2
