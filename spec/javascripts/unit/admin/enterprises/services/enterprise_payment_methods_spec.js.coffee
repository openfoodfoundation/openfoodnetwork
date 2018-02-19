describe "EnterprisePaymentMethods service", ->
  enterprise = null
  PaymentMethods = null
  EnterprisePaymentMethods = null

  beforeEach ->
    enterprise =
      payment_method_ids: [ 1, 3 ]
    PaymentMethods =
        all: [ { id: 1 }, { id: 2 }, { id: 3 }, { id: 4 } ]

    module 'admin.enterprises'
    module ($provide) ->
      $provide.value 'PaymentMethods', PaymentMethods
      $provide.value 'enterprise', enterprise
      null

    inject (_EnterprisePaymentMethods_) ->
      EnterprisePaymentMethods = _EnterprisePaymentMethods_

  describe "selecting payment methods", ->
    it "sets the selected property of each payment method", ->
      expect(PaymentMethods.all[0].selected).toBe true
      expect(PaymentMethods.all[1].selected).toBe false
      expect(PaymentMethods.all[2].selected).toBe true
      expect(PaymentMethods.all[3].selected).toBe false

  describe "determining payment method colour", ->
    it "returns 'blue' when at least one payment method is selected", ->
      spyOn(EnterprisePaymentMethods, "selectedCount").and.returnValue 1
      expect(EnterprisePaymentMethods.displayColor()).toBe "blue"

    it "returns 'red' when no payment methods are selected", ->
      spyOn(EnterprisePaymentMethods, "selectedCount").and.returnValue 0
      expect(EnterprisePaymentMethods.displayColor()).toBe "red"

    it "returns 'red' when no payment methods exist", ->
      EnterprisePaymentMethods.paymentMethods = []
      spyOn(EnterprisePaymentMethods, "selectedCount").and.returnValue 1
      expect(EnterprisePaymentMethods.displayColor()).toBe "red"

  describe "counting selected payment methods", ->
    it "counts only payment methods with selected: true", ->
      expect(EnterprisePaymentMethods.selectedCount()).toBe 2
