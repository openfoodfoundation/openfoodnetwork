describe "LineItemsCtrl", ->
  ctrl = scope = httpBackend = $timeout = VariantUnitManager = Enterprises = Orders = LineItems = OrderCycles = null
  supplier = distributor = orderCycle = null

  beforeEach ->
    module "admin.lineItems"
    module ($provide) ->
      $provide.value 'columns', []
      null

    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

  beforeEach inject(($controller, $rootScope, $httpBackend, _$timeout_, _VariantUnitManager_, _Enterprises_, _Orders_, _LineItems_, _OrderCycles_) ->
    scope = $rootScope.$new()
    ctrl = $controller
    $timeout = _$timeout_
    httpBackend = $httpBackend
    Enterprises = _Enterprises_
    Orders = _Orders_
    LineItems = _LineItems_
    OrderCycles = _OrderCycles_
    VariantUnitManager = _VariantUnitManager_
    spyOn(window, "daysFromToday").and.returnValue "SomeDate"
    spyOn(window, "formatDate").and.returnValue "SomeDate"
    spyOn(window, "parseDate").and.returnValue "SomeDate"

    supplier = { id: 1, name: "Supplier" }
    distributor = { id: 5, name: "Distributor" }
    orderCycle = { id: 4, name: "OC1" }
    order = { id: 9, order_cycle: { id: 4 }, distributor: { id: 5 }, number: "R123456" }
    lineItem = { id: 7, quantity: 3, order: { id: 9 }, supplier: { id: 1 } }

    httpBackend.expectGET("/admin/orders.json?q%5Bcompleted_at_gt%5D=SomeDate&q%5Bcompleted_at_lt%5D=SomeDate&q%5Bcompleted_at_not_null%5D=true&q%5Bstate_not_eq%5D=canceled").respond [order]
    httpBackend.expectGET("/admin/bulk_line_items.json?q%5Border%5D%5Bcompleted_at_gt%5D=SomeDate&q%5Border%5D%5Bcompleted_at_lt%5D=SomeDate&q%5Border%5D%5Bcompleted_at_not_null%5D=true&q%5Border%5D%5Bstate_not_eq%5D=canceled").respond [lineItem]
    httpBackend.expectGET("/admin/enterprises/visible.json?ams_prefix=basic&q%5Bsells_in%5D%5B%5D=own&q%5Bsells_in%5D%5B%5D=any").respond [distributor]
    httpBackend.expectGET("/admin/order_cycles.json?ams_prefix=basic&as=distributor&q%5Borders_close_at_gt%5D=SomeDate").respond [orderCycle]
    httpBackend.expectGET("/admin/enterprises/visible.json?ams_prefix=basic&q%5Bis_primary_producer_eq%5D=true").respond [supplier]

    scope.bulk_order_form = jasmine.createSpyObj('bulk_order_form', ['$setPristine'])

    ctrl "LineItemsCtrl", {$scope: scope, $timeout: $timeout, Enterprises: Enterprises, Orders: Orders, LineItems: LineItems, OrderCycles: OrderCycles}
  )

  describe "before data is returned", ->
    it "the RequestMonitor will have a state of loading", ->
      expect(scope.RequestMonitor.loading).toBe true

    it "will not have reset the select filters", ->
      expect(scope.distributorFilter).toBeUndefined()
      expect(scope.supplierFilter).toBeUndefined()
      expect(scope.orderCycleFilter).toBeUndefined()
      expect(scope.quickSearch).toBeUndefined()

    it "will not have reset the form state to pristine", ->
      expect(scope.bulk_order_form.$setPristine.calls.count()).toBe 0

  describe "after data is returned", ->
    beforeEach ->
      httpBackend.flush()
      $timeout.flush()

    describe "initialisation", ->
      it "gets suppliers", ->
        expect(scope.suppliers).toDeepEqual [supplier ]

      it "gets distributors", ->
        expect(scope.distributors).toDeepEqual [ distributor ]

      it "stores enterprises in an list that is accessible by id", ->
        expect(Enterprises.byID[1]).toDeepEqual supplier

      it "gets order cycles", ->
        expect(scope.orderCycles).toDeepEqual [ orderCycle ]

      it "gets orders, with dereferenced order cycles and distributors", ->
        expect(scope.orders).toDeepEqual [ { id: 9, order_cycle: orderCycle, distributor: distributor, number: "R123456" } ]

      it "gets line_items, with dereferenced orders and suppliers", ->
        expect(scope.lineItems).toDeepEqual [ { id: 7, quantity: 3, order: scope.orders[0], supplier: supplier } ]

      it "the RequestMonitor will have a state of loaded", ->
        expect(scope.RequestMonitor.loading).toBe false

      it "resets the select filters", ->
        expect(scope.distributorFilter).toBe 0
        expect(scope.supplierFilter).toBe 0
        expect(scope.orderCycleFilter).toBe 0
        expect(scope.quickSearch).toBe = ""

      it "resets the form state to pristine", ->
        expect(scope.bulk_order_form.$setPristine.calls.count()).toBe 1

    describe "deleting a line item", ->
      order = line_item1 = line_item2 = null

      beforeEach inject((LineItemResource) ->
        spyOn(window,"confirm").and.returnValue true
        order = { number: "R12345678" }
        line_item1 = new LineItemResource({ id: 1, order: order })
        line_item2 = new LineItemResource({ id: 2, order: order })
        scope.lineItems= [ line_item1, line_item2 ]
      )

      describe "where the request is successful", ->
        beforeEach ->
          httpBackend.expectDELETE("/admin/bulk_line_items/1.json").respond "nothing"
          scope.deleteLineItem line_item1
          httpBackend.flush()

        it "removes the deleted item from the line_items array", ->
          expect(scope.lineItems).toEqual [line_item2]

      describe "where the request is unsuccessful", ->
        beforeEach ->
          httpBackend.expectDELETE("/admin/bulk_line_items/1.json").respond 404, "NO CONTENT"
          scope.deleteLineItem line_item1
          httpBackend.flush()

        it "does not remove line_item from the line_items array", ->
          expect(scope.lineItems).toEqual [line_item1, line_item2]

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
        it "returns the sum of the product of unit_value and maxOf(max_quantity, pristine quantity) for specified line_items", ->
          scope.filteredLineItems = [
            { id: 1, units_variant: { unit_value: 1 }, max_quantity: 5 }
            { id: 2, units_variant: { unit_value: 2 }, max_quantity: 1 }
            { id: 3, units_variant: { unit_value: 3 }, max_quantity: 10 }
          ]

          expect(scope.sumMaxUnitValues()).toEqual 37

      describe "formatting a value based upon the properties of a specified Units Variant", ->
        # A Units Variant is an API object which holds unit properies of a variant

        beforeEach ->
          spyOn(Math,"round").and.callThrough()

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
          spyOn(VariantUnitManager, "getScale").and.returnValue 5
          scope.formattedValueWithUnitName(10, unitsVariant)
          expect(Math.round).toHaveBeenCalledWith 10/5 * 1000

        it "returns the result of Math.round divided by 1000, followed by the result of getUnitName", ->
          unitsVariant = { variant_unit: "weight" }
          spyOn(VariantUnitManager, "getScale").and.returnValue 1000
          spyOn(VariantUnitManager, "getUnitName").and.returnValue "kg"
          expect(scope.formattedValueWithUnitName(2000,unitsVariant)).toEqual "2 kg"

      describe "updating the price upon updating the weight of a line item", ->
        beforeEach ->
          LineItems.pristineByID = { 1: { price: 2.00, quantity: 1, final_weight_volume: 2000 } }

        it "updates the price if the weight is changed", ->
          scope.filteredLineItems = [
            { id: 1, price: 2.00, quantity: 1, final_weight_volume: 4000  }
          ]
          scope.weightAdjustedPrice(scope.filteredLineItems[0])
          expect(scope.filteredLineItems[0].price).toEqual 4.00

        it "doesn't update the price if the weight <= 0", ->
          scope.filteredLineItems = [
            { id: 1, price: 2.00, quantity: 1, final_weight_volume: 0  }
          ]
          scope.weightAdjustedPrice(scope.filteredLineItems[0])
          expect(scope.filteredLineItems[0].price).toEqual 2.00

        it "doesn't update the price if the weight is an empty string", ->
          scope.filteredLineItems = [
            { id: 1, price: 2.00, quantity: 1, final_weight_volume: ""  }
          ]
          scope.weightAdjustedPrice(scope.filteredLineItems[0])
          expect(scope.filteredLineItems[0].price).toEqual 2.00

      describe "updating final_weight_volume upon updating the quantity for a line_item", ->
        beforeEach ->
          LineItems.pristineByID = { 1: { price: 2.00, quantity: 1, final_weight_volume: 2000 } }
          spyOn(scope, "weightAdjustedPrice")

        it "updates the weight if the quantity is changed, then calls weightAdjustedPrice()", ->
          scope.filteredLineItems = [
            { id: 1, price: 2.00, quantity: 2, final_weight_volume: 0  }
          ]
          scope.updateOnQuantity(scope.filteredLineItems[0])
          expect(scope.filteredLineItems[0].final_weight_volume).toEqual 4000
          expect(scope.weightAdjustedPrice).toHaveBeenCalled()

        it "doesn't update the weight if the quantity <= 0", ->
          scope.filteredLineItems = [
            { id: 1, price: 2.00, quantity: 0, final_weight_volume: 1000  }
          ]
          scope.updateOnQuantity(scope.filteredLineItems[0])
          expect(scope.filteredLineItems[0].final_weight_volume).toEqual 1000

        it "doesn't update the weight if the quantity is an empty string", ->
          scope.filteredLineItems = [
            { id: 1, price: 2.00, quantity: "", final_weight_volume: 1000  }
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
