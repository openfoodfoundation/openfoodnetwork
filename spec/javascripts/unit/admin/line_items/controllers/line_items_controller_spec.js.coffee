describe "LineItemsCtrl", ->
  ctrl = scope = httpBackend = $timeout = VariantUnitManager = Enterprises = Orders = LineItems = OrderCycles = null
  supplier = distributor = orderCycle = null

  beforeEach ->
    module "admin.lineItems"
    module ($provide) ->
      $provide.value 'columns', []
      null
    module "admin.products"
    module ($provide)->
      $provide.value "availableUnits", "g,kg,T,mL,L,kL"
      null

    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

  beforeEach inject(($controller, $rootScope, $httpBackend, _$timeout_, _VariantUnitManager_, _Enterprises_, _Orders_, _OrderCycles_) ->
    scope = $rootScope.$new()
    ctrl = $controller
    $timeout = _$timeout_
    httpBackend = $httpBackend
    Enterprises = _Enterprises_
    Orders = _Orders_
    OrderCycles = _OrderCycles_
    VariantUnitManager = _VariantUnitManager_
    momentMock = jasmine.createSpyObj('moment', ['format', 'startOf', 'endOf', 'subtract', 'add', 'isValid'])
    spyOn(window,"moment").and.returnValue momentMock
    momentMock.startOf.and.returnValue momentMock
    momentMock.endOf.and.returnValue momentMock
    momentMock.subtract.and.returnValue momentMock
    momentMock.add.and.returnValue momentMock
    momentMock.format.and.returnValue "SomeDate"
    momentMock.isValid.and.returnValue true

    supplier = { id: 1, name: "Supplier" }
    distributor = { id: 5, name: "Distributor" }
    orderCycle = { id: 4, name: "OC1" }
    order = { id: 9, order_cycle: { id: 4 }, distributor: { id: 5 }, number: "R123456" }
    lineItem = { id: 7, quantity: 3, order: { id: 9 }, supplier: { id: 1 } }

    LineItems =
      index: jasmine.createSpy('index').and.returnValue(lineItem)
      all: [lineItem]
      delete: (lineItem, callback=null) ->
        callback() if callback
        return Promise.resolve()
      allSaved: jasmine.createSpy('allSaved').and.returnValue(true)

    httpBackend.expectGET("/admin/enterprises/visible.json?ams_prefix=basic&q%5Bsells_in%5D%5B%5D=own&q%5Bsells_in%5D%5B%5D=any").respond [distributor]
    httpBackend.expectGET("/admin/order_cycles.json?ams_prefix=basic&as=distributor&q%5Borders_close_at_gt%5D=SomeDate").respond [orderCycle]
    httpBackend.expectGET("/admin/enterprises/visible.json?ams_prefix=basic&q%5Bis_primary_producer_eq%5D=true").respond [supplier]
    httpBackend.expectGET("/api/v0/orders.json?q%5Bid_in%5D%5B%5D=#{order.id}").respond { orders: [order] }

    scope.bulk_order_form = jasmine.createSpyObj('bulk_order_form', ['$setPristine'])

    ctrl "LineItemsCtrl", {$scope: scope, $timeout: $timeout, Enterprises: Enterprises, Orders: Orders, LineItems: LineItems, OrderCycles: OrderCycles}
  )

  describe "before data is returned", ->
    it "the RequestMonitor will have a state of loading", ->
      expect(scope.RequestMonitor.loading).toBe true

    it "will not have reset the form state to pristine", ->
      expect(scope.bulk_order_form.$setPristine.calls.count()).toBe 0

  describe "after data is returned", ->
    beforeEach ->
      httpBackend.flush()
      $timeout.flush()

    describe "initialisation", ->
      it "gets suppliers", ->
        expect(scope.suppliers).toDeepEqual [ supplier ]

      it "gets distributors", ->
        expect(scope.distributors).toDeepEqual [ distributor ]

      it "stores enterprises in an list that is accessible by id", ->
        expect(Enterprises.byID[1]).toDeepEqual supplier

      it "gets order cycles", ->
        expect(scope.orderCycles).toDeepEqual [ orderCycle ]

      it "gets orders, with dereferenced order cycles and distributors", ->
        expect(scope.orders).toDeepEqual [ { id: 9, order_cycle: orderCycle, distributor: distributor, number: "R123456" } ]

      it "gets line_items, with dereferenced orders and suppliers", ->
        expect(scope.line_items).toDeepEqual [ { id: 7, quantity: 3, order: scope.orders[0], supplier: supplier } ]

      it "the RequestMonitor will have a state of loaded", ->
        expect(scope.RequestMonitor.loading).toBe false

      it "resets the select filters", ->
        expect(scope.distributorFilter).toBe ''
        expect(scope.supplierFilter).toBe ''
        expect(scope.orderCycleFilter).toBe ''
        expect(scope.quickSearch).toBe = ""

      it "resets the form state to pristine", ->
        expect(scope.bulk_order_form.$setPristine.calls.count()).toBe 1

    describe "deleting a line item", ->
      line_item1 = line_item2 = null
      order1 = order2 = null

      beforeEach ->
        order1 = { id: 1, item_count: 1 }
        order2 = { id: 2, item_count: 2 }

        line_item1 = {
          name: "line item 1",
          order: order1
        }
        line_item2 = {
          name: "line item 2",
          order: order2
        }
        scope.line_items = [ line_item1, line_item2 ]

      it "show popup about order cancellation only on last item deletion", ->
        spyOn(window, "ofnCancelOrderAlert")
        scope.deleteLineItem(line_item2)
        expect(ofnCancelOrderAlert).not.toHaveBeenCalled()
        scope.deleteLineItem(line_item1)
        expect(ofnCancelOrderAlert).toHaveBeenCalled()

      it "deletes the line item", ->
        spyOn(window, "confirm").and.callFake(-> return true)
        spyOn(LineItems, "delete")
        scope.deleteLineItem(line_item2)
        expect(LineItems.delete).toHaveBeenCalledWith(line_item2, jasmine.anything())
    
    describe "deleting 'checked' line items", ->
      line_item1 = line_item2 = line_item3 = line_item4 = null
      order1 = order2 = order3 = null

      beforeEach ->
        order1 = { id: 1, item_count: 1 }
        order2 = { id: 2, item_count: 1 }
        order3 = { id: 3, item_count: 2 }
        line_item1 = {
          name: "line item 1",
          order: order1
          checked: false
        }
        line_item2 = {
          name: "line item 2",
          order: order2,
          checked: false
        }
        line_item3 = {
          name: "line item 3",
          order: order3,
          checked: false
        }
        line_item4 = {
          name: "line item 4",
          order: order3,
          checked: false
        }
        scope.line_items = [ line_item1, line_item2, line_item3, line_item4 ]

      it "asks for confirmation only if orders will be canceled", ->
        spyOn(window, "ofnCancelOrderAlert")
        line_item3.checked = true
        scope.deleteLineItems(scope.line_items)
        line_item1.checked = true
        scope.deleteLineItems(scope.line_items)

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

        it "calls Math.round() if variant_unit is 'weight', 'volume', or items", ->
          spyOn(Math,"round")
          scope.selectedUnitsProduct = { variant_unit: "weight", group_buy_unit_size: 10 }
          scope.fulfilled()
          expect(Math.round).toHaveBeenCalled()
          scope.selectedUnitsProduct = { variant_unit: "volume", group_buy_unit_size: 10 }
          scope.fulfilled()
          expect(Math.round).toHaveBeenCalled()
          scope.selectedUnitsProduct = { variant_unit: "items", group_buy_unit_size: 10 }
          scope.fulfilled()
          expect(Math.round).toHaveBeenCalled()


        describe "returns the quantity of fulfilled group buy units", -> 
          runs = [
            { selectedUnitsProduct: { variant_unit: "weight", group_buy_unit_size: 1000, variant_unit_scale: 1 }, arg: 1500, expected: 1.5  },
            { selectedUnitsProduct: { variant_unit: "weight", group_buy_unit_size: 60000, variant_unit_scale: 1000 }, arg: 9, expected: 0.15  },
            { selectedUnitsProduct: { variant_unit: "weight", group_buy_unit_size: 60000, variant_unit_scale: 1 }, arg: 9000, expected: 0.15 }
            { selectedUnitsProduct: { variant_unit: "weight", group_buy_unit_size: 5, variant_unit_scale: 28.35 }, arg: 12, expected: 2.4},
            { selectedUnitsProduct: { variant_unit: "volume", group_buy_unit_size: 5000, variant_unit_scale: 1  }, arg: 5, expected: 0.001}
          ];
          runs.forEach ({selectedUnitsProduct, arg, expected}) ->
            it "returns the quantity of fulfilled group buy units, group_buy_unit_size: " + selectedUnitsProduct.group_buy_unit_size + ", arg: " + arg + ", scale: " + selectedUnitsProduct.variant_unit_scale ,  ->
              scope.selectedUnitsProduct = selectedUnitsProduct
              expect(scope.fulfilled(arg)).toEqual expected

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
        it "returns the sum of the final_weight_volumes line_items if volume", ->
          scope.filteredLineItems = [
            { final_weight_volume: 2, units_product: { variant_unit: "volume" } }
            { final_weight_volume: 7, units_product: { variant_unit: "volume" } }
            { final_weight_volume: 21, units_product: { variant_unit: "volume" } }
          ]
          expect(scope.sumUnitValues()).toEqual 30

        it "returns the sum of the quantity line_items if items", ->
          scope.filteredLineItems = [
            { quantity: 2, units_product: { variant_unit: "items" } }
            { quantity: 7, units_product: { variant_unit: "items" } }
            { quantity: 21, units_product: { variant_unit: "items" } }
          ]
          expect(scope.sumUnitValues()).toEqual 30

        it "returns the sum of the final_weight_volumes for line_items with both metric and imperial units", ->
          scope.filteredLineItems = [
            { final_weight_volume: 907.2, units_product: { variant_unit: "weight", variant_unit_scale: 453.6 }, units_variant: { unit_value: 453.6 } }
            { final_weight_volume: 2000, units_product: { variant_unit: "weight", variant_unit_scale: 1000 }, units_variant: { unit_value: 1000 } }
            { final_weight_volume: 56.7, units_product: { variant_unit: "weight", variant_unit_scale: 28.35 }, units_variant: { unit_value: 28.35 } }
            { final_weight_volume: 2, units_product: { variant_unit: "volume", variant_unit_scale: 1.0 }, units_variant: { unit_value: 1.0 } }
          ]
          expect(scope.sumUnitValues()).toEqual 8

      describe "sumMaxUnitValues()", ->
        it "returns the sum of the product of unit_value and maxOf(max_quantity, pristine quantity) for specified line_items", ->
          scope.filteredLineItems = [
            { id: 1, units_variant: { unit_value: 1 }, max_quantity: 5, units_product: { variant_unit: "volume", variant_unit_scale: 1 } }
            { id: 2, units_variant: { unit_value: 2 }, max_quantity: 1, units_product: { variant_unit: "volume", variant_unit_scale: 1 } }
            { id: 3, units_variant: { unit_value: 3 }, max_quantity: 10, units_product: { variant_unit: "volume", variant_unit_scale: 1 } }
          ]

          expect(scope.sumMaxUnitValues()).toEqual 37

        it "returns the sum of the product of max_quantity for specified line_items if variant_unit is `items`", ->
          scope.filteredLineItems = [
            { id: 1, units_variant: { unit_value: 1 }, max_quantity: 5, units_product: { variant_unit: "items" } }
            { id: 2, units_variant: { unit_value: 2 }, max_quantity: 1, units_product: { variant_unit: "items" } }
            { id: 3, units_variant: { unit_value: 3 }, max_quantity: 10, units_product: { variant_unit: "items" } }
          ]

          expect(scope.sumMaxUnitValues()).toEqual 16

      describe "formatting a value based upon the properties of a specified Units Variant", ->
        # A Units Variant is an API object which holds unit properies of a variant

        beforeEach ->
          spyOn(Math,"round").and.callThrough()
        unitsVariant = { unit_value: "1" }

        it "returns '' if selectedUnitsVariant has no property 'variant_unit'", ->
          expect(scope.formattedValueWithUnitName(1,{})).toEqual ''

        it "returns the value, and does not call Math.round if variant_unit is 'items'", ->
          unitsProduct = { variant_unit: "items" }
          expect(scope.formattedValueWithUnitName(1, unitsProduct, unitsVariant)).toEqual "1 items"

        it "calls Math.round() if variant_unit is 'weight' or 'volume'", ->
          unitsProduct = { variant_unit: "weight", variant_unit_scale: 1 }
          scope.formattedValueWithUnitName(1,unitsProduct,unitsVariant)
          expect(Math.round).toHaveBeenCalled()
          scope.selectedUnitsVariant = { variant_unit: "volume" }
          scope.formattedValueWithUnitName(1,unitsProduct,unitsVariant)
          expect(Math.round).toHaveBeenCalled()

        it "calls Math.round with the value multiplied by 1000", ->
          unitsProduct = { variant_unit: "weight", variant_unit_scale: 5 }
          scope.formattedValueWithUnitName(10, unitsProduct,unitsVariant)
          expect(Math.round).toHaveBeenCalledWith 10 * 1000

        it "returns the result of Math.round divided by 1000, followed by the result of getUnitName", ->
          unitsProduct = { variant_unit: "weight", variant_unit_scale: 1000 }
          spyOn(VariantUnitManager, "getUnitName").and.returnValue "kg"
          expect(scope.formattedValueWithUnitName(2,unitsProduct,unitsVariant)).toEqual "2 kg"

        it "handle correclty the imperial units", ->
          unitsProduct = { variant_unit: "weight", variant_unit_scale: 1000 }
          unitsVariant = { unit_value: "453.6" }
          spyOn(VariantUnitManager, "getUnitName").and.returnValue "lb"
          expect(scope.formattedValueWithUnitName(2, unitsProduct, unitsVariant)).toEqual "2 lb"

      describe "get group by size formatted value with unit name", ->
        beforeEach ->
          spyOn(VariantUnitManager, "getUnitName").and.returnValue "kg"
        
        unitsProduct = { variant_unit: "weight", variant_unit_scale: 1000 }
         
        it "returns the formatted value with unit name", ->
          expect(scope.getGroupBySizeFormattedValueWithUnitName(1000, unitsProduct)).toEqual "1 kg"

        it "handle the case when the value is actually null or empty", ->
          expect(scope.getGroupBySizeFormattedValueWithUnitName(null, unitsProduct)).toEqual ""
          expect(scope.getGroupBySizeFormattedValueWithUnitName("", unitsProduct)).toEqual ""


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
