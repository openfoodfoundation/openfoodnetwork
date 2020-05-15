describe "ordersCtrl", ->
  ctrl = null
  Orders = null
  $scope = null
  orders = [
    { id: 8, order_cycle: { id: 4 }, distributor: { id: 5 }, number: "R123456" }
    { id: 9, order_cycle: { id: 5 }, distributor: { id: 7 }, number: "R213776" }
    { id: 10, order_cycle: { id: 6 }, distributor: { id: 8 }, number: "R213777" }
  ]
  form = {
    q: {
      created_at_lt: ''
      created_at_gt: ''
      completed_at_not_null: true
    }
  }

  beforeEach ->
    module 'admin.orders'
    inject ($controller, $rootScope, RequestMonitor, SortOptions) ->
      $scope = $rootScope.$new()
      Orders =
        index: jasmine.createSpy('index').and.returnValue(orders)
        all: orders
      ctrl = $controller 'ordersCtrl', { $scope: $scope, RequestMonitor: RequestMonitor, SortOptions: SortOptions, Orders: Orders }
      $scope.q = form.q

  describe "initialising the controller", ->
    it "fetches orders", ->
      $scope.initialise()
      expect(Orders.index).toHaveBeenCalled()
      expect($scope.orders).toEqual orders

    it "fetches them sorted by completed_at by default", ->
      $scope.initialise()
      expect(Orders.index).toHaveBeenCalledWith(jasmine.objectContaining({
        'q[s]': 'completed_at desc'
      }))

  describe "using pagination", ->
    it "changes the page", ->
      $scope.changePage(2)
      expect($scope.page).toEqual 2
      expect(Orders.index).toHaveBeenCalled()

  describe "sorting orders", ->
    it "sorts orders", ->
      spyOn $scope, "fetchResults"

      $scope.sortOptions.toggle('number')
      $scope.$apply()

      expect($scope.sorting).toEqual 'number asc'
      expect($scope.fetchResults).toHaveBeenCalled()

  describe "filtering orders", ->
    it "filters orders by all selected order cycles", ->
      $scope['q']['order_cycle_id_in'] = ['4', '5']

      $scope.fetchResults()

      # Fetched with correct square brackets in field name for array value
      expect(Orders.index).toHaveBeenCalledWith(jasmine.objectContaining({
        'q[order_cycle_id_in][]': ['4', '5']
      }))
