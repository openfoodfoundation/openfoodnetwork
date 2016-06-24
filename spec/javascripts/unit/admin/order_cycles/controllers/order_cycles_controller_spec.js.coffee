describe "OrderCyclesCtrl", ->
  ctrl = scope = httpBackend = Enterprises = OrderCycles = null
  coordinator = producer = shop = orderCycle = null

  beforeEach ->
    module "admin.orderCycles"
    module ($provide) ->
      $provide.value 'columns', []
      null

    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

  beforeEach inject(($controller, $rootScope, $httpBackend, _OrderCycles_, _Enterprises_) ->
    scope = $rootScope.$new()
    ctrl = $controller
    httpBackend = $httpBackend
    Enterprises = _Enterprises_
    OrderCycles = _OrderCycles_
    spyOn(window, "daysFromToday").and.returnValue "SomeDate"

    coordinator = { id: 3, name: "Coordinator" }
    producer = { id: 1, name: "Producer" }
    shop = { id: 5, name: "Shop" }
    orderCycle = { id: 4, name: "OC1", coordinator: {id: 3}, shops: [{id: 3},{id: 5}], producers: [{id: 1}] }

    httpBackend.expectGET("/admin/enterprises/visible.json?ams_prefix=basic").respond [coordinator, producer, shop]
    httpBackend.expectGET("/admin/order_cycles.json?ams_prefix=index&q%5Borders_close_at_gt%5D=SomeDate").respond [orderCycle]

    ctrl "OrderCyclesCtrl", {$scope: scope, Enterprises: Enterprises, OrderCycles: OrderCycles}
  )

  describe "before data is returned", ->
    it "the RequestMonitor will have a state of loading", ->
      expect(scope.RequestMonitor.loading).toBe true

  describe "after data is returned", ->
    beforeEach ->
      httpBackend.flush()

    describe "initialisation", ->
      it "gets suppliers, adds a blank option as the first in the list", ->
        expect(scope.enterprises).toDeepEqual [ { id : '0', name : 'All' }, coordinator, producer, shop ]

      it "stores enterprises in an list that is accessible by id", ->
        expect(Enterprises.enterprisesByID["5"]).toDeepEqual shop

      it "gets order cycles, with dereferenced coordinator, shops and producers", ->
        oc = OrderCycles.orderCyclesByID["4"]
        expect(scope.orderCycles).toDeepEqual [oc]
        expect(oc.coordinator).toDeepEqual coordinator
        expect(oc.shops).toDeepEqual [coordinator,shop]
        expect(oc.producers).toDeepEqual [producer]
        expect(oc.shopNames).toEqual "Coordinator, Shop"
        expect(oc.producerNames).toEqual "Producer"

      it "the RequestMonitor will not longer have a state of loading", ->
        expect(scope.RequestMonitor.loading).toBe false
