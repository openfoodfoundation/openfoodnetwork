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

describe "managing pending changes", ->
  dataSubmitter = pendingChangesService = null

  beforeEach ->
    dataSubmitter = jasmine.createSpy('dataSubmitter').andReturn {
      then: (thenFn) ->
        thenFn({propertyName: "new_value"})
    }

  beforeEach ->
    module "ofn.bulk_order_management", ($provide) ->
      $provide.value 'dataSubmitter', dataSubmitter
      return

  beforeEach inject (pendingChanges) ->
    pendingChangesService = pendingChanges

  describe "adding a new change", ->
    it "adds a new object with key of id if it does not already exist", ->
      expect(pendingChangesService.pendingChanges).toEqual {}
      expect(pendingChangesService.pendingChanges["1"]).not.toBeDefined()
      pendingChangesService.add 1, "propertyName", { a: 1 }
      expect(pendingChangesService.pendingChanges["1"]).toBeDefined()

    it "adds a new object with key of the altered attribute name if it does not already exist", ->
      pendingChangesService.add 1, "propertyName", { a: 1 }
      expect(pendingChangesService.pendingChanges["1"]).toBeDefined()
      expect(pendingChangesService.pendingChanges["1"]["propertyName"]).toEqual { a: 1 }

    it "replaces the existing object when adding a change to an attribute which already exists", ->
      pendingChangesService.add 1, "propertyName", { a: 1 }
      expect(pendingChangesService.pendingChanges["1"]).toBeDefined()
      expect(pendingChangesService.pendingChanges["1"]["propertyName"]).toEqual { a: 1 }
      pendingChangesService.add 1, "propertyName", { b: 2 }
      expect(pendingChangesService.pendingChanges["1"]["propertyName"]).toEqual { b: 2 }

   it "adds an attribute to key to a line item object when one already exists", ->
      pendingChangesService.add 1, "propertyName1", { a: 1 }
      pendingChangesService.add 1, "propertyName2", { b: 2 }
      expect(pendingChangesService.pendingChanges["1"]).toEqual { propertyName1: { a: 1}, propertyName2: { b: 2 } }

  describe "removing an existing change", ->
    it "deletes a change if it exists", ->
      pendingChangesService.pendingChanges = { 1: { "propertyName1": { a: 1 }, "propertyName2": { b: 2 } } }
      expect(pendingChangesService.pendingChanges["1"]["propertyName1"]).toBeDefined()
      pendingChangesService.remove 1, "propertyName1"
      expect(pendingChangesService.pendingChanges["1"]).toBeDefined()
      expect(pendingChangesService.pendingChanges["1"]["propertyName1"]).not.toBeDefined()

    it "deletes a line item object if it is empty", ->
      pendingChangesService.pendingChanges = { 1: { "propertyName1": { a: 1 } } }
      expect(pendingChangesService.pendingChanges["1"]["propertyName1"]).toBeDefined()
      pendingChangesService.remove 1, "propertyName1"
      expect(pendingChangesService.pendingChanges["1"]).not.toBeDefined()

    it "does nothing if key with specified attribute does not exist", ->
      pendingChangesService.pendingChanges = { 1: { "propertyName1": { a: 1 } } }
      expect(pendingChangesService.pendingChanges["1"]["propertyName1"]).toBeDefined()
      pendingChangesService.remove 1, "propertyName2"
      expect(pendingChangesService.pendingChanges["1"]["propertyName1"]).toEqual { a: 1 }

    it "does nothing if key with specified id does not exist", ->
      pendingChangesService.pendingChanges = { 1: { "propertyName1": { a: 1 } } }
      expect(pendingChangesService.pendingChanges["1"]["propertyName1"]).toBeDefined()
      pendingChangesService.remove 2, "propertyName1"
      expect(pendingChangesService.pendingChanges["1"]).toEqual { "propertyName1": { a: 1 } }

  describe "submitting an individual change to the server", ->
    it "sends the correct object to dataSubmitter", ->
      changeObj = { element: {} }
      pendingChangesService.submit 1, "propertyName", changeObj
      expect(dataSubmitter.calls.length).toEqual 1
      expect(dataSubmitter).toHaveBeenCalledWith changeObj

    it "calls remove with id and attribute name", ->
      changeObj = { element: {} }
      spyOn(pendingChangesService, "remove").andCallFake(->)
      pendingChangesService.submit 1, "propertyName", changeObj
      expect(pendingChangesService.remove.calls.length).toEqual 1
      expect(pendingChangesService.remove).toHaveBeenCalledWith 1, "propertyName"

    it "resets the dbValue attribute of the element in question", ->
      element = { dbValue: 2 }
      changeObj = { element: element }
      pendingChangesService.submit 1, "propertyName", changeObj
      expect(element.dbValue).toEqual "new_value"

  describe "cycling through all changes to submit to server", ->
    it "sends the correct object to dataSubmitter", ->
      spyOn(pendingChangesService, "submit").andCallFake(->)
      pendingChangesService.pendingChanges =
        1: { "prop1": 1, "prop2": 2 }
        2: { "prop1": 2, "prop2": 4 }
        7: { "prop2": 5 }
      pendingChangesService.submitAll()
      expect(pendingChangesService.submit.calls.length).toEqual 5
      expect(pendingChangesService.submit).toHaveBeenCalledWith '1', "prop1", 1
      expect(pendingChangesService.submit).toHaveBeenCalledWith '1', "prop2", 2
      expect(pendingChangesService.submit).toHaveBeenCalledWith '2', "prop1", 2
      expect(pendingChangesService.submit).toHaveBeenCalledWith '2', "prop2", 4
      expect(pendingChangesService.submit).toHaveBeenCalledWith '7', "prop2", 5

describe "dataSubmitter service", ->
  qMock = httpMock = {}
  resolve = reject = dataSubmitterService = null

  beforeEach ->
    resolve = jasmine.createSpy('resolve')
    reject = jasmine.createSpy('reject')
    qMock.defer = ->
      resolve: resolve
      reject: reject
      promise: "promise1"

    # Can't use httpBackend because the qMock interferes with it
    httpMock.put = (url) ->
      success: (successFn) ->
        successFn("somedata") if url == "successURL"
        error: (errorFn) ->
          errorFn() if url == "errorURL"

    spyOn(httpMock, "put").andCallThrough()
    spyOn(qMock, "defer").andCallThrough()

  beforeEach ->
    module "ofn.bulk_order_management" , ($provide) ->
      $provide.value '$q', qMock
      $provide.value '$http', httpMock
      return

  beforeEach inject (dataSubmitter) ->
    dataSubmitterService = dataSubmitter

  it "returns a promise", ->
    expect(dataSubmitterService( { url: "successURL" } )).toEqual "promise1"
    expect(qMock.defer).toHaveBeenCalled()

  it "sends a PUT request with the url property of changeObj", ->
    dataSubmitterService { url: "successURL" }
    expect(httpMock.put).toHaveBeenCalledWith "successURL"

  it "calls resolve on deferred object when request is successful", ->
    dataSubmitterService { url: "successURL" }
    expect(resolve.calls.length).toEqual 1
    expect(reject.calls.length).toEqual 0
    expect(resolve).toHaveBeenCalledWith "somedata"

  it "calls reject on deferred object when request is erroneous", ->
    dataSubmitterService { url: "errorURL" }
    expect(resolve.calls.length).toEqual 0
    expect(reject.calls.length).toEqual 1

describe "switchClass service", ->
  elementMock = timeoutMock = {}
  removeClass = addClass = switchClassService = null

  beforeEach ->
    addClass = jasmine.createSpy('addClass')
    removeClass = jasmine.createSpy('removeClass')
    elementMock =
      addClass: addClass
      removeClass: removeClass
    timeoutMock = jasmine.createSpy('timeout').andReturn "new timeout"
    timeoutMock.cancel = jasmine.createSpy('timeout.cancel')

  beforeEach ->
    module "ofn.bulk_order_management" , ($provide) ->
      $provide.value '$timeout', timeoutMock
      return

  beforeEach inject (switchClass) ->
    switchClassService = switchClass

  it "calls addClass on the element once", ->
    switchClassService elementMock, "addClass", [], false
    expect(addClass).toHaveBeenCalledWith "addClass"
    expect(addClass.calls.length).toEqual 1

  it "calls removeClass on the element for ", ->
    switchClassService elementMock, "", ["remClass1", "remClass2", "remClass3"], false
    expect(removeClass).toHaveBeenCalledWith "remClass1"
    expect(removeClass).toHaveBeenCalledWith "remClass2"
    expect(removeClass).toHaveBeenCalledWith "remClass3"
    expect(removeClass.calls.length).toEqual 3

  it "call cancel on element.timout only if it exists", ->
    switchClassService elementMock, "", [], false
    expect(timeoutMock.cancel).not.toHaveBeenCalled()
    elementMock.timeout = true
    switchClassService elementMock, "", [], false
    expect(timeoutMock.cancel).toHaveBeenCalled()

  it "doesn't set up a new timeout if 'timeout' is false", ->
    switchClassService elementMock, "class1", ["class2"], false
    expect(timeoutMock).not.toHaveBeenCalled()

  it "doesn't set up a new timeout if 'timeout' is a string", ->
    switchClassService elementMock, "class1", ["class2"], "string"
    expect(timeoutMock).not.toHaveBeenCalled()

  it "sets up a new timeout if 'timeout' parameter is an integer", ->
    switchClassService elementMock, "class1", ["class2"], 1000
    expect(timeoutMock).toHaveBeenCalled()
    expect(elementMock.timeout).toEqual "new timeout"