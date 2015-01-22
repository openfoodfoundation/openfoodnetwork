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
        is_primary_producer: true
        sells: "none"
    PaymentMethods =
      paymentMethods: "payment methods"
    ShippingMethods =
      shippingMethods: "shipping methods"

    inject ($rootScope, $controller) ->
      scope = $rootScope
      ctrl = $controller 'enterpriseCtrl', {$scope: scope, Enterprise: Enterprise, EnterprisePaymentMethods: PaymentMethods, EnterpriseShippingMethods: ShippingMethods}

  describe "initialisation", ->
    it "stores enterprise", ->
      expect(scope.Enterprise).toEqual Enterprise.enterprise

    it "stores payment methods", ->
      expect(scope.PaymentMethods).toBe PaymentMethods.paymentMethods

    it "stores shipping methods", ->
      expect(scope.ShippingMethods).toBe ShippingMethods.shippingMethods
