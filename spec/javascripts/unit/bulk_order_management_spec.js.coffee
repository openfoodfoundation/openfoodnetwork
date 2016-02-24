describe "AdminOrderMgmtCtrl", ->
  ctrl = scope = httpBackend = VariantUnitManager = null

  beforeEach ->
    module "ofn.admin", ($provide) ->
      $provide.value 'SpreeApiKey', 'API_KEY'
      return
  beforeEach inject(($controller, $rootScope, $httpBackend, _VariantUnitManager_) ->
    scope = $rootScope.$new()
    ctrl = $controller
    httpBackend = $httpBackend
    VariantUnitManager = _VariantUnitManager_
    spyOn(window, "formatDate").andReturn "SomeDate"

    ctrl "AdminOrderMgmtCtrl", {$scope: scope}
  )

  describe "loading data upon initialisation", ->
    it "gets a list of suppliers, a list of distributors and a list of Order Cycles and then calls fetchOrders", ->
      returnedSuppliers = ["list of suppliers"]
      returnedDistributors = ["list of distributors"]
      returnedOrderCycles = [ "oc1", "oc2", "oc3" ]
      httpBackend.expectGET("/api/users/authorise_api?token=API_KEY").respond success: "Use of API Authorised"
      httpBackend.expectGET("/api/enterprises/accessible?template=bulk_index&q[is_primary_producer_eq]=true").respond returnedSuppliers
      httpBackend.expectGET("/api/enterprises/accessible?template=bulk_index&q[sells_in][]=own&q[sells_in][]=any").respond returnedDistributors
      httpBackend.expectGET("/api/order_cycles/accessible?as=distributor&q[orders_close_at_gt]=SomeDate").respond returnedOrderCycles
      spyOn(scope, "initialiseVariables").andCallThrough()
      spyOn(scope, "fetchOrders").andReturn "nothing"
      #spyOn(returnedSuppliers, "unshift")
      #spyOn(returnedDistributors, "unshift")
      #spyOn(returnedOrderCycles, "unshift")
      scope.initialise()
      httpBackend.flush()

      expect(scope.suppliers).toEqual [{ id : '0', name : 'All' }, 'list of suppliers']
      expect(scope.distributors).toEqual [ { id : '0', name : 'All' }, 'list of distributors' ]
      expect(scope.orderCycles).toEqual [ { id : '0', name : 'All' }, 'oc1', 'oc2', 'oc3' ]

      expect(scope.initialiseVariables.calls.length).toBe 1
      expect(scope.fetchOrders.calls.length).toBe 1
      expect(scope.spree_api_key_ok).toBe true

  describe "fetching orders", ->
    beforeEach ->
      scope.initialiseVariables()
      httpBackend.expectGET("/admin/orders/managed?template=bulk_index;page=1;per_page=500;q[state_not_eq]=canceled;q[completed_at_not_null]=true;q[completed_at_gt]=SomeDate;q[completed_at_lt]=SomeDate").respond "list of orders"

    it "makes a call to dataFetcher, with current start and end date parameters", ->
      scope.fetchOrders()

    it "calls resetOrders after data has been received", ->
      spyOn scope, "resetOrders"
      scope.fetchOrders()
      httpBackend.flush()
      expect(scope.resetOrders).toHaveBeenCalledWith "list of orders"

    it "sets the loading property to true before fetching orders and unsets it when loading is complete", ->
      spyOn scope, "resetOrders"
      scope.fetchOrders()
      expect(scope.loading).toEqual true
      httpBackend.flush()
      expect(scope.loading).toEqual false

  describe "resetting orders", ->
    beforeEach ->
      spyOn(scope, "matchObject").andReturn "nothing"
      spyOn(scope, "resetLineItems").andReturn "nothing"
      scope.resetOrders [ "order1", "order2", "order3" ]

    it "sets the value of $scope.orders to the data received", ->
      expect(scope.orders).toEqual [ "order1", "order2", "order3" ]

    it "makes a call to $scope.resetLineItems", ->
      expect(scope.resetLineItems).toHaveBeenCalled()

  describe "resetting line items", ->
    order1 = order2 = order3 = null

    beforeEach ->
      spyOn(scope, "matchObject").andReturn "nothing"
      spyOn(scope, "lineItemOrder").andReturn "copied order"
      order1 = { name: "order1", line_items: [ { name: "line_item1.1" }, { name: "line_item1.1" }, { name: "line_item1.1" } ] }
      order2 = { name: "order2", line_items: [ { name: "line_item2.1" }, { name: "line_item2.1" }, { name: "line_item2.1" } ] }
      order3 = { name: "order3", line_items: [ { name: "line_item3.1" }, { name: "line_item3.1" }, { name: "line_item3.1" } ] }
      scope.orders = [ order1, order2, order3 ]
      scope.resetLineItems()

    it "creates $scope.lineItems by flattening the line_items arrays in each order object", ->
      expect(scope.lineItems.length).toEqual 9
      expect(scope.lineItems[0].name).toEqual "line_item1.1"
      expect(scope.lineItems[3].name).toEqual "line_item2.1"
      expect(scope.lineItems[6].name).toEqual "line_item3.1"

    it "adds a reference to a modified parent order object to each line item", ->
      expect(scope.lineItemOrder.calls.length).toEqual scope.orders.length
      expect("copied order").toEqual line_item.order for line_item in scope.lineItems

    it "calls matchObject once for each line item", ->
      expect(scope.matchObject.calls.length).toEqual scope.lineItems.length

  describe "copying orders", ->
    order1copy = null

    beforeEach ->
      spyOn(scope, "lineItemOrder").andCallThrough()
      spyOn(scope, "matchObject").andReturn "matched object"
      order1 = { name: "order1", line_items: [  ] }
      scope.orders = [ order1 ]
      order1copy = scope.lineItemOrder order1

    it "calls removes the line_items attribute of the order, in order to avoid circular referencing)", ->
      expect(order1copy.hasOwnProperty("line_items")).toEqual false

    it "calls matchObject twice for each order (once for distributor and once for order cycle)", ->
      expect(scope.matchObject.calls.length).toEqual scope.lineItemOrder.calls.length * 2
      expect(order1copy.distributor).toEqual "matched object"
      expect(order1copy.distributor).toEqual "matched object"

  describe "matching objects", ->
    it "returns the first matching object in the list", ->
      list_item1 =
        id: 1
        name: "LI1"

      list_item2 =
        id: 2
        name: "LI2"

      test_item =
        id: 2
        name: "LI2"

      expect(list_item2 is test_item).not.toEqual true
      list = [
        list_item1
        list_item2
      ]

      returned_item = scope.matchObject list, test_item, null
      expect(returned_item is list_item2).toEqual true

    it "returns the default provided if no matching item is found", ->
      list_item1 =
        id: 1
        name: "LI1"

      list_item2 =
        id: 2
        name: "LI2"

      test_item =
        id: 1
        name: "LI2"

      expect(list_item2 is test_item).not.toEqual true
      list = [
        list_item1
        list_item2
      ]

      returned_item = scope.matchObject list, test_item, null
      expect(returned_item is null).toEqual true

  describe "deleting a line item", ->
    order = line_item1 = line_item2 = null

    beforeEach ->
      scope.initialiseVariables()
      spyOn(window,"confirm").andReturn true
      order = { number: "R12345678", line_items: [] }
      line_item1 = { id: 1, order: order }
      line_item2 = { id: 2, order: order }
      order.line_items = [ line_item1, line_item2 ]

    it "sends a delete request via the API", ->
      httpBackend.expectDELETE("/api/orders/#{line_item1.order.number}/line_items/#{line_item1.id}").respond "nothing"
      scope.deleteLineItem line_item1
      httpBackend.flush()

    it "does not remove line_item from the line_items array when request is not successful", ->
      httpBackend.expectDELETE("/api/orders/#{line_item1.order.number}/line_items/#{line_item1.id}").respond 404, "NO CONTENT"
      scope.deleteLineItem line_item1
      httpBackend.flush()
      expect(order.line_items).toEqual [line_item1, line_item2]

  describe "deleting 'checked' line items", ->
    line_item1 = line_item2 = line_item3 = line_item4 = null

    beforeEach ->
      line_item1 = { name: "line item 1", checked: false }
      line_item2 = { name: "line item 2", checked: true }
      line_item3 = { name: "line item 3", checked: false }
      line_item4 = { name: "line item 4", checked: true }
      scope.lineItems = [ line_item1, line_item2, line_item3, line_item4 ]

    it "calls deletedLineItem for each 'checked' line item", ->
      spyOn(scope, "deleteLineItem")
      scope.deleteLineItems(scope.lineItems)
      expect(scope.deleteLineItem).toHaveBeenCalledWith(line_item2)
      expect(scope.deleteLineItem).toHaveBeenCalledWith(line_item4)
      expect(scope.deleteLineItem).not.toHaveBeenCalledWith(line_item1)
      expect(scope.deleteLineItem).not.toHaveBeenCalledWith(line_item3)

  describe "check boxes for line items", ->
    line_item1 = line_item2 = null

    beforeEach ->
      line_item1 = { name: "line item 1", checked: false }
      line_item2 = { name: "line item 2", checked: false }
      scope.filteredLineItems = [ line_item1, line_item2 ]

    it "keeps track of whether all filtered lines items are 'checked' or not", ->
      expect(scope.allBoxesChecked()).toEqual false
      line_item1.checked = true
      expect(scope.allBoxesChecked()).toEqual false
      line_item2.checked = true
      expect(scope.allBoxesChecked()).toEqual true
      line_item1.checked = false
      expect(scope.allBoxesChecked()).toEqual false

    it "toggles the 'checked' attribute of all line items based to the value of allBoxesChecked", ->
      scope.toggleAllCheckboxes()
      expect(scope.allBoxesChecked()).toEqual true
      line_item1.checked = false
      expect(scope.allBoxesChecked()).toEqual false
      scope.toggleAllCheckboxes()
      expect(scope.allBoxesChecked()).toEqual true
      scope.toggleAllCheckboxes()
      expect(scope.allBoxesChecked()).toEqual false

  describe "unit calculations", ->
    beforeEach ->
      scope.initialiseVariables()

    describe "fulfilled()", ->
      it "returns '' if selectedUnitsVariant has no property 'variant_unit'", ->
        expect(scope.fulfilled()).toEqual ''

      it "returns '' if selectedUnitsVariant has no property 'group_buy_unit_size' or group_buy_unit_size is 0", ->
        scope.selectedUnitsProduct = { variant_unit: "weight", group_buy_unit_size: 0 }
        expect(scope.fulfilled()).toEqual ''
        scope.selectedUnitsProduct = { variant_unit: "weight" }
        expect(scope.fulfilled()).toEqual ''

      it "returns '', and does not call Math.round if variant_unit is 'items'", ->
        spyOn(Math,"round")
        scope.selectedUnitsProduct = { variant_unit: "items", group_buy_unit_size: 10 }
        expect(scope.fulfilled()).toEqual ''
        expect(Math.round).not.toHaveBeenCalled()

      it "calls Math.round() if variant_unit is 'weight' or 'volume'", ->
        spyOn(Math,"round")
        scope.selectedUnitsProduct = { variant_unit: "weight", group_buy_unit_size: 10 }
        scope.fulfilled()
        expect(Math.round).toHaveBeenCalled()
        scope.selectedUnitsProduct = { variant_unit: "volume", group_buy_unit_size: 10 }
        scope.fulfilled()
        expect(Math.round).toHaveBeenCalled()

      it "returns the quantity of fulfilled group buy units", ->
        scope.selectedUnitsProduct = { variant_unit: "weight", group_buy_unit_size: 1000 }
        expect(scope.fulfilled(1500)).toEqual 1.5

    describe "allFinalWeightVolumesPresent()", ->
      it "returns false if the unit_value of any item in filteredLineItems does not exist", ->
        scope.filteredLineItems = [
          { final_weight_volume: 1000 }
          { final_weight_volume: 3000 }
          { final_weight_yayaya: 2000 }
        ]
        expect(scope.allFinalWeightVolumesPresent()).toEqual false

      it "returns false if the unit_value of any item in filteredLineItems is not a number greater than 0", ->
        scope.filteredLineItems = [
          { final_weight_volume: 0 }
          { final_weight_volume: 3000 }
          { final_weight_volume: 2000 }
        ]
        expect(scope.allFinalWeightVolumesPresent()).toEqual false
        scope.filteredLineItems = [
          { final_weight_volume: 'lalala' }
          { final_weight_volume: 3000 }
          { final_weight_volume: 2000 }
        ]
        expect(scope.allFinalWeightVolumesPresent()).toEqual false

      it "returns true if the unit_value of all items in filteredLineItems are numbers greater than 0", ->
        scope.filteredLineItems = [
          { final_weight_volume: 1000 }
          { final_weight_volume: 3000 }
          { final_weight_volume: 2000 }
        ]
        expect(scope.allFinalWeightVolumesPresent()).toEqual true

    describe "sumUnitValues()", ->
      it "returns the sum of the final_weight_volumes line_items", ->
        scope.filteredLineItems = [
          { final_weight_volume: 2 }
          { final_weight_volume: 7 }
          { final_weight_volume: 21 }
        ]
        expect(scope.sumUnitValues()).toEqual 30

    describe "sumMaxUnitValues()", ->
      it "returns the sum of the product of unit_value and maxOf(max_quantity,quantity) for specified line_items", ->
        scope.filteredLineItems = [
          { units_variant: { unit_value: 1 }, original_quantity: 2, max_quantity: 5 }
          { units_variant: { unit_value: 2 }, original_quantity: 3, max_quantity: 1 }
          { units_variant: { unit_value: 3 }, original_quantity: 7, max_quantity: 10 }
        ]
        sp0 = scope.filteredLineItems[0].units_variant.unit_value * Math.max(scope.filteredLineItems[0].original_quantity, scope.filteredLineItems[0].max_quantity)
        sp1 = scope.filteredLineItems[1].units_variant.unit_value * Math.max(scope.filteredLineItems[1].original_quantity, scope.filteredLineItems[1].max_quantity)
        sp2 = scope.filteredLineItems[2].units_variant.unit_value * Math.max(scope.filteredLineItems[2].original_quantity, scope.filteredLineItems[2].max_quantity)
        expect(scope.sumMaxUnitValues()).toEqual (sp0 + sp1 + sp2)

    describe "formatting a value based upon the properties of a specified Units Variant", ->
      # A Units Variant is an API object which holds unit properies of a variant

      beforeEach ->
        spyOn(Math,"round").andCallThrough()

      it "returns '' if selectedUnitsVariant has no property 'variant_unit'", ->
        expect(scope.formattedValueWithUnitName(1,{})).toEqual ''

      it "returns '', and does not call Math.round if variant_unit is 'items'", ->
        unitsVariant = { variant_unit: "items" }
        expect(scope.formattedValueWithUnitName(1,unitsVariant)).toEqual ''
        expect(Math.round).not.toHaveBeenCalled()

      it "calls Math.round() if variant_unit is 'weight' or 'volume'", ->
        unitsVariant = { variant_unit: "weight" }
        scope.formattedValueWithUnitName(1,unitsVariant)
        expect(Math.round).toHaveBeenCalled()
        scope.selectedUnitsVariant = { variant_unit: "volume" }
        scope.formattedValueWithUnitName(1,unitsVariant)
        expect(Math.round).toHaveBeenCalled()

      it "calls Math.round with the quotient of scale and value, multiplied by 1000", ->
        unitsVariant = { variant_unit: "weight" }
        spyOn(VariantUnitManager, "getScale").andReturn 5
        scope.formattedValueWithUnitName(10, unitsVariant)
        expect(Math.round).toHaveBeenCalledWith 10/5 * 1000

      it "returns the result of Math.round divided by 1000, followed by the result of getUnitName", ->
        unitsVariant = { variant_unit: "weight" }
        spyOn(VariantUnitManager, "getScale").andReturn 1000
        spyOn(VariantUnitManager, "getUnitName").andReturn "kg"
        expect(scope.formattedValueWithUnitName(2000,unitsVariant)).toEqual "2 kg"

    describe "updating the price upon updating the weight of a line item", ->
      it "updates the price if the weight is changed", ->
        scope.filteredLineItems = [
          { original_price: 2.00, price: 2.00, original_quantity: 1, quantity: 1, original_final_weight_volume: 2000, final_weight_volume: 4000  }
        ]
        scope.weightAdjustedPrice(scope.filteredLineItems[0])
        expect(scope.filteredLineItems[0].price).toEqual 4.00

      it "doesn't update the price if the weight <= 0", ->
        scope.filteredLineItems = [
          { original_price: 2.00, price: 2.00, original_quantity: 1, quantity: 1, original_final_weight_volume: 2000, final_weight_volume: 0  }
        ]
        scope.weightAdjustedPrice(scope.filteredLineItems[0])
        expect(scope.filteredLineItems[0].price).toEqual 2.00

      it "doesn't update the price if the weight is an empty string", ->
        scope.filteredLineItems = [
          { original_price: 2.00, price: 2.00, original_quantity: 1, quantity: 1, original_final_weight_volume: 2000, final_weight_volume: ""  }
        ]
        scope.weightAdjustedPrice(scope.filteredLineItems[0])
        expect(scope.filteredLineItems[0].price).toEqual 2.00

    describe "updating final_weight_volume upon updating the quantity for a line_item", ->
      beforeEach ->
        spyOn(scope, "weightAdjustedPrice")

      it "updates the weight if the quantity is changed, then calls weightAdjustedPrice()", ->
        scope.filteredLineItems = [
          { original_price: 2.00, price: 2.00, original_quantity: 1, quantity: 2, original_final_weight_volume: 2000, final_weight_volume: 0  }
        ]
        scope.updateOnQuantity(scope.filteredLineItems[0])
        expect(scope.filteredLineItems[0].final_weight_volume).toEqual 4000
        expect(scope.weightAdjustedPrice).toHaveBeenCalled()

      it "doesn't update the weight if the quantity <= 0", ->
        scope.filteredLineItems = [
          { original_price: 2.00, price: 2.00, original_quantity: 1, quantity: 0, original_final_weight_volume: 2000, final_weight_volume: 1000  }
        ]
        scope.updateOnQuantity(scope.filteredLineItems[0])
        expect(scope.filteredLineItems[0].final_weight_volume).toEqual 1000

      it "doesn't update the weight if the quantity is an empty string", ->
        scope.filteredLineItems = [
          { original_price: 2.00, price: 2.00, original_quantity: 1, quantity: "", original_final_weight_volume: 2000, final_weight_volume: 1000  }
        ]
        scope.updateOnQuantity(scope.filteredLineItems[0])
        expect(scope.filteredLineItems[0].final_weight_volume).toEqual 1000


describe "Auxiliary functions", ->
  describe "getting a zero filled two digit number", ->
    it "returns the number as a string if its value is greater than or equal to 10", ->
      expect(twoDigitNumber(10)).toEqual "10"
      expect(twoDigitNumber(15)).toEqual "15"
      expect(twoDigitNumber(99)).toEqual "99"

    it "returns the number formatted as a zero filled string if its value is less than 10", ->
      expect(twoDigitNumber(0)).toEqual "00"
      expect(twoDigitNumber(1)).toEqual "01"
      expect(twoDigitNumber(9)).toEqual "09"

  describe "formatting dates and times", ->
    date = null

    beforeEach ->
      date = new Date
      date.setYear(2010)
      date.setMonth(4) # Zero indexed, so 4 is May
      date.setDate(15)
      date.setHours(5)
      date.setMinutes(10)
      date.setSeconds(30)

    it "returns a date formatted as yyyy-mm-dd", ->
      expect(formatDate(date)).toEqual "2010-05-15"

    it "returns a time formatted as hh-MM:ss", ->
      expect(formatTime(date)).toEqual "05:10:30"
