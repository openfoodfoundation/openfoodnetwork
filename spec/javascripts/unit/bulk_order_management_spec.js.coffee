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
    it "gets a list of suppliers and a list of distributors and then calls fetchOrders", ->
      returnedSuppliers = ["list of suppliers"]
      returnedDistributors = ["list of distributors"]
      httpBackend.expectGET("/api/users/authorise_api?token=api_key").respond success: "Use of API Authorised"
      httpBackend.expectGET("/api/enterprises/managed?template=bulk_index&q[is_primary_producer_eq]=true").respond returnedSuppliers
      httpBackend.expectGET("/api/enterprises/managed?template=bulk_index&q[is_distributor_eq]=true").respond returnedDistributors
      spyOn(scope, "fetchOrders").andReturn "nothing"
      spyOn(returnedSuppliers, "unshift")
      spyOn(returnedDistributors, "unshift")
      scope.initialise "api_key"
      httpBackend.flush()
      expect(scope.suppliers).toEqual ["list of suppliers"]
      expect(scope.distributors).toEqual ["list of distributors"]
      expect(scope.fetchOrders.calls.length).toEqual 1
      expect(returnedSuppliers.unshift.calls.length).toEqual 1
      expect(returnedDistributors.unshift.calls.length).toEqual 1
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
      spyOn(scope, "matchDistributor").andReturn "nothing"
      spyOn(scope, "resetLineItems").andReturn "nothing"
      scope.resetOrders [ "order1", "order2", "order3" ]

    it "sets the value of $scope.orders to the data received", ->
      expect(scope.orders).toEqual [ "order1", "order2", "order3" ]

    it "makes a call to $scope.resetLineItems", ->
      expect(scope.resetLineItems).toHaveBeenCalled()

    it "calls matchDistributor for each line item", ->
      expect(scope.matchDistributor.calls.length).toEqual 3

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
      supplier1_list =
        id: 1
        name: "S1"

      supplier2_list =
        id: 2
        name: "S2"

      supplier1_line_item =
        id: 1
        name: "S1"

      expect(supplier1_list is supplier1_line_item).not.toEqual true
      scope.suppliers = [
        supplier1_list
        supplier2_list
      ]
      line_item =
        id: 10
        supplier: supplier1_line_item

      scope.matchSupplier line_item
      expect(line_item.supplier is supplier1_list).toEqual true

  describe "matching distributor", ->
    it "changes the distributor of the order to the one which matches it from the distributors list", ->
      distributor1_list =
        id: 1
        name: "D1"

      distributor2_list =
        id: 2
        name: "D2"

      distributor1_order =
        id: 1
        name: "D1"

      expect(distributor1_list is distributor1_order).not.toEqual true
      scope.distributors = [
        distributor1_list
        distributor2_list
      ]
      order =
        id: 10
        distributor: distributor1_order

      scope.matchDistributor order
      expect(order.distributor is distributor1_list).toEqual true

  describe "deleting a line item", ->
    order = line_item1 = line_item2 = null
    beforeEach ->
      spyOn(window,"confirm").andReturn true
      order = { number: "R12345678", line_items: [] }
      line_item1 = { id: 1, order: order }
      line_item2 = { id: 2, order: order }
      order.line_items = [ line_item1, line_item2 ]

    it "sends a delete request via the API", ->
      httpBackend.expectDELETE("/api/orders/#{line_item1.order.number}/line_items/#{line_item1.id}").respond "nothing"
      scope.deleteLineItem line_item1
      httpBackend.flush()

    it "removes line_item from the line_items array of the relevant order object when request is 204", ->
      httpBackend.expectDELETE("/api/orders/#{line_item1.order.number}/line_items/#{line_item1.id}").respond 204, "NO CONTENT"
      scope.deleteLineItem line_item1
      httpBackend.flush()
      expect(order.line_items).toEqual [line_item2]

    it "does not remove line_item from the line_items array when request is not successful", ->
      httpBackend.expectDELETE("/api/orders/#{line_item1.order.number}/line_items/#{line_item1.id}").respond 404, "NO CONTENT"
      scope.deleteLineItem line_item1
      httpBackend.flush()
      expect(order.line_items).toEqual [line_item1, line_item2]