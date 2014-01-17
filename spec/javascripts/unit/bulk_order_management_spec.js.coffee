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
    beforeEach ->
      spyOn(scope, "resetLineItems").andReturn "nothing"
      scope.resetOrders "list of orders"

    it "sets the value of $scope.orders to the data received", ->
      expect(scope.orders).toEqual "list of orders"

    it "makes a call to $scope.resetLineItems", ->
      expect(scope.resetLineItems).toHaveBeenCalled()

  describe "resetting line items", ->
    order1 = order2 = order3 = null

    beforeEach ->
      spyOn(scope, "matchSupplier").andReturn "nothing"
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

    it "calls matchSupplier for each line item", ->
      expect(scope.matchSupplier.calls.length).toEqual 9

  describe "matching supplier", ->
    it "changes the supplier of the line_item to the one which matches it from the suppliers list", ->
      s1_s =
        id: 1
        name: "S1"

      s2_s =
        id: 2
        name: "S2"

      s1_l =
        id: 1
        name: "S1"

      expect(s1_s is s1_l).not.toEqual true
      scope.suppliers = [
        s1_s
        s2_s
      ]
      line_item =
        id: 10
        supplier: s1_l

      scope.matchSupplier line_item
      expect(line_item.supplier is s1_s).toEqual true