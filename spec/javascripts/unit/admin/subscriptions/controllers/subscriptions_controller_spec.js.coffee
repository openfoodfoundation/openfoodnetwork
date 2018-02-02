describe "SubscriptionsCtrl", ->
  scope = null
  http = null
  shops = [
    { name: "Shop 1", id: 1 }
    { name: "Shop 2", id: 2 }
    { name: "Shop 3", id: 3 }
  ]

  beforeEach ->
    module('admin.subscriptions')
    module ($provide) ->
      # $provide.value 'columns', []
      $provide.value 'shops', shops
      null

    inject ($controller, $rootScope, _SubscriptionResource_, $httpBackend) ->
      scope = $rootScope
      http = $httpBackend
      $controller 'SubscriptionsController', {$scope: scope, SubscriptionResource: _SubscriptionResource_}
    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

  it "has no shop pre-selected", ->
    expect(scope.shop_id).toEqual null

  describe "setting shop_id on scope", ->
    subscription = { errors: {}, id: 5, customer_id: 3, schedule_id: 1 }
    subscriptions = [subscription]

    beforeEach ->
      http.expectGET('/admin/subscriptions.json?q%5Bcanceled_at_null%5D=true&q%5Bshop_id_eq%5D=3').respond 200, subscriptions
      scope.$apply -> scope.shop_id = 3
      http.flush()

    # it "sets the CurrentShop", inject (CurrentShop) ->
    #   expect(CurrentShop.shop).toEqual shops[2]

    it "retrieves the list of subscriptions", ->
      expect(scope.subscriptions).toDeepEqual subscriptions
