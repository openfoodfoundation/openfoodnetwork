describe "OrderCyclesCtrl", ->
  ctrl = scope = httpBackend = Enterprises = OrderCycles = Schedules = null
  coordinator = producer = shop = orderCycle = schedule = null

  beforeEach ->
    module "admin.orderCycles"
    module ($provide) ->
      $provide.value 'columns', []
      null

    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

  beforeEach inject(($controller, $rootScope, $httpBackend, _OrderCycles_, _Enterprises_, _Schedules_) ->
    scope = $rootScope.$new()
    ctrl = $controller
    httpBackend = $httpBackend
    Enterprises = _Enterprises_
    OrderCycles = _OrderCycles_
    Schedules = _Schedules_
    spyOn(window, "daysFromToday").and.returnValue "SomeDate"

    coordinator = { id: 3, name: "Coordinator" }
    producer = { id: 1, name: "Producer" }
    shop = { id: 5, name: "Shop" }
    schedule = { id: 7, name: 'Weekly', order_cycles: [{id: 4}]}
    orderCycle = { id: 4, schedules: [{id: 7}], name: "OC1", coordinator: {id: 3}, shops: [{id: 3},{id: 5}], producers: [{id: 1}] }

    httpBackend.expectGET("/admin/enterprises/visible.json?ams_prefix=basic").respond [coordinator, producer, shop]
    httpBackend.expectGET("/admin/schedules.json").respond [schedule]
    httpBackend.expectGET("/admin/order_cycles.json?ams_prefix=index&q%5Borders_close_at_gt%5D=SomeDate").respond [orderCycle]

    ctrl "OrderCyclesCtrl", {$scope: scope, Enterprises: Enterprises, OrderCycles: OrderCycles, Schedules: Schedules}
  )

  describe "before data is returned", ->
    it "the RequestMonitor will have a state of loading", ->
      expect(scope.RequestMonitor.loading).toBe true

    it "has not received/stored any data yet", ->
      expect(Enterprises.byID["5"]).toBeUndefined()
      expect(OrderCycles.byID["4"]).toBeUndefined()
      expect(Schedules.byID["7"]).toBeUndefined()

  describe "after data is returned", ->
    beforeEach ->
      httpBackend.flush()

    describe "initialisation", ->
      it "gets enterprises", ->
        expect(scope.enterprises).toDeepEqual [ coordinator, producer, shop ]

      it "stores enterprises, order cycle and schedules in a list that is accessible by id", ->
        expect(Enterprises.byID["5"]).toBeDefined()
        expect(OrderCycles.byID["4"]).toBeDefined()
        expect(Schedules.byID["7"]).toBeDefined()

      it "gets order cycles, with dereferenced coordinator, shops and producers, schedules", ->
        oc = OrderCycles.byID["4"]
        s = Schedules.byID["7"]
        expect(scope.orderCycles).toDeepEqual [oc]
        expect(oc.coordinator).toDeepEqual coordinator
        expect(oc.shops).toDeepEqual [coordinator,shop]
        expect(oc.producers).toDeepEqual [producer]
        expect(oc.schedules).toEqual [s]
        expect(s.order_cycles).toEqual [oc]
        expect(oc.shopNames).toEqual "Coordinator, Shop"
        expect(oc.producerNames).toEqual "Producer"


      it "the RequestMonitor will not longer have a state of loading", ->
        expect(scope.RequestMonitor.loading).toBe false

  describe "filtering order cycles", ->
    it "filters by and resets filter variables", ->
      scope.query = "test"
      scope.scheduleFilter = 1
      scope.involvingFilter = 1
      scope.resetSelectFilters()
      expect(scope.query).toBe ""
      expect(scope.scheduleFilter).toBe 0
      expect(scope.involvingFilter).toBe 0