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
    beforeEach ->
      httpBackend.expectGET("/api/orders?template=bulk_index").respond "list of orders"

    it "makes a standard call to dataFetcher", ->
      scope.fetchOrders()

    it "calls resetOrders after data has been received", ->
      spyOn scope, "resetOrders"
      scope.fetchOrders()
      httpBackend.flush()
      expect(scope.resetOrders).toHaveBeenCalledWith "list of orders"

  describe "resetting orders", ->
    it "sets the value of $scope.orders to the data received", ->
      scope.resetOrders "list of orders"
      expect(scope.orders).toEqual "list of orders"

    it "makes a call to $scope.resetLineItems", ->
      spyOn scope, "resetLineItems"
      scope.resetOrders "list of orders"
      expect(scope.resetLineItems).toHaveBeenCalled()

  describe "resetting line items", ->
    order1 = order2 = order3 = null

    beforeEach ->
      order1 = { line_items: [ { name: "line_item1.1" }, { name: "line_item1.1" }, { name: "line_item1.1" } ] }
      order2 = { line_items: [ { name: "line_item2.1" }, { name: "line_item2.1" }, { name: "line_item2.1" } ] }
      order3 = { line_items: [ { name: "line_item3.1" }, { name: "line_item3.1" }, { name: "line_item3.1" } ] }
      scope.orders = [ order1, order2, order3 ]
      scope.resetLineItems()

    it "creates $scope.lineItems by flattening the line_items arrays in each order object", ->
      expect(scope.lineItems.length).toEqual 9
      expect(scope.lineItems[0].name).toEqual "line_item1.1"
      expect(scope.lineItems[3].name).toEqual "line_item2.1"
      expect(scope.lineItems[6].name).toEqual "line_item3.1"

    it "adds a reference to the parent order to each line item", ->
      expect(scope.lineItems[0].order).toEqual order1
      expect(scope.lineItems[3].order).toEqual order2
      expect(scope.lineItems[6].order).toEqual order3