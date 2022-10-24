describe "enterpriseCtrl", ->
  ctrl = null
  scope = null
  enterprise = null
  PaymentMethods = null
  Enterprises = null
  StatusMessage = null

  beforeEach ->
    module('admin.enterprises')
    enterprise =
      is_primary_producer: true
      sells: "none"
      owner:
        id: 98
    receivesNotifications = 99

    inject ($rootScope, $controller, _Enterprises_, _StatusMessage_) ->
      scope = $rootScope
      Enterprises = _Enterprises_
      StatusMessage = _StatusMessage_
      ctrl = $controller "enterpriseCtrl", {$scope: scope, enterprise: enterprise, EnterprisePaymentMethods: PaymentMethods, Enterprises: Enterprises, StatusMessage: StatusMessage, receivesNotifications: receivesNotifications}

  describe "initialisation", ->
    it "stores enterprise", ->
      expect(scope.Enterprise).toEqual enterprise
