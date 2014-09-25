describe "enterpriseCtrl", ->
  ctrl = null
  scope = null
  Enterprise = null
  PaymentMethods = null
  ShippingMethods = null

  beforeEach ->
    module('admin.enterprises')
    Enterprise =
      enterprise:
        payment_method_ids: [ 1, 3 ]
        shipping_method_ids: [ 2, 4 ]
    PaymentMethods =
      paymentMethods: [ { id: 1 }, { id: 2 }, { id: 3 }, { id: 4 } ]
    ShippingMethods =
      shippingMethods: [ { id: 1 }, { id: 2 }, { id: 3 }, { id: 4 } ]

    inject ($controller) ->
      scope = {}
      ctrl = $controller 'enterpriseCtrl', {$scope: scope, Enterprise: Enterprise, PaymentMethods: PaymentMethods, ShippingMethods: ShippingMethods}

  describe "initialisation", ->
    it "stores enterprise", ->
      expect(scope.Enterprise).toEqual Enterprise.enterprise

    it "stores payment methods", ->
      expect(scope.PaymentMethods).toBe PaymentMethods.paymentMethods

    it "stores shipping methods", ->
      expect(scope.ShippingMethods).toBe ShippingMethods.shippingMethods

    it "sets the selected property of each payment method", ->
      expect(PaymentMethods.paymentMethods[0].selected).toBe true
      expect(PaymentMethods.paymentMethods[1].selected).toBe false
      expect(PaymentMethods.paymentMethods[2].selected).toBe true
      expect(PaymentMethods.paymentMethods[3].selected).toBe false

    it "sets the selected property of each shipping method", ->
      expect(ShippingMethods.shippingMethods[0].selected).toBe false
      expect(ShippingMethods.shippingMethods[1].selected).toBe true
      expect(ShippingMethods.shippingMethods[2].selected).toBe false
      expect(ShippingMethods.shippingMethods[3].selected).toBe true

  describe "determining payment method colour", ->
    it "returns 'blue' when at least one payment method is selected", ->
      scope.PaymentMethods = [ { id: 1 } ]
      spyOn(scope, "selectedPaymentMethodsCount").andReturn 1
      expect(scope.paymentMethodsColor()).toBe "blue"

    it "returns 'red' when no payment methods are selected", ->
      scope.PaymentMethods = [ { id: 1 } ]
      spyOn(scope, "selectedPaymentMethodsCount").andReturn 0
      expect(scope.paymentMethodsColor()).toBe "red"

    it "returns 'red' when no payment methods exist", ->
      scope.PaymentMethods = [ ]
      spyOn(scope, "selectedPaymentMethodsCount").andReturn 1
      expect(scope.paymentMethodsColor()).toBe "red"

  describe "counting selected payment methods", ->
    it "counts only payment methods with selected: true", ->
      scopePaymentMethods = [ { selected: true }, { selected: false }, { selected: false }, { selected: true } ]
      expect(scope.selectedPaymentMethodsCount()).toBe 2

  describe "determining shipping method colour", ->
    it "returns 'blue' when at least one shipping method is selected", ->
      scope.ShippingMethods = [ { id: 1 } ]
      spyOn(scope, "selectedShippingMethodsCount").andReturn 1
      expect(scope.shippingMethodsColor()).toBe "blue"

    it "returns 'red' when no shipping methods are selected", ->
      scope.ShippingMethods = [ { id: 1 } ]
      spyOn(scope, "selectedShippingMethodsCount").andReturn 0
      expect(scope.shippingMethodsColor()).toBe "red"

    it "returns 'red' when no shipping method exist", ->
      scope.ShippingMethods = [ ]
      spyOn(scope, "selectedShippingMethodsCount").andReturn 1
      expect(scope.shippingMethodsColor()).toBe "red"

  describe "counting selected shipping methods", ->
    it "counts only shipping methods with selected: true", ->
      scope.ShippingMethods = [ { selected: true }, { selected: true }, { selected: false }, { selected: true } ]
      expect(scope.selectedShippingMethodsCount()).toBe 3
