describe "ProvidersCtrl", ->
  ctrl = null
  scope = null
  paymentMethod = null

  describe "initialising using a payment method without a type", ->
    beforeEach ->
      module 'admin.paymentMethods'
      scope = {}
      paymentMethod =
        type: null

      inject ($controller)->
        ctrl = $controller 'ProvidersCtrl', {$scope: scope, paymentMethod: paymentMethod }

    it "sets the invlude_html porperty on scope to blank", ->
      expect(scope.include_html).toBe ""

  describe "initialising using a payment method with a type", ->
    beforeEach ->
      module 'admin.paymentMethods'
      scope = {}
      paymentMethod =
        type: "NOT NULL"

      inject ($controller)->
        ctrl = $controller 'ProvidersCtrl', {$scope: scope, paymentMethod: paymentMethod }

    it "sets the include_html porperty on scope to some address", ->
      expect(scope.include_html).toBe "/admin/payment_methods/show_provider_preferences?provider_type=NOT NULL;pm_id=#{paymentMethod.id || ''};"
