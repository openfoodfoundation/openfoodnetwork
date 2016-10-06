describe "StandingOrdersCtrl", ->
  scope = null
  http = null
  shops = null

  beforeEach ->
    module('admin.standingOrders')
    # module ($provide) ->
    #   $provide.value 'columns', []
    #   null

    # shops = [
    #   { name: "Shop 1", id: 1 }
    #   { name: "Shop 2", id: 2 }
    #   { name: "Shop 3", id: 3 }
    # ]

    inject ($controller, $rootScope, _StandingOrderResource_, $httpBackend) ->
      scope = $rootScope
      http = $httpBackend
      $controller 'StandingOrdersController', {$scope: scope, StandingOrderResource: _StandingOrderResource_}
    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

  # it "has no shop pre-selected", inject (CurrentShop) ->
  #   expect(CurrentShop.shop).toEqual {}

  describe "initialization", -> # setting shop_id on scope
    standingOrder = { id: 5, customer_id: 3, schedule_id: 1}
    standingOrders = [standingOrder]

    beforeEach inject ->
      scope.standing_orders_form = jasmine.createSpyObj('standing_orders_form', ['$setPristine'])
      http.expectGET('/admin/standing_orders.json').respond 200, standingOrders
      # scope.$apply ->
      #   scope.shop_id = 3
      http.flush()

    # it "sets the CurrentShop", inject (CurrentShop) ->
    #   expect(CurrentShop.shop).toEqual shops[2]
    #
    # it "sets the form state to pristine", ->
    #   expect(scope.standingOrders_form.$setPristine).toHaveBeenCalled()
    #
    # it "clears all changes", inject (pendingChanges) ->
    #   expect(pendingChanges.removeAll).toHaveBeenCalled()

    it "retrieves the list of standingOrders", ->
      expect(scope.standingOrders).toDeepEqual standingOrders
