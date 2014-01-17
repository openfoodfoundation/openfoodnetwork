describe "AdminBulkOrdersCtrl", ->
  ctrl = scope = timeout = httpBackend = null

  beforeEach ->
    module "bulk_order_management"
  beforeEach inject(($controller, $rootScope, $httpBackend) ->
    scope = $rootScope.$new()
    ctrl = $controller
    httpBackend = $httpBackend

    ctrl "AdminBulkOrdersCtrl", {$scope: scope, $timeout: timeout}
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