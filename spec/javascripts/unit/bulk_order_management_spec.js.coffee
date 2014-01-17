describe "AdminOrderMgmtCtrl", ->
  ctrl = scope = httpBackend = null

  beforeEach ->
    module "ofn.bulk_order_management"
  beforeEach inject(($controller, $rootScope, $httpBackend) ->
    scope = $rootScope.$new()
    ctrl = $controller
    httpBackend = $httpBackend

    ctrl "AdminOrderMgmtCtrl", {$scope: scope}
  )

  describe "loading data upon initialisation", ->
    it "gets a list of suppliers and then calls fetchOrders", ->
      httpBackend.expectGET("/api/users/authorise_api?token=api_key").respond success: "Use of API Authorised"
      httpBackend.expectGET("/api/enterprises/managed?template=bulk_index&q[is_primary_producer_eq]=true").respond "list of suppliers"
      spyOn(scope, "fetchOrders").andReturn "nothing"
      scope.initialise "api_key"
      httpBackend.flush()
      expect(scope.suppliers).toEqual "list of suppliers"
      expect(scope.fetchOrders.calls.length).toEqual 1
      expect(scope.spree_api_key_ok).toEqual true

  describe "fetching orders", ->
    it "makes a standard call to dataFetcher", ->
      httpBackend.expectGET("/api/orders?template=bulk_index").respond "list of orders"
      scope.fetchOrders()

    it "calls resetOrders after data has been received", ->
      spyOn scope, "resetOrders"
      httpBackend.expectGET("/api/orders?template=bulk_index").respond "list of orders"
      scope.fetchOrders()
      httpBackend.flush()
      expect(scope.resetOrders).toHaveBeenCalledWith "list of orders"

  describe "resetting orders", ->
    it "sets the value of $scope.orders to the data received", ->
      scope.resetOrders "list of orders"
      expect(scope.orders).toEqual "list of orders"