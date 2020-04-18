describe "CustomersCtrl", ->
  scope = null
  http = null
  shops = null

  beforeEach ->
    module('admin.customers')
    module ($provide) ->
      $provide.value 'columns', []
      null

    shops = [
      { name: "Shop 1", id: 1 },
      { name: "Shop 2", id: 12 },
      { name: "Shop 3", id: 2 },
      { name: "Shop 4", id: 3 }
    ]

    availableCountries = [
      {id: 109, name: "Australia", states: [{id: 55, name: "ACT", abbr: "ACT"}]}
    ]

    inject ($controller, $rootScope, _CustomerResource_, $httpBackend) ->
      scope = $rootScope
      http = $httpBackend
      $controller 'customersCtrl', {$scope: scope, CustomerResource: _CustomerResource_, shops: shops, availableCountries: availableCountries}
    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

  it "has no shop pre-selected", inject (CurrentShop) ->
    expect(CurrentShop.shop).toEqual {}

  describe "setting the shop on scope", ->
    customer = { id: 5, email: 'someone@email.com', code: 'a'}
    customers = [customer]

    beforeEach inject (pendingChanges) ->
      spyOn(pendingChanges, "removeAll")
      scope.customers_form = jasmine.createSpyObj('customers_form', ['$setPristine'])
      http.expectGET('/admin/customers.json?enterprise_id=2').respond 200, customers
      scope.$apply ->
        scope.shop_id = "2"
      http.flush()

    it "sets the CurrentShop", inject (CurrentShop) ->
      expect(CurrentShop.shop).toEqual shops[2]

    it "sets the form state to pristine", ->
      expect(scope.customers_form.$setPristine).toHaveBeenCalled()

    it "clears all changes", inject (pendingChanges) ->
      expect(pendingChanges.removeAll).toHaveBeenCalled()

    it "retrievs the list of customers", ->
      expect(scope.customers).toDeepEqual customers

    it "finds customers by code", ->
      as = scope.findByCode('a')
      expect(as).toDeepEqual customers
      as = scope.findByCode('b')
      expect(as).toDeepEqual []

    describe "scope.deleteCustomer", ->
      beforeEach ->
        spyOn(window, 'confirm').and.returnValue(true)

      it "deletes a customer", ->
        expect(scope.customers.length).toBe 1
        customer = scope.customers[0]
        http.expectDELETE('/admin/customers/' + customer.id + '.json').respond 200
        scope.deleteCustomer(customer)
        http.flush()
        expect(scope.customers.length).toBe 0

    describe "scope.findTags", ->
      tags = [
        { text: 'one' }
        { text: 'two' }
        { text: 'three' }
      ]
      beforeEach ->
        http.expectGET('/admin/tag_rules/map_by_tag.json?enterprise_id=2').respond 200, tags

      it "retrieves the tag list", ->
        promise = scope.findTags('')
        result = null
        promise.then (data) ->
          result = data
        http.flush()
        expect(result).toDeepEqual tags

      it "filters the tag list", ->
        filtered_tags = [
          { text: 'two' }
          { text: 'three' }
        ]
        promise = scope.findTags('t')
        result = null
        promise.then (data) ->
          result = data
        http.flush()
        expect(result).toDeepEqual filtered_tags
