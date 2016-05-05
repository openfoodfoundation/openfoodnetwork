describe "CustomersCtrl", ->
  scope = null
  http = null

  beforeEach ->
    module('admin.customers')
    inject ($controller, $rootScope, _CustomerResource_, $httpBackend) ->
      scope = $rootScope
      http = $httpBackend
      $controller 'customersCtrl', {$scope: scope, CustomerResource: _CustomerResource_, shops: {}}
    this.addMatchers
      toAngularEqual: (expected) ->
        return angular.equals(this.actual, expected)

  it "has no shop pre-selected", ->
    expect(scope.shop).toEqual {}

  describe "setting the shop on scope", ->
    customer = { id: 5, email: 'someone@email.com'}
    customers = [customer]

    beforeEach ->
      http.expectGET('/admin/customers.json?enterprise_id=1').respond 200, customers
      scope.$apply ->
        scope.shop = {id: 1}
      http.flush()

    it "retrievs the list of customers", ->
      expect(scope.customers).toAngularEqual customers

    describe "scope.add", ->
      it "creates a new customer", ->
        email = "customer@example.org"
        newCustomer = {id: 6, email: email}
        customers.push(newCustomer)
        http.expectPOST('/admin/customers.json?email=' + email + '&enterprise_id=1').respond 200, newCustomer
        scope.add(email)
        http.flush()
        expect(scope.customers).toAngularEqual customers

    describe "scope.deleteCustomer", ->
      it "deletes a customer", ->
        expect(scope.customers.length).toBe 2
        customer = scope.customers[0]
        http.expectDELETE('/admin/customers/' + customer.id + '.json').respond 200
        scope.deleteCustomer(customer)
        http.flush()
        expect(scope.customers.length).toBe 1
        expect(scope.customers[0]).not.toAngularEqual customer

    describe "scope.findTags", ->
      tags = [
        { text: 'one' }
        { text: 'two' }
        { text: 'three' }
      ]
      beforeEach ->
        http.expectGET('/admin/tags.json?enterprise_id=1').respond 200, tags

      it "retrieves the tag list", ->
        promise = scope.findTags('')
        result = null
        promise.then (data) ->
          result = data
        http.flush()
        expect(result).toAngularEqual tags

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
        expect(result).toAngularEqual filtered_tags
