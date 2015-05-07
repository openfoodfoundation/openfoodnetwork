describe "CustomersCtrl", ->
  ctrl = null
  scope = null
  Customers = null

  beforeEach ->
    shops = "list of shops"

    module('admin.customers')
    inject ($controller, $rootScope, _Customers_) ->
      scope = $rootScope
      Customers = _Customers_
      ctrl = $controller 'customersCtrl', {$scope: scope, Customers: Customers, shops: shops}

  describe "initialise()", ->
    beforeEach ->
      spyOn(Customers, "index").andReturn "list of customers"
      scope.shop = {id: 1}
      scope.initialise()

    it "calls Customers#index with the correct params", ->
      expect(Customers.index).toHaveBeenCalledWith({enterprise_id: 1})

    it "resets $scope.customers with the result of Customers#index", ->
      expect(scope.customers).toEqual "list of customers"
