describe "StandingOrdersCtrl", ->
  scope = null
  http = null
  shops = [
    { name: "Shop 1", id: 1 }
    { name: "Shop 2", id: 2 }
    { name: "Shop 3", id: 3 }
  ]

  beforeEach ->
    module('admin.standingOrders')
    module ($provide) ->
      # $provide.value 'columns', []
      $provide.value 'shops', shops
      null

    inject ($controller, $rootScope, _StandingOrderResource_, $httpBackend) ->
      scope = $rootScope
      http = $httpBackend
      $controller 'StandingOrdersController', {$scope: scope, StandingOrderResource: _StandingOrderResource_}
    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

  it "has no shop pre-selected", ->
    expect(scope.shop_id).toEqual null

  describe "setting shop_id on scope", ->
    standingOrder = { errors: {}, id: 5, customer_id: 3, schedule_id: 1 }
    standingOrders = [standingOrder]

    beforeEach ->
      http.expectGET('/admin/standing_orders.json?ams_prefix=index&q%5Bshop_id_eq%5D=3').respond 200, standingOrders
      scope.$apply -> scope.shop_id = 3
      http.flush()

    # it "sets the CurrentShop", inject (CurrentShop) ->
    #   expect(CurrentShop.shop).toEqual shops[2]

    it "retrieves the list of standingOrders", ->
      expect(scope.standingOrders).toDeepEqual standingOrders
