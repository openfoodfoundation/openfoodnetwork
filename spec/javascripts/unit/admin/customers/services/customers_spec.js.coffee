describe "Customers", ->
  Customers = CurrentShop = customers = $httpBackend = null

  beforeEach ->
    module 'admin.customers'

    jasmine.addMatchers
      toDeepEqual: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
          { pass: angular.equals(actual, expected) }

    inject ($q, _$httpBackend_, _Customers_, _CurrentShop_) ->
      Customers = _Customers_

  describe "scope.add", ->
    it "creates a new customer", inject ($httpBackend, CurrentShop) ->
      email = "customer@example.org"
      newCustomer = {id: 6, email: email}
      CurrentShop.shop = { id: 3 }
      $httpBackend.expectPOST('/admin/customers.json?email=' + email + '&enterprise_id=3').respond 200, newCustomer
      Customers.add(email)
      $httpBackend.flush()
      expect(Customers.all).toDeepEqual [newCustomer]
